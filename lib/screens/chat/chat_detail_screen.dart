import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jasaku_app/models/chat_model.dart';
import 'package:jasaku_app/models/service.dart';
import 'package:intl/intl.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String contactName;
  final String contactInitial;
  final String? conversationId;
  final Service? service;

  const ChatDetailScreen({
    Key? key,
    required this.contactName,
    this.contactInitial = 'A',
    this.service,
    this.conversationId,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showPriceOfferDialog = false;
  double _proposedPrice = 0;
  String? _conversationId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId != null && _conversationId!.isNotEmpty) {
      _loadMessagesFromApi();
      _pollTimer = Timer.periodic(Duration(seconds: 2), (_) => _loadMessagesFromApi());
    } else {
      _loadMessages();
    }
    _proposedPrice = widget.service?.price.toDouble() ?? 0;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // Sample messages with negotiation features
    setState(() {
      _messages.addAll([
        ChatMessage(
          id: '1',
          text: 'Silahkan order kak',
          isMe: false,
          timestamp: DateTime(2025, 10, 29, 10, 0),
          senderName: widget.contactName,
        ),
        ChatMessage(
          id: '2',
          text: 'Saya tertarik dengan jasa desain logo Anda. Bisa nego harga?',
          isMe: true,
          timestamp: DateTime(2025, 10, 29, 10, 5),
        ),
        ChatMessage(
          id: '3',
          text: 'Bisa kak, harga bisa dibicarakan. Budgetnya berapa?',
          isMe: false,
          timestamp: DateTime(2025, 10, 29, 10, 10),
          senderName: widget.contactName,
        ),
        ChatMessage(
          id: '4',
          text: 'Untuk paket basic, apakah bisa Rp 300.000?',
          isMe: true,
          timestamp: DateTime(2025, 10, 29, 10, 15),
          type: MessageType.priceOffer,
          proposedPrice: 300000,
          serviceId: widget.service?.id.toString(),
        ),
      ]);
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    final now = DateTime.now();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final senderName = auth.user?.nama ?? auth.user?.email ?? 'You';

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: now,
      senderName: senderName,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // ensure conversation id exists; create temporary deterministic id if missing
    if (_conversationId == null || _conversationId!.isEmpty) {
      _conversationId = 'conv_' + DateTime.now().millisecondsSinceEpoch.toString();
    }

    final uri = 'http://localhost/jasaku_api/api/api.php?resource=chats';
    final body = newMessage.toJson();
    body['conversationId'] = _conversationId;
    body['isMe'] = 1;
    ApiService.post(uri, body);
  }

  Future<void> _loadMessagesFromApi() async {
    if (_conversationId == null || _conversationId!.isEmpty) return;
    final uri = 'http://localhost/jasaku_api/api/api.php?resource=chats&conversationId=${Uri.encodeComponent(_conversationId!)}';
    final res = await ApiService.get(uri);
    if (res is List) {
      final msgs = <ChatMessage>[];
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final myName = auth.user?.nama ?? auth.user?.email ?? '';
      for (final m in res) {
        final isMeRaw = m['isMe'];
        // Prefer computing isMe by comparing senderName to current user name
        final senderNameRaw = m['senderName']?.toString() ?? '';
        bool isMe = (isMeRaw == 1 || isMeRaw == true || isMeRaw == '1');
        if (senderNameRaw.isNotEmpty && myName.isNotEmpty) {
          if (senderNameRaw == myName) isMe = true; else if (senderNameRaw != myName && isMe) isMe = false;
        }
        DateTime ts;
        try {
          ts = DateTime.parse(m['timestamp']);
        } catch (_) {
          ts = DateTime.now();
        }
        MessageType type = MessageType.text;
        try {
          final t = m['type'];
          if (t != null) type = MessageType.values[int.tryParse(t.toString()) ?? 0];
        } catch (_) {}
        double? proposed;
        try { proposed = m['proposedPrice'] != null ? double.tryParse(m['proposedPrice'].toString()) : null; } catch (_) { proposed = null; }
        msgs.add(ChatMessage(
          id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: m['text']?.toString() ?? '',
          isMe: isMe,
          timestamp: ts,
          type: type,
          senderName: m['senderName']?.toString(),
          serviceId: m['serviceId']?.toString(),
          proposedPrice: proposed,
          offerId: m['offerId']?.toString(),
        ));
      }
      setState(() {
        _messages.clear();
        _messages.addAll(msgs);
      });
    }
  }

  void _simulateReply() {
    setState(() {
      _isTyping = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Baik, saya pertimbangkan dulu ya',
            isMe: false,
            timestamp: DateTime.now(),
            senderName: widget.contactName,
          ),
        );
      });
    });
  }

  void _showPriceNegotiationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajukan Penawaran Harga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.service != null) ...[
              Text(
                'Harga Normal: Rp ${_formatPrice(widget.service!.price.toDouble())}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
            ],
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Harga Penawaran',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: _proposedPrice.toString(),
              onChanged: (value) {
                _proposedPrice = double.tryParse(value) ?? 0;
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Pesan Penawaran (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _sendPriceOffer();
              Navigator.pop(context);
            },
            child: Text('Ajukan Penawaran'),
          ),
        ],
      ),
    );
  }

  void _sendPriceOffer() {
    final offerMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'Saya menawarkan harga Rp ${_formatPrice(_proposedPrice)} untuk jasa ini',
      isMe: true,
      timestamp: DateTime.now(),
      type: MessageType.priceOffer,
      proposedPrice: _proposedPrice,
      serviceId: widget.service?.id.toString(),
    );

    setState(() {
      _messages.add(offerMessage);
    });

    // Simulate seller response
    _simulateOfferResponse();
  }

  void _simulateOfferResponse() {
    setState(() {
      _isTyping = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isTyping = false;
        
        // Random response - in real app this would come from seller
        final isAccepted = _proposedPrice >= (widget.service?.price.toDouble() ?? 0) * 0.8;
        
        if (isAccepted) {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: 'Baik, saya terima penawaran Rp ${_formatPrice(_proposedPrice)}',
              isMe: false,
              timestamp: DateTime.now(),
              type: MessageType.offerAccepted,
              senderName: widget.contactName,
            ),
          );
        } else {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: 'Maaf, harga Rp ${_formatPrice(_proposedPrice)} terlalu rendah. Bagaimana kalau Rp 400.000?',
              isMe: false,
              timestamp: DateTime.now(),
              senderName: widget.contactName,
            ),
          );
        }
      });
    });
  }

  void _acceptOffer(ChatMessage offerMessage) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Saya terima penawaran Anda!',
          isMe: false,
          timestamp: DateTime.now(),
          type: MessageType.offerAccepted,
          senderName: widget.contactName,
        ),
      );
    });
  }

  void _rejectOffer(ChatMessage offerMessage) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Maaf, penawaran tidak bisa saya terima',
          isMe: false,
          timestamp: DateTime.now(),
          type: MessageType.offerRejected,
          senderName: widget.contactName,
        ),
      );
    });
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(price);
  }

  String _formatTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                widget.contactInitial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.service != null)
            IconButton(
              icon: Icon(Icons.attach_money, color: Colors.orange),
              onPressed: _showPriceNegotiationDialog,
              tooltip: 'Ajukan Penawaran',
            ),
          IconButton(
            icon: Icon(Icons.phone, color: Colors.blue),
            onPressed: () {
              // Call functionality
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              switch (value) {
                case 'view_service':
                  // Navigate to service detail
                  break;
                case 'clear_chat':
                  // Clear chat history
                  break;
                case 'block':
                  // Block user
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view_service',
                child: Row(
                  children: [
                    Icon(Icons.remove_red_eye, size: 20),
                    SizedBox(width: 8),
                    Text('Lihat Jasa'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_chat',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus Chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20),
                    SizedBox(width: 8),
                    Text('Blokir'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Service Info Banner (if service exists)
          if (widget.service != null) _buildServiceInfo(),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping) _buildTypingIndicator(),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.design_services, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service?.title ?? 'Jasa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Rp ${_formatPrice(widget.service?.price.toDouble() ?? 0)}',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, size: 20),
            onPressed: () {
              // Navigate to service detail
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue,
              child: Text(
                message.senderName?[0] ?? 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!message.isMe)
                  Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      message.senderName ?? 'User',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Different bubble styles based on message type
                if (message.type == MessageType.priceOffer)
                  _buildPriceOfferBubble(message)
                else if (message.type == MessageType.offerAccepted)
                  _buildAcceptedOfferBubble(message)
                else if (message.type == MessageType.offerRejected)
                  _buildRejectedOfferBubble(message)
                else
                  _buildTextBubble(message),
              ],
            ),
          ),
          if (message.isMe) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.green,
              child: Text(
                'Me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextBubble(ChatMessage message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isMe ? Colors.blue : Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: message.isMe ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: message.isMe ? Colors.white70 : Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceOfferBubble(ChatMessage message) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text(
                'Penawaran Harga',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            message.text,
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Harga Ditawarkan:',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  'Rp ${_formatPrice(message.proposedPrice ?? 0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          if (!message.isMe) SizedBox(height: 8),
          if (!message.isMe)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectOffer(message),
                    child: Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOffer(message),
                    child: Text('Terima'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedOfferBubble(ChatMessage message) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text(
                'Penawaran Diterima',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            message.text,
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedOfferBubble(ChatMessage message) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel, size: 16, color: Colors.red),
              SizedBox(width: 4),
              Text(
                'Penawaran Ditolak',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            message.text,
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue,
            child: Text(
              widget.contactInitial,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Typing...',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () {
              // Attach file
            },
          ),

          // Price Offer Button
          if (widget.service != null)
            IconButton(
              icon: Icon(Icons.attach_money, color: Colors.orange),
              onPressed: _showPriceNegotiationDialog,
              tooltip: 'Ajukan Penawaran Harga',
            ),

          // Message Input
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
          ),

          // Send Button
          IconButton(
            icon: Icon(
              Icons.send,
              color: Colors.blue,
            ),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  
}