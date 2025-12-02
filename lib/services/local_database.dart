import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';
import '../models/service.dart';
import '../models/order_model.dart';
import '../models/chat_model.dart';
import '../models/payment_model.dart';

class LocalDatabase {
  LocalDatabase._privateConstructor();
  static final LocalDatabase instance = LocalDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'jasaku_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nrp TEXT,
        nama TEXT,
        email TEXT,
        phone TEXT,
        profile_image TEXT,
        role TEXT,
        is_verified_provider INTEGER,
        provider_since TEXT,
        provider_description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE services(
        id INTEGER PRIMARY KEY,
        title TEXT,
        seller TEXT,
        price INTEGER,
        sold INTEGER,
        rating REAL,
        reviews INTEGER,
        is_verified INTEGER,
        has_fast_response INTEGER,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id TEXT PRIMARY KEY,
        serviceId TEXT,
        serviceTitle TEXT,
        sellerId TEXT,
        sellerName TEXT,
        customerId TEXT,
        customerName TEXT,
        price REAL,
        quantity INTEGER,
        notes TEXT,
        status INTEGER,
        orderDate TEXT,
        deadline TEXT,
        completedDate TEXT,
        paymentMethod TEXT,
        isPaid INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE order_progress(
        id TEXT PRIMARY KEY,
        orderId TEXT,
        percentage INTEGER,
        description TEXT,
        timestamp TEXT,
        imageUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id TEXT PRIMARY KEY,
        orderId TEXT,
        amount REAL,
        paymentMethod TEXT,
        status INTEGER,
        createdAt TEXT,
        paidAt TEXT,
        qrCodeUrl TEXT,
        paymentReference TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chats(
        id TEXT PRIMARY KEY,
        conversationId TEXT,
        text TEXT,
        isMe INTEGER,
        timestamp TEXT,
        type INTEGER,
        senderName TEXT,
        serviceId TEXT,
        proposedPrice REAL,
        offerId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE price_offers(
        id TEXT PRIMARY KEY,
        serviceId TEXT,
        originalPrice REAL,
        proposedPrice REAL,
        message TEXT,
        status INTEGER,
        createdAt TEXT,
        respondedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE wishlist(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        serviceId INTEGER
      )
    ''');
  }

  // ---------- Users ----------
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return User.fromJson(maps.first);
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update('users', user.toJson(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Services ----------
  Future<int> insertService(Service s) async {
    final db = await database;
    final map = {
      'id': s.id,
      'title': s.title,
      'seller': s.seller,
      'price': s.price,
      'sold': s.sold,
      'rating': s.rating,
      'reviews': s.reviews,
      'is_verified': s.isVerified ? 1 : 0,
      'has_fast_response': s.hasFastResponse ? 1 : 0,
      'category': s.category,
    };
    return await db.insert('services', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Service>> getAllServices() async {
    final db = await database;
    final rows = await db.query('services');
    return rows.map((r) => Service(
      id: r['id'] as int,
      title: r['title'] as String,
      seller: r['seller'] as String,
      price: r['price'] as int,
      sold: r['sold'] as int,
      rating: (r['rating'] as num).toDouble(),
      reviews: r['reviews'] as int,
      isVerified: (r['is_verified'] as int) == 1,
      hasFastResponse: (r['has_fast_response'] as int) == 1,
      category: r['category'] as String?,
    )).toList();
  }

  // ---------- Orders ----------
  Future<int> insertOrder(Order order) async {
    final db = await database;
    final map = Map<String, dynamic>.from(order.toJson());
    // Remove progress from main order row; progress stored separately
    map.remove('progress');
    map['isPaid'] = order.isPaid ? 1 : 0;
    return await db.insert('orders', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Order>> getOrdersForUser(String userId) async {
    final db = await database;
    final rows = await db.query('orders', where: 'customerId = ?', whereArgs: [userId]);
    return rows.map((r) {
      return Order(
        id: r['id'] as String,
        serviceId: r['serviceId'] as String,
        serviceTitle: r['serviceTitle'] as String,
        sellerId: r['sellerId'] as String,
        sellerName: r['sellerName'] as String,
        customerId: r['customerId'] as String,
        customerName: r['customerName'] as String,
        price: (r['price'] as num).toDouble(),
        quantity: r['quantity'] as int,
        notes: (r['notes'] as String?) ?? '',
        status: OrderStatus.values[(r['status'] ?? 0) as int],
        orderDate: DateTime.parse(r['orderDate'] as String),
        deadline: r['deadline'] != null ? DateTime.parse(r['deadline'] as String) : null,
        completedDate: r['completedDate'] != null ? DateTime.parse(r['completedDate'] as String) : null,
        progress: [],
        paymentMethod: r['paymentMethod'] as String?,
        isPaid: (r['isPaid'] as int) == 1,
      );
    }).toList();
  }

  Future<int> insertOrderProgress(OrderProgress p) async {
    final db = await database;
    return await db.insert('order_progress', p.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------- Payments ----------
  Future<int> insertPayment(Payment p) async {
    final db = await database;
    return await db.insert('payments', p.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Payment>> getPaymentsForOrder(String orderId) async {
    final db = await database;
    final rows = await db.query('payments', where: 'orderId = ?', whereArgs: [orderId]);
    return rows.map((r) => Payment.fromJson(r)).toList();
  }

  // ---------- Chats & Offers ----------
  Future<int> insertChatMessage(ChatMessage m, {String? conversationId}) async {
    final db = await database;
    final map = m.toJson();
    map['isMe'] = m.isMe ? 1 : 0;
    map['conversationId'] = conversationId;
    return await db.insert('chats', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getChatMessages(String conversationId) async {
    final db = await database;
    final rows = await db.query('chats', where: 'conversationId = ?', whereArgs: [conversationId], orderBy: 'timestamp ASC');
    return rows.map((r) => ChatMessage.fromJson({
      'id': r['id'],
      'text': r['text'],
      'isMe': (r['isMe'] as int) == 1,
      'timestamp': r['timestamp'],
      'type': r['type'],
      'senderName': r['senderName'],
      'serviceId': r['serviceId'],
      'proposedPrice': r['proposedPrice'],
      'offerId': r['offerId'],
    })).toList();
  }

  Future<int> insertPriceOffer(PriceOffer offer) async {
    final db = await database;
    final map = {
      'id': offer.id,
      'serviceId': offer.serviceId,
      'originalPrice': offer.originalPrice,
      'proposedPrice': offer.proposedPrice,
      'message': offer.message,
      'status': offer.status.index,
      'createdAt': offer.createdAt.toIso8601String(),
      'respondedAt': offer.respondedAt?.toIso8601String(),
    };
    return await db.insert('price_offers', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? args]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future close() async {
    final db = await database;
    return db.close();
  }
}
