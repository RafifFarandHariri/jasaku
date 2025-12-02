import 'package:flutter/material.dart';

class Order {
  final String id;
  final String serviceId;
  final String serviceTitle;
  final String sellerId;
  final String sellerName;
  final String customerId;
  final String customerName;
  final double price;
  final int quantity;
  final String notes;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? deadline;
  final DateTime? completedDate;
  final List<OrderProgress> progress;
  final String? paymentMethod;
  final bool isPaid;

  Order({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.sellerId,
    required this.sellerName,
    required this.customerId,
    required this.customerName,
    required this.price,
    this.quantity = 1,
    this.notes = '',
    required this.status,
    required this.orderDate,
    this.deadline,
    this.completedDate,
    this.progress = const [],
    this.paymentMethod,
    this.isPaid = false,
  });

  double get totalPrice => price * quantity;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      serviceId: json['serviceId'],
      serviceTitle: json['serviceTitle'],
      sellerId: json['sellerId'],
      sellerName: json['sellerName'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      price: json['price'],
      quantity: json['quantity'],
      notes: json['notes'],
      status: OrderStatus.values[json['status']],
      orderDate: DateTime.parse(json['orderDate']),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
      progress: (json['progress'] as List).map((p) => OrderProgress.fromJson(p)).toList(),
      paymentMethod: json['paymentMethod'],
      isPaid: json['isPaid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'customerId': customerId,
      'customerName': customerName,
      'price': price,
      'quantity': quantity,
      'notes': notes,
      'status': status.index,
      'orderDate': orderDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'progress': progress.map((p) => p.toJson()).toList(),
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
    };
  }
}

class OrderProgress {
  final String id;
  final int percentage;
  final String description;
  final DateTime timestamp;
  final String? imageUrl;

  OrderProgress({
    required this.id,
    required this.percentage,
    required this.description,
    required this.timestamp,
    this.imageUrl,
  });

  factory OrderProgress.fromJson(Map<String, dynamic> json) {
    return OrderProgress(
      id: json['id'],
      percentage: json['percentage'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'percentage': percentage,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}

enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  readyForReview,
  completed,
  cancelled,
  rejected,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Menunggu Konfirmasi';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.inProgress:
        return 'Sedang Dikerjakan';
      case OrderStatus.readyForReview:
        return 'Siap Review';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
      case OrderStatus.rejected:
        return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.readyForReview:
        return Colors.teal;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.rejected:
        return Colors.red;
    }
  }
}