import 'package:flutter/material.dart';
import 'dart:io';

import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/services/auth_service.dart';
import 'package:jasaku_app/models/order_model.dart';
import 'package:jasaku_app/models/user_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  List<Order> _orders = [];
  User? _me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await AuthService.getUserData();
      _me = me;
      // Request orders filtered on server by customerId or sellerId when possible
      final router = Platform.isAndroid ? ApiService.emulatorRouter : ApiService.physicalRouter;
      String url = '$router?resource=orders';
      if (me != null) {
        final id = me.id?.toString() ?? '';
        if (me.role == 'provider') {
          url += '&sellerId=$id';
        } else {
          url += '&customerId=$id';
        }
      }
      final res = await ApiService.get(url);
      final items = <Order>[];
      if (res is List) {
        for (final it in res) {
          if (it is Map<String, dynamic> || it is Map) {
            final map = Map<String, dynamic>.from(it as Map);
            try {
              items.add(Order.fromJson(map));
            } catch (_) {}
          }
        }
      }

      // Filter according to role: customer sees their orders; provider sees incoming
      if (me != null && me.role == 'provider') {
        final uid = me.id?.toString() ?? '';
        _orders = items.where((o) => o.sellerId == uid || o.sellerName == me.nama).toList();
      } else if (me != null) {
        final uid = me.id?.toString() ?? '';
        _orders = items.where((o) => o.customerId == uid || o.customerName == me.nama).toList();
      } else {
        _orders = items;
      }
    } catch (e) {
      _orders = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan Saya'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text('Belum ada pesanan'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.all(12),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = _orders[i];
                      return Card(
                        child: ListTile(
                          title: Text(o.serviceTitle),
                          subtitle: Text('${o.sellerName} • ${o.orderDate.toLocal().toString().split(' ').first}'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Rp ${o.totalPrice.toInt()}', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text(o.status.displayName, style: TextStyle(color: o.status.color)),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text('Detail Pesanan'),
                                content: Text('ID: ${o.id}\nStatus: ${o.status.displayName}\nTotal: Rp ${o.totalPrice.toInt()}'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Tutup')),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
