import 'package:flutter/material.dart';
import 'package:jasaku_app/models/service.dart';
import 'package:jasaku_app/models/order_model.dart';
import 'package:jasaku_app/services/api.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:jasaku_app/screens/profile/transactions_screen.dart';
import 'package:jasaku_app/screens/payment/qris_payment_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  final Service service;
  final Map<String, dynamic>? selectedPackage;

  const CreateOrderScreen({Key? key, required this.service, this.selectedPackage}) : super(key: key);

  @override
  _CreateOrderScreenState createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  
  int _quantity = 1;
  String _selectedPaymentMethod = 'Transfer Bank';
  bool _isSubmitting = false;

  final List<String> _paymentMethods = [
    'QRIS',
    'Transfer Bank',
    'E-Wallet',
    'Kartu Kredit',
  ];

  // Helper to determine the base price (service price or selected package price)
  double _getBasePrice() {
    if (widget.selectedPackage != null && widget.selectedPackage!['price'] != null) {
      final p = widget.selectedPackage!['price'];
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? widget.service.price.toDouble();
    }
    return widget.service.price.toDouble();
  }

  // GANTI method _submitOrder dengan ini:
  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Compute base price and build payload for server
        final basePrice = _getBasePrice();
        final nowIso = DateTime.now().toIso8601String();
        final payload = {
          'serviceId': widget.service.id.toString(),
          'serviceTitle': widget.service.title,
          // include package info if selected
          if (widget.selectedPackage != null) 'packageId': widget.selectedPackage!['id']?.toString(),
          if (widget.selectedPackage != null) 'packageTitle': widget.selectedPackage!['title']?.toString(),
          if (widget.selectedPackage != null) 'packagePrice': (widget.selectedPackage!['price'] is num) ? (widget.selectedPackage!['price'] as num).toDouble() : double.tryParse(widget.selectedPackage!['price']?.toString() ?? '') ?? widget.service.price.toDouble(),
          // Use the seller value from the service (often the seller name).
          // Ideally this should be the seller's user id, but services currently
          // store seller as a name in the DB. Using the name avoids mismatches.
          'sellerId': widget.service.seller,
          'sellerName': widget.service.seller,
          'customerId': 'customer1',
          'customerName': 'Angga Dwi Prastyo',
          'price': basePrice.toDouble(),
          'quantity': _quantity,
          'notes': _notesController.text,
          'status': OrderStatus.pending.index,
          'orderDate': nowIso,
          'deadline': _deadlineController.text.isNotEmpty
              ? DateFormat('dd/MM/yyyy').parse(_deadlineController.text).toIso8601String()
              : null,
          'paymentMethod': _selectedPaymentMethod,
          'isPaid': 0,
        };

        final auth = Provider.of<AuthProvider>(context, listen: false);
        // Ensure customerId/name come from authenticated user
        if (auth.user != null) {
          payload['customerId'] = auth.user!.id.toString();
          payload['customerName'] = auth.user!.nama ?? auth.user!.email ?? 'Customer';
        }

        final resp = await apiClient.createOrder(payload);
        // Server returns { 'id': '<id>' } on success
        final createdId = resp['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

        // Construct local Order instance for navigation (Transactions will pick up from server)
        final newOrder = Order(
          id: createdId,
          serviceId: payload['serviceId'].toString(),
          serviceTitle: payload['serviceTitle'].toString(),
          // record packageTitle into local order if present
          // (Order model does not have package fields by default; we include package title in notes)
          
          sellerId: payload['sellerId'].toString(),
          sellerName: payload['sellerName'].toString(),
          customerId: payload['customerId'].toString(),
          customerName: payload['customerName'].toString(),
          price: (payload['price'] as num).toDouble(),
          quantity: (payload['quantity'] is int) ? payload['quantity'] as int : int.tryParse(payload['quantity'].toString()) ?? 1,
          notes: payload['notes']?.toString() ?? '',
          status: OrderStatus.pending,
          orderDate: DateTime.parse(payload['orderDate'].toString()),
          deadline: payload['deadline'] != null ? DateTime.parse(payload['deadline'].toString()) : null,
          paymentMethod: payload['paymentMethod']?.toString(),
          isPaid: false,
          progress: [
            OrderProgress(
              id: '1',
              percentage: 0,
              description: 'Pesanan dibuat',
              timestamp: DateTime.now(),
            ),
          ],
        );

        setState(() {
          _isSubmitting = false;
        });

        // Redirect to QRIS payment if payment method is QRIS
        if (_selectedPaymentMethod == 'QRIS') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QRISPaymentScreen(order: newOrder),
            ),
          );
        } else {
          _showOrderSuccessDialog(newOrder);
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderSuccessDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Pesanan Berhasil!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesanan Anda telah berhasil dibuat.'),
            SizedBox(height: 8),
            Text(
              'ID Pesanan: ${order.id}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Silakan lakukan pembayaran dan tunggu konfirmasi dari penjual.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to service detail
            },
            child: Text('Kembali ke Detail Jasa'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to Transactions screen to show latest orders
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => TransactionsScreen()),
              );
            },
            child: Text('Lihat Pesanan Saya'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026, 12, 31),
    );
    
    if (picked != null) {
      setState(() {
        _deadlineController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = _getBasePrice();
    final totalPrice = basePrice * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Info
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.design_services, color: Colors.blue),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.service.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.service.seller,
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

              // Quantity
              Text(
                'Jumlah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                  ),
                  Container(
                    width: 60,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _quantity.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                  Spacer(),
                  Text(
                    _formatPrice(totalPrice.toDouble()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Deadline
              Text(
                'Deadline (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  hintText: 'Pilih tanggal deadline',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _selectDeadline,
                  ),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              SizedBox(height: 20),

              // Payment Method
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Notes
              Text(
                'Catatan untuk Penjual (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Contoh: Tolong sertakan source file, warna preferensi biru, dll.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 30),

              // Order Summary
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal'),
                          Text(_formatPrice(widget.service.price.toDouble())),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Jumlah'),
                          Text('x$_quantity'),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatPrice(totalPrice.toDouble()),
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
              ),
              SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Buat Pesanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }
}