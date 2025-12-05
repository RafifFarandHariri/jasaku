import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:jasaku_app/services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  List<dynamic> _orders = [];

  int _totalOrders = 0;
  int _incomingOrders = 0;
  double _totalRevenue = 0.0; // revenue from completed orders

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sellerId = auth.user?.id ?? '';
    final sellerName = auth.user?.nama ?? '';

    final routerBase = 'http://localhost/jasaku_api/api/api.php';
    // try by sellerId
    final urlById = '$routerBase?resource=orders&sellerId=$sellerId';
    dynamic res = await ApiService.get(urlById);
    if (res is List) {
      _orders = res;
    } else {
      _orders = [];
    }

    // fallback: by sellerName
    if (_orders.isEmpty && sellerName.isNotEmpty) {
      final urlByName = '$routerBase?resource=orders&sellerName=${Uri.encodeQueryComponent(sellerName)}';
      final res2 = await ApiService.get(urlByName);
      if (res2 is List) _orders = res2;
    }

    // final fallback: fetch all and filter locally by normalized seller id/name
    if (_orders.isEmpty) {
      final urlAll = '$routerBase?resource=orders';
      final resAll = await ApiService.get(urlAll);
      if (resAll is List) {
        final sid = sellerId.toString().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
        final sname = sellerName.toString().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
        _orders = (resAll as List).where((o) {
          try {
            final osid = (o['sellerId'] ?? '').toString().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
            final oname = (o['sellerName'] ?? '').toString().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
            if (sid.isNotEmpty && osid == sid) return true;
            if (sname.isNotEmpty && oname == sname) return true;
            if (sid.isNotEmpty && oname.contains(sid)) return true;
            if (sname.isNotEmpty && osid.contains(sname)) return true;
          } catch (_) {}
          return false;
        }).toList();
      }
    }

    // compute metrics
    _totalOrders = _orders.length;
    _incomingOrders = _orders.where((o) {
      final st = o['status'];
      final s = int.tryParse(st?.toString() ?? '') ?? -1;
      return s == 0; // pending
    }).length;

    double revenue = 0.0;
    for (final o in _orders) {
      final st = o['status'];
      final s = int.tryParse(st?.toString() ?? '') ?? -1;
      if (s == 4) { // completed orders count toward revenue
        final p = o['price'];
        final q = o['quantity'] ?? 1;
        double price = 0.0;
        if (p is int) price = p.toDouble();
        else if (p is double) price = p;
        else price = double.tryParse(p?.toString() ?? '0') ?? 0.0;
        final qty = int.tryParse(q?.toString() ?? '1') ?? 1;
        revenue += price * qty;
      }
    }
    _totalRevenue = revenue;

    setState(() => _loading = false);
  }

  String _fmtCurrency(double v) {
    final rounded = v.toStringAsFixed(0);
    return 'Rp $rounded';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Penjualan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Pesanan', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  Text('$_totalOrders', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pesanan Masuk', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  Text('$_incomingOrders', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Pendapatan (Selesai)', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  Text(_fmtCurrency(_totalRevenue), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Pesanan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _orders.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('Belum ada pesanan')))
                        : Column(
                            children: _orders.reversed.take(8).map((o) {
                              final id = o['id'] ?? o['order_id'] ?? '—';
                              final status = o['status']?.toString() ?? '-';
                              final priceRaw = o['price'];
                              double price = 0.0;
                              if (priceRaw is int) price = priceRaw.toDouble();
                              else if (priceRaw is double) price = priceRaw;
                              else price = double.tryParse(priceRaw?.toString() ?? '0') ?? 0.0;
                              final qty = int.tryParse((o['quantity'] ?? 1).toString()) ?? 1;
                              final date = o['created_at'] ?? o['order_date'] ?? '';
                              return ListTile(
                                title: Text('#$id'),
                                subtitle: Text('Status: $status • ${date.toString().substring(0, 10)}'),
                                trailing: Text(_fmtCurrency(price * qty)),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
