import 'package:flutter/material.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({Key? key}) : super(key: key);

  @override
  _IncomingOrdersScreenState createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  bool _loading = true;
  List<dynamic> _orders = [];
  int _totalOrders = 0;
  double _totalRevenue = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sellerName = auth.user?.nama ?? '';
    // Server stores service seller as a name in many places. Some orders may have
    // sellerId as numeric id, but services often only have sellerName. To ensure
    // provider sees incoming orders regardless of sellerId usage, fetch all
    // orders and filter by sellerName here.
    final url = 'http://localhost/jasaku_api/api/api.php?resource=orders';
    final res = await ApiService.get(url);
    if (res is List) {
      _orders = res.where((o) {
        final sName = (o['sellerName'] ?? o['seller'] ?? '').toString();

        // sellerId in DB may be stored as int or as string (sometimes it's a name).
        // Compare carefully: if both are numeric compare as int, otherwise compare string values.
        final sellerIdRaw = o['sellerId'];
        final userId = auth.user?.id;

        bool matchesSellerId = false;
        if (sellerIdRaw != null && userId != null) {
          if (sellerIdRaw is int) {
            matchesSellerId = sellerIdRaw == userId;
          } else {
            // try parse as int, otherwise compare as string
            final parsed = int.tryParse(sellerIdRaw.toString());
            if (parsed != null) {
              matchesSellerId = parsed == userId;
            } else {
              matchesSellerId = sellerIdRaw.toString() == userId.toString();
            }
          }
        }

        return sName == sellerName || matchesSellerId;
      }).toList();
      // compute basic statistics for displayed orders
      _totalOrders = _orders.length;
      _totalRevenue = 0.0;
      for (final o in _orders) {
        final p = o['price'];
        double v = 0.0;
        if (p is int) v = p.toDouble();
        else if (p is double) v = p;
        else v = double.tryParse(p?.toString() ?? '0') ?? 0.0;
        _totalRevenue += v;
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pesanan Masuk')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text('Belum ada pesanan masuk'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Pesanan', style: TextStyle(color: Colors.grey[700])),
                                  SizedBox(height: 6),
                                  Text('$_totalOrders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Pendapatan', style: TextStyle(color: Colors.grey[700])),
                                  SizedBox(height: 6),
                                  Text(_formatCurrency(_totalRevenue), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (ctx, i) {
                          final o = _orders[i];
                          return ListTile(
                            title: Text(o['serviceTitle'] ?? 'Order'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customer: ${o['customerName'] ?? ''} • Rp ${o['price'] ?? 0}'),
                                SizedBox(height: 6),
                                Text('Status: ${_statusLabel(o['status'])}', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(o['orderDate'] ?? ''),
                                SizedBox(height: 6),
                                PopupMenuButton<String>(
                                  onSelected: (choice) async {
                                    int? newStatus;
                                    if (choice == 'Sedang Dikerjakan') newStatus = 2; // inProgress
                                    if (choice == 'Sudah Selesai') newStatus = 4; // completed
                                    if (choice == 'Pending') newStatus = 0; // pending

                                    if (newStatus != null) {
                                      final rawId = o['id'];
                                      final orderId = (rawId is int) ? rawId.toString() : (rawId?.toString() ?? '');
                                      final auth = Provider.of<AuthProvider>(context, listen: false);
                                      final Map<String, dynamic> body = {
                                        'status': newStatus,
                                        'sellerName': auth.user?.nama ?? auth.user?.email ?? ''
                                      };
                                      if (newStatus == 4) {
                                        // set completedDate when marking as completed
                                        body['completedDate'] = dateIsoNow();
                                      }
                                      final uri = 'http://localhost/jasaku_api/api/api.php?resource=orders&id=${Uri.encodeComponent(orderId)}';
                                      try {
                                        await ApiService.put(uri, body);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status diperbarui')));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui status')));
                                      }
                                      await _load();
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(value: 'Sedang Dikerjakan', child: Text('Sedang Dikerjakan')),
                                    PopupMenuItem(value: 'Sudah Selesai', child: Text('Sudah Selesai')),
                                    PopupMenuItem(value: 'Pending', child: Text('Pending')),
                                  ],
                                  child: Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String dateIsoNow() => DateTime.now().toIso8601String();

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

  String _formatCurrency(double value) {
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return f.format(value);
  }
}
