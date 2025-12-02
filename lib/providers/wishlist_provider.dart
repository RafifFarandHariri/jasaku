import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jasaku_app/services/api_service.dart';

class WishlistProvider with ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _isSyncing = false;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  bool get isSyncing => _isSyncing;

  // Load wishlist from local storage for given userId (or guest if userId==0)
  Future<void> load({required int userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'wishlist_${userId ?? 0}';
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        _items = [];
      }
    } else {
      _items = [];
    }
    notifyListeners();

    // Attempt background sync with server if logged in
    if (userId > 0) {
      await syncFromServer(userId: userId);
    }
  }

  Future<void> saveLocal({required int userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'wishlist_${userId ?? 0}';
    await prefs.setString(key, jsonEncode(_items));
  }

  Future<void> add(Map<String, dynamic> item, {required int userId}) async {
    // Avoid duplicates by id
    if (!_items.any((it) => it['id'] == item['id'])) {
      _items.add(item);
      notifyListeners();
      await saveLocal(userId: userId);
      if (userId > 0) await syncToServer(userId: userId);
    }
  }

  Future<void> remove(int id, {required int userId}) async {
    _items.removeWhere((it) => it['id'] == id);
    notifyListeners();
    await saveLocal(userId: userId);
    if (userId > 0) await syncToServer(userId: userId);
  }

  Future<void> moveToCart(int id, {required int userId}) async {
    // For now, moving to cart simply removes from wishlist and triggers save/sync.
    await remove(id, userId: userId);
    // TODO: call Cart API to add item to cart when available
  }

  // Server sync stubs. Expects server endpoints like 'api/user/wishlist.php'
  Future<void> syncFromServer({required int userId}) async {
    _isSyncing = true;
    notifyListeners();
    try {
      final res = await ApiService.get('api/user/wishlist.php');
      if (res is Map && res['success'] == true && res['data'] is List) {
        final List<dynamic> list = res['data'];
        _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await saveLocal(userId: userId);
        notifyListeners();
      }
    } catch (_) {
      // ignore errors; keep local copy
    }
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> syncToServer({required int userId}) async {
    // Push local wishlist to server - server should accept an array of item ids
    try {
      final payload = {'items': _items};
      await ApiService.post('api/user/wishlist_sync.php', payload);
    } catch (_) {
      // ignore
    }
  }
}
