import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/providers/auth_provider.dart';

class SalesStatisticsScreen extends StatefulWidget {
  const SalesStatisticsScreen({Key? key}) : super(key: key);

  @override
  _SalesStatisticsScreenState createState() => _SalesStatisticsScreenState();
}

class _SalesStatisticsScreenState extends State<SalesStatisticsScreen> {
  bool _loading = true;
  List<dynamic> _orders = [];
  Timer? _timer;

  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  double _avgOrder = 0.0;
  List<dynamic> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
    // refresh every 10s to keep stats live for provider
    _timer = Timer.periodic(Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sellerId = auth.user?.id ?? '';

    // Try both: some records store sellerId, others store sellerName in sellerId field
    final url = 'http://localhost/jasaku_api/api/api.php?resource=orders&sellerId=$sellerId';
    final res = await ApiService.get(url);
    if (res is List) {
      _orders = res;
    } else {
      _orders = [];
    }

    // compute totals
    _totalOrders = _orders.length;
    _totalRevenue = 0.0;
    for (final o in _orders) {
      final p = o['price'];
      double v = 0.0;
      if (p is int) v = p.toDouble();
      else if (p is double) v = p;
      else v = double.tryParse(p?.toString() ?? '0') ?? 0.0;
      _totalRevenue += v * (int.tryParse(o['quantity']?.toString() ?? '1') ?? 1);
    }
    _avgOrder = _totalOrders > 0 ? (_totalRevenue / _totalOrders) : 0.0;

    // recent: sort by orderDate desc and take 5
    _recent = List.from(_orders);
    _recent.sort((a, b) {
      final da = DateTime.tryParse(a['orderDate']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b['orderDate']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    if (_recent.length > 5) _recent = _recent.sublist(0, 5);

    setState(() => _loading = false);
  }

  String _formatCurrency(double v) {
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return f.format(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Statistik Penjualan')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _buildSummaryCard(),
                  SizedBox(height: 18),
                  Text('Pendapatan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  _buildRecentCard(),
                  SizedBox(height: 18),
                  Text('Detail Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  _buildOrdersList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _summaryItem('Total Pesanan', _totalOrders.toString(), Icons.shopping_bag, Colors.blue)),
                SizedBox(width: 8),
                Expanded(child: _summaryItem('Total Pendapatan', _formatCurrency(_totalRevenue), Icons.account_balance_wallet, Colors.green)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _summaryItem('Rata-rata Order', _formatCurrency(_avgOrder), Icons.show_chart, Colors.orange)),
                Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.all(12),
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                SizedBox(height: 6),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard() {
    if (_recent.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              Text('Belum ada data', style: TextStyle(color: Colors.grey[700])),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Menampilkan 0 pesanan terakhir', style: TextStyle(color: Colors.grey[600])),
                  Text('Total: ${_formatCurrency(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    double recentTotal = 0.0;
    for (final r in _recent) {
      final p = r['price'];
      double v = 0.0;
      if (p is int) v = p.toDouble();
      else if (p is double) v = p;
      else v = double.tryParse(p?.toString() ?? '0') ?? 0.0;
      recentTotal += v * (int.tryParse(r['quantity']?.toString() ?? '1') ?? 1);
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          children: [
            ..._recent.map((r) {
              final title = r['serviceTitle'] ?? 'Order';
              final price = r['price'];
              double v = 0.0;
              if (price is int) v = price.toDouble();
              else if (price is double) v = price;
              else v = double.tryParse(price?.toString() ?? '0') ?? 0.0;
              final qty = int.tryParse(r['quantity']?.toString() ?? '1') ?? 1;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(r['orderDate'] ?? ''),
                trailing: Text(_formatCurrency(v * qty)),
              );
            }).toList(),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Menampilkan ${_recent.length} pesanan terakhir', style: TextStyle(color: Colors.grey[600])),
                  Text('Total: ${_formatCurrency(recentTotal)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) return Container(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Belum ada pesanan')));
    return Column(
      children: _orders.map((o) {
        final title = o['serviceTitle'] ?? 'Order';
        final status = o['status']?.toString() ?? '0';
        final price = o['price'];
        double v = 0.0;
        if (price is int) v = price.toDouble();
        else if (price is double) v = price;
        else v = double.tryParse(price?.toString() ?? '0') ?? 0.0;
        final qty = int.tryParse(o['quantity']?.toString() ?? '1') ?? 1;
        return ListTile(
          title: Text(title),
          subtitle: Text('Status: ${_statusLabel(o['status'])}'),
          trailing: Text(_formatCurrency(v * qty)),
        );
      }).toList(),
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
