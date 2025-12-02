import 'package:jasaku_app/models/order_model.dart';

class OrderService {
  // Simulate order data - in real app, this would be from API
  static final List<Order> _orders = [
    Order(
      id: '1',
      serviceId: '1',
      serviceTitle: 'Design Logo Murah & Terbaik - Bebas Revisi',
      sellerId: 'seller1',
      sellerName: 'Fadhil Jofan Syahputra',
      customerId: 'customer1',
      customerName: 'Angga Dwi Prastyo',
      price: 500000,
      quantity: 1,
      notes: 'Tolong dibuat dengan konsep minimalis dan modern',
      status: OrderStatus.completed,
      orderDate: DateTime(2025, 10, 20),
      deadline: DateTime(2025, 10, 27),
      completedDate: DateTime(2025, 10, 25),
      progress: [
        OrderProgress(
          id: '1',
          percentage: 0,
          description: 'Pesanan diterima',
          timestamp: DateTime(2025, 10, 20),
        ),
        OrderProgress(
          id: '2',
          percentage: 50,
          description: 'Konsep awal sudah dibuat',
          timestamp: DateTime(2025, 10, 22),
        ),
        OrderProgress(
          id: '3',
          percentage: 100,
          description: 'Final design sudah selesai',
          timestamp: DateTime(2025, 10, 25),
        ),
      ],
      paymentMethod: 'Transfer Bank',
      isPaid: true,
    ),
    Order(
      id: '2',
      serviceId: '2',
      serviceTitle: 'Design Website HTML CSS JS PHP',
      sellerId: 'seller2',
      sellerName: 'Hanan Rasyad Sadad',
      customerId: 'customer1',
      customerName: 'Angga Dwi Prastyo',
      price: 1500000,
      quantity: 1,
      notes: 'Website company profile dengan responsive design',
      status: OrderStatus.inProgress,
      orderDate: DateTime(2025, 11, 1),
      deadline: DateTime(2025, 11, 15),
      progress: [
        OrderProgress(
          id: '1',
          percentage: 0,
          description: 'Pesanan dikonfirmasi',
          timestamp: DateTime(2025, 11, 1),
        ),
        OrderProgress(
          id: '2',
          percentage: 30,
          description: 'UI Design selesai',
          timestamp: DateTime(2025, 11, 5),
        ),
      ],
      paymentMethod: 'E-Wallet',
      isPaid: true,
    ),
  ];

  static Future<List<Order>> getCustomerOrders(String customerId) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate API call
    return _orders.where((order) => order.customerId == customerId).toList();
  }

  static Future<List<Order>> getSellerOrders(String sellerId) async {
    await Future.delayed(Duration(seconds: 1));
    return _orders.where((order) => order.sellerId == sellerId).toList();
  }

  static Future<Order> createOrder({
    required String serviceId,
    required String serviceTitle,
    required String sellerId,
    required String sellerName,
    required String customerId,
    required String customerName,
    required double price,
    int quantity = 1,
    String notes = '',
    DateTime? deadline,
    String paymentMethod = 'Transfer Bank',
  }) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate API call

    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      sellerId: sellerId,
      sellerName: sellerName,
      customerId: customerId,
      customerName: customerName,
      price: price,
      quantity: quantity,
      notes: notes,
      status: OrderStatus.pending,
      orderDate: DateTime.now(),
      deadline: deadline,
      paymentMethod: paymentMethod,
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

    _orders.insert(0, newOrder);
    return newOrder;
  }

  static Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await Future.delayed(Duration(seconds: 1));
    final order = _orders.firstWhere((order) => order.id == orderId);
    final index = _orders.indexWhere((order) => order.id == orderId);
    
    _orders[index] = Order(
      id: order.id,
      serviceId: order.serviceId,
      serviceTitle: order.serviceTitle,
      sellerId: order.sellerId,
      sellerName: order.sellerName,
      customerId: order.customerId,
      customerName: order.customerName,
      price: order.price,
      quantity: order.quantity,
      notes: order.notes,
      status: newStatus,
      orderDate: order.orderDate,
      deadline: order.deadline,
      completedDate: newStatus == OrderStatus.completed ? DateTime.now() : order.completedDate,
      progress: order.progress,
      paymentMethod: order.paymentMethod,
      isPaid: order.isPaid,
    );
  }

  static Future<void> addOrderProgress(String orderId, OrderProgress progress) async {
    await Future.delayed(Duration(seconds: 1));
    final order = _orders.firstWhere((order) => order.id == orderId);
    final index = _orders.indexWhere((order) => order.id == orderId);
    
    final updatedProgress = List<OrderProgress>.from(order.progress)..add(progress);
    
    _orders[index] = Order(
      id: order.id,
      serviceId: order.serviceId,
      serviceTitle: order.serviceTitle,
      sellerId: order.sellerId,
      sellerName: order.sellerName,
      customerId: order.customerId,
      customerName: order.customerName,
      price: order.price,
      quantity: order.quantity,
      notes: order.notes,
      status: order.status,
      orderDate: order.orderDate,
      deadline: order.deadline,
      completedDate: order.completedDate,
      progress: updatedProgress,
      paymentMethod: order.paymentMethod,
      isPaid: order.isPaid,
    );
  }
}