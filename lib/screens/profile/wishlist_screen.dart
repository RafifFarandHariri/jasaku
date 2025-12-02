import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/wishlist_provider.dart';
import 'package:jasaku_app/providers/auth_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late WishlistProvider _provider;
  int _userId = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    _userId = auth.user?.id ?? 0;
    _provider = Provider.of<WishlistProvider>(context);
    // Load wishlist for user only once to avoid repeated reloads/rebuilds
    if (!_initialized) {
      _initialized = true;
      // call load but don't await here to avoid blocking build
      _provider.load(userId: _userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Consumer<WishlistProvider>(
          builder: (context, wp, _) {
            final items = wp.items;
            if (wp.isSyncing) {
              return Center(child: CircularProgressIndicator());
            }
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Wishlist Anda kosong', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Tambahkan layanan yang Anda sukai untuk menyimpannya di sini.'),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: (item['image'] != null && item['image'].toString().isNotEmpty)
                          ? Image.network(item['image'], fit: BoxFit.cover)
                          : Icon(Icons.work_outline, color: Colors.blue),
                    ),
                    title: Text(item['title'] ?? 'Untitled'),
                    subtitle: Text('${item['subtitle'] ?? ''} • ${item['price'] ?? ''}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'remove') {
                          await wp.remove(item['id'] as int, userId: _userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Item dihapus dari wishlist')),
                          );
                        } else if (value == 'move') {
                          await wp.moveToCart(item['id'] as int, userId: _userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Item dipindah ke keranjang')),
                          );
                        } else if (value == 'go') {
                          // TODO: navigate to service detail if exists
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Buka detail layanan (coming soon)')),
                          );
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'go', child: Text('Buka Layanan')),
                        PopupMenuItem(value: 'move', child: Text('Pindah ke Keranjang')),
                        PopupMenuItem(value: 'remove', child: Text('Hapus')),
                      ],
                    ),
                    onTap: () {
                      // future: open service detail
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
