import 'package:flutter/material.dart';
import 'package:jasaku_app/models/payment_model.dart';

class PaymentService {
  // Simulate payment data - in real app, this would integrate with payment gateway
  static final List<Payment> _payments = [];

  static Future<Payment> createQRISPayment({
    required String orderId,
    required double amount,
  }) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate API call

    // Generate mock QRIS data
    final payment = Payment(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      amount: amount,
      paymentMethod: 'QRIS',
      status: PaymentStatus.waitingPayment,
      createdAt: DateTime.now(),
      qrCodeUrl: _generateMockQRCodeUrl(amount, orderId),
      paymentReference: 'REF-${DateTime.now().millisecondsSinceEpoch}',
    );

    _payments.add(payment);
    return payment;
  }

  static Future<Payment> getPayment(String paymentId) async {
    await Future.delayed(Duration(seconds: 1));
    return _payments.firstWhere((payment) => payment.id == paymentId);
  }

  static Future<Payment?> getPaymentByOrder(String orderId) async {
    await Future.delayed(Duration(seconds: 1));
    try {
      return _payments.firstWhere((payment) => payment.orderId == orderId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> simulatePayment(String paymentId) async {
    await Future.delayed(Duration(seconds: 3));
    final payment = _payments.firstWhere((p) => p.id == paymentId);
    final index = _payments.indexWhere((p) => p.id == paymentId);
    
    _payments[index] = Payment(
      id: payment.id,
      orderId: payment.orderId,
      amount: payment.amount,
      paymentMethod: payment.paymentMethod,
      status: PaymentStatus.paid,
      createdAt: payment.createdAt,
      paidAt: DateTime.now(),
      qrCodeUrl: payment.qrCodeUrl,
      paymentReference: payment.paymentReference,
    );
  }

  static Future<void> checkPaymentStatus(String paymentId) async {
    await Future.delayed(Duration(seconds: 2));
    // In real app, this would poll payment gateway API
  }

  static String _generateMockQRCodeUrl(double amount, String orderId) {
    // Generate a mock QR code URL
    // In real app, this would be from payment gateway like Midtrans, Xendit, etc.
    return 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=QRIS%3A%2F%2FJASAKU%2F$orderId%2F$amount';
  }

  static List<Map<String, dynamic>> getQRISInstructions() {
    return [
      {
        'step': 1,
        'instruction': 'Buka aplikasi e-wallet atau mobile banking Anda',
        'icon': Icons.smartphone,
      },
      {
        'step': 2,
        'instruction': 'Pilih fitur scan QRIS atau bayar dengan QR',
        'icon': Icons.qr_code_scanner,
      },
      {
        'step': 3,
        'instruction': 'Scan kode QR yang tertera di layar',
        'icon': Icons.camera_alt,
      },
      {
        'step': 4,
        'instruction': 'Periksa nominal dan konfirmasi pembayaran',
        'icon': Icons.verified,
      },
      {
        'step': 5,
        'instruction': 'Tunggu konfirmasi pembayaran sukses',
        'icon': Icons.schedule,
      },
    ];
  }
}