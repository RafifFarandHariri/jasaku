import 'package:flutter/material.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  int _ordersCount = 0;
  double _revenue = 0.0;
  double _avgOrder = 0.0;
  List<double> _recent = []; // recent order amounts for sparkline

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sellerId = auth.user?.id ?? 0;
    final url = 'http://localhost/jasaku_api/api/api.php?resource=orders&sellerId=$sellerId';
    final res = await ApiService.get(url);
    List<dynamic> my = [];
    if (res is List) {
      my = res;
    }

    _ordersCount = my.length;
    _revenue = my.fold(0.0, (sum, o) => sum + (double.tryParse((o['price'] ?? 0).toString()) ?? 0.0));
    _avgOrder = _ordersCount > 0 ? (_revenue / _ordersCount) : 0.0;

    // recent amounts (last 8 orders)
    _recent = my.reversed
        .take(8)
        .map((o) => double.tryParse((o['price'] ?? 0).toString())?.toDouble() ?? 0.0)
        .toList();

    setState(() => _loading = false);
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[700])),
                  SizedBox(height: 6),
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sparkline(List<double> values) {
    if (values.isEmpty) return Center(child: Text('Belum ada data'));
    final maxv = values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values.map((v) {
        final h = maxv == 0 ? 4.0 : (v / maxv) * 60 + 4;
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: h,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Statistik Penjualan')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    _statCard('Total Pesanan', '$_ordersCount', Colors.blue, Icons.shopping_bag_outlined),
                    _statCard('Total Pendapatan', 'Rp ${_revenue.toStringAsFixed(0)}', Colors.green, Icons.account_balance_wallet_outlined),
                    _statCard('Rata-rata Order', 'Rp ${_avgOrder.toStringAsFixed(0)}', Colors.orange, Icons.show_chart),
                    SizedBox(height: 20),
                    Text('Pendapatan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            SizedBox(height: 8),
                            SizedBox(height: 80, child: _sparkline(_recent)),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Menampilkan ${_recent.length} pesanan terakhir', style: TextStyle(color: Colors.grey[600])),
                                Text('Total: Rp ${_recent.fold(0.0, (s, e) => s + e).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text('Detail Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    // Simple list of recent orders
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _recent.length,
                      separatorBuilder: (_, __) => Divider(),
                      itemBuilder: (ctx, i) {
                        final amt = _recent[i];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.attach_money, color: Colors.white)),
                          title: Text('Pesanan #${i + 1}'),
                          subtitle: Text('Rp ${amt.toStringAsFixed(0)}'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
