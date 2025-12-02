import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jasaku_app/models/order_model.dart';
import 'package:jasaku_app/models/payment_model.dart';
import 'package:jasaku_app/services/payment_service.dart';
import 'package:jasaku_app/services/order_service.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class QRISPaymentScreen extends StatefulWidget {
  final Order order;

  const QRISPaymentScreen({Key? key, required this.order}) : super(key: key);

  @override
  _QRISPaymentScreenState createState() => _QRISPaymentScreenState();
}

class _QRISPaymentScreenState extends State<QRISPaymentScreen> {
  Payment? _payment;
  bool _isLoading = true;
  bool _isPolling = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _initializePayment() async {
    try {
      // Check if payment already exists
      var existingPayment = await PaymentService.getPaymentByOrder(widget.order.id);
      
      if (existingPayment == null) {
        // Create new QRIS payment
        _payment = (await PaymentService.createQRISPayment(
          orderId: widget.order.id,
          amount: widget.order.totalPrice,
        )) as Payment?;
      } else {
        _payment = existingPayment as Payment?;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Start polling for payment status
      _startPolling();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_payment != null) {
        await PaymentService.checkPaymentStatus(_payment!.id);
        
        // For demo, we'll simulate payment after 15 seconds
        if (_payment?.status == PaymentStatus.waitingPayment && 
            DateTime.now().difference(_payment!.createdAt).inSeconds > 15) {
          await PaymentService.simulatePayment(_payment!.id);
          _refreshPayment();
        }
        
        _refreshPayment();
      }
    });
  }

  Future<void> _refreshPayment() async {
    if (_payment == null) return;

    final updatedPayment = await PaymentService.getPayment(_payment!.id);
    if (!mounted) return;

    setState(() {
      _payment = updatedPayment as Payment?;
    });

    // If payment is successful, update order status
    if (updatedPayment.status == PaymentStatus.paid) {
      // update server-side order status so TransactionsScreen reflects the change
      try {
        final updateBody = {
          'status': 'confirmed',
          'isPaid': 1,
          'completedDate': DateTime.now().toIso8601String(),
        };
        final uri = 'http://localhost/jasaku_api/api/api.php?resource=orders&id=${Uri.encodeComponent(widget.order.id)}';
        // Use ApiService to ensure headers/auth are applied consistently
        try {
          await ApiService.put(uri, updateBody);
        } catch (_) {}
      } catch (_) {}

      await OrderService.updateOrderStatus(widget.order.id, OrderStatus.confirmed);
      if (!mounted) return;
      _showPaymentSuccess();
    }
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Pembayaran Berhasil!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pembayaran Anda telah berhasil diverifikasi.'),
            SizedBox(height: 8),
            Text(
              'Pesanan akan diproses oleh penjual.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to order screen
            },
            child: Text('Lihat Pesanan Saya'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulatePayment() async {
    if (_payment != null) {
      if (mounted) {
        setState(() { _isPolling = true; });
      }

      await PaymentService.simulatePayment(_payment!.id);
      await _refreshPayment();

      if (mounted) {
        setState(() { _isPolling = false; });
      }
    }
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  String _formatTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran QRIS'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _payment == null
              ? Center(child: Text('Gagal memuat pembayaran'))
              : _buildPaymentContent(),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Payment Status
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _payment!.status.icon,
                    color: _payment!.status.color,
                    size: 40,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _payment!.status.displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _payment!.status.color,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatTime(_payment!.createdAt),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // QR Code
          if (_payment!.status == PaymentStatus.waitingPayment) ...[
            Text(
              'Scan QR Code untuk Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(77),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CachedNetworkImage(
                    imageUrl: _payment!.qrCodeUrl!,
                    width: 250,
                    height: 250,
                    placeholder: (context, url) => Container(
                      width: 250,
                      height: 250,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.download),
                      label: Text('Download QR'),
                      onPressed: _downloadQr,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _formatPrice(_payment!.amount),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'QRIS - Indonesian Standard',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Payment Instructions
            _buildPaymentInstructions(),
            SizedBox(height: 20),

            // Demo Button (for testing)
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Demo Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Untuk testing, klik tombol di bawah untuk simulasi pembayaran sukses',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isPolling ? null : _simulatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: _isPolling
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Simulasikan Pembayaran Sukses'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Order Summary
          SizedBox(height: 20),
          _buildOrderSummary(),
        ],
      ),
    );
  }

  Future<void> _downloadQr() async {
    final url = _payment?.qrCodeUrl;
    if (url == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak ada QR untuk di-download')));
      return;
    }

    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mengunduh QR...')));
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      // Determine downloads directory (desktop) or documents as fallback
      Directory? dir;
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {
        try {
          dir = await getApplicationDocumentsDirectory();
        } catch (_) {
          dir = Directory.systemTemp;
        }
      }

      final filename = 'qris_${widget.order.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir?.path}${Platform.pathSeparator}$filename');
      await file.writeAsBytes(res.bodyBytes);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR tersimpan: ${file.path}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunduh QR: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildPaymentInstructions() {
    final instructions = PaymentService.getQRISInstructions();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cara Pembayaran:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...instructions.map((instruction) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            instruction['step'].toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        instruction['icon'] as IconData,
                        size: 20,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instruction['instruction'],
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ID Pesanan'),
                Text(
                  widget.order.id,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Layanan'),
                Expanded(
                  child: Text(
                    widget.order.serviceTitle,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Penjual'),
                Text(
                  widget.order.sellerName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatPrice(widget.order.totalPrice),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}