import 'package:flutter/material.dart';

class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? qrCodeUrl;
  final String? paymentReference;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.qrCodeUrl,
    this.paymentReference,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['orderId'],
      amount: json['amount'],
      paymentMethod: json['paymentMethod'],
      status: PaymentStatus.values[json['status']],
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      qrCodeUrl: json['qrCodeUrl'],
      paymentReference: json['paymentReference'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'qrCodeUrl': qrCodeUrl,
      'paymentReference': paymentReference,
    };
  }
}

enum PaymentStatus {
  pending,
  waitingPayment,
  paid,
  expired,
  failed,
  cancelled,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Menunggu';
      case PaymentStatus.waitingPayment:
        return 'Menunggu Pembayaran';
      case PaymentStatus.paid:
        return 'Terbayar';
      case PaymentStatus.expired:
        return 'Kadaluarsa';
      case PaymentStatus.failed:
        return 'Gagal';
      case PaymentStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.waitingPayment:
        return Colors.blue;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.expired:
        return Colors.red;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.waitingPayment:
        return Icons.schedule;
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.expired:
        return Icons.timer_off;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
    }
  }
}