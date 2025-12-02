import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _loading = true;
  List<dynamic> _orders = [];
  Timer? _timer;

  @override
  @override
  void initState() {
    super.initState();
    // periodic refresh so customer sees provider-updated statuses quickly
    _load();
    _timer = Timer.periodic(Duration(seconds: 10), (_) async {
      await _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // keep behavior compatible if dependencies change
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id ?? 0;
    final url = 'http://localhost/jasaku_api/api/api.php?resource=orders&customerId=$userId';
    final res = await ApiService.get(url);
    if (res is List) _orders = res;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text('Belum ada transaksi'))
              : ListView.separated(
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (ctx, i) {
                    final o = _orders[i];
                    return ListTile(
                      title: Text(o['serviceTitle'] ?? 'Order'),
                      subtitle: Text('Status: ${_statusLabel(o['status'])} • Rp ${o['price'] ?? 0}'),
                      trailing: Text(o['orderDate'] ?? ''),
                    );
                  },
                ),
    );
  }

  String _statusLabel(dynamic raw) {
    if (raw == null) return 'Unknown';
    if (raw is int) {
      switch (raw) {
        case 0:
          return 'Pending';
        case 1:
          return 'Konfirmasi';
        case 2:
          return 'Sedang Dikerjakan';
        case 3:
          return 'Siap Review';
        case 4:
          return 'Sudah Selesai';
        case 5:
          return 'Dibatalkan';
        default:
          return raw.toString();
      }
    }
    final parsed = int.tryParse(raw.toString());
    if (parsed != null) return _statusLabel(parsed);
    return raw.toString();
  }
}
