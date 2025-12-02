import 'package:flutter/material.dart';
import 'package:jasaku_app/screens/chat/chat_detail_screen.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _loading = true;
  List<ChatContact> _contacts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id ?? '';
    final url = 'http://localhost/jasaku_api/api/api.php?resource=chats&conversationsFor=${Uri.encodeComponent(userId.toString())}';
    final res = await ApiService.get(url);
    List<ChatContact> contacts = [];
    if (res is List) {
      for (final r in res) {
        final conv = r['conversationId'] ?? '';
        final last = r['lastMessage'] ?? '';
        final time = r['lastTimestamp'] ?? '';
        final sender = r['senderName'] ?? '';
        contacts.add(ChatContact(
          name: sender.isNotEmpty ? sender : conv,
          lastMessage: last,
          time: time.toString(),
          unreadCount: 0,
          initial: (sender.isNotEmpty ? sender[0] : (conv.isNotEmpty ? conv[0] : '?')),
          isOnline: false,
          conversationId: conv,
        ));
      }
    }
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _contacts;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey),
            onPressed: () {
              _showSearchDialog(context, contacts);
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              _handleMenuSelection(value, context);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'new_group', child: Text('Grup Baru')),
              PopupMenuItem(value: 'broadcast', child: Text('Siaran')),
              PopupMenuItem(value: 'settings', child: Text('Pengaturan Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Online Contacts
          _buildOnlineContacts(contacts),
          // Chat List Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Percakapan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${contacts.length} chat',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Chat List
          Expanded(
            child: _loading ? Center(child: CircularProgressIndicator()) : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return _buildChatItem(contacts[index], context);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewChatDialog(context);
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

    }

  Widget _buildOnlineContacts(List<ChatContact> contacts) {
    final onlineContacts = contacts.where((contact) => contact.isOnline).toList();
    
    return Container(
      height: 110,
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Online',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: onlineContacts.length,
              itemBuilder: (context, index) {
                return _buildOnlineContactItem(onlineContacts[index], context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineContactItem(ChatContact contact, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              contactName: contact.name,
              contactInitial: contact.initial,
              conversationId: contact.conversationId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAvatarColor(contact.initial),
                  child: Text(
                    contact.initial,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              contact.name.split(' ')[0],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatContact contact, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: _getAvatarColor(contact.initial),
                child: Text(
                  contact.initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (contact.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  contact.name,
                  style: TextStyle(
                    fontWeight: contact.unreadCount > 0 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (contact.unreadCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    contact.unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  contact.lastMessage,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                contact.time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          trailing: contact.unreadCount > 0
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  contactName: contact.name,
                  contactInitial: contact.initial,
                  conversationId: contact.conversationId,
                ),
              ),
            );
          },
          onLongPress: () {
            _showChatOptions(context, contact);
          },
        ),
      ),
    );
  }

  Color _getAvatarColor(String initial) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    final index = initial.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  void _showSearchDialog(BuildContext context, List<ChatContact> contacts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cari Chat'),
        content: Container(
          width: double.maxFinite,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari nama atau pesan...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Implement search logic
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement search
            },
            child: Text('Cari'),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat Baru'),
        content: Text('Pilih kontak untuk memulai chat baru'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to contact list
            },
            child: Text('Pilih Kontak'),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context, ChatContact contact) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.notifications_off, color: Colors.grey),
                title: Text('Sembunyikan Notifikasi'),
                onTap: () {
                  Navigator.pop(context);
                  _showNotificationHiddenMessage(context, contact.name);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Hapus Chat', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, contact);
                },
              ),
              ListTile(
                leading: Icon(Icons.block, color: Colors.orange),
                title: Text('Blokir Kontak', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(context, contact);
                },
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Chat'),
        content: Text('Apakah Anda yakin ingin menghapus chat dengan ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat dengan ${contact.name} telah dihapus')),
              );
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context, ChatContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Blokir Kontak'),
        content: Text('Apakah Anda yakin ingin memblokir ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${contact.name} telah diblokir')),
              );
            },
            child: Text('Blokir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNotificationHiddenMessage(BuildContext context, String contactName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifikasi untuk $contactName telah disembunyikan')),
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'new_group':
        _showNewGroupDialog(context);
        break;
      case 'broadcast':
        _showBroadcastDialog(context);
        break;
      case 'settings':
        _showChatSettings(context);
        break;
    }
  }

  void _showNewGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buat Grup Baru'),
        content: Text('Fitur pembuatan grup akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buat Siaran'),
        content: Text('Fitur siaran akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showChatSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pengaturan Chat'),
        content: Text('Pengaturan chat akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }


class ChatContact {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String initial;
  final bool isOnline;
  final String conversationId;

  ChatContact({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.initial,
    required this.isOnline,
    this.conversationId = '',
  });
}