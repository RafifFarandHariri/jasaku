import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:jasaku_app/models/service.dart';
import 'package:jasaku_app/screens/chat/chat_detail_screen.dart';
import 'package:jasaku_app/screens/order/create_order_screen.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:jasaku_app/providers/wishlist_provider.dart';

// Uses shared `Service` model from `lib/models/service.dart`
class ServiceDetailScreen extends StatefulWidget {
  final Service? service;
  const ServiceDetailScreen({Key? key, this.service}) : super(key: key);

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late Service serviceData;
  Map<String, dynamic>? _selectedPackage;
  double _myRating = 0.0;
  final _commentCtl = TextEditingController();
  bool _isSubmitting = false;
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    serviceData = widget.service ?? Service(
      id: 1,
      title: 'Design Logo Murah & Terbaik - Bebas Revisi',
      seller: 'Fadhil Jofan Syahputra',
      price: 50000,
      sold: 300,
      rating: 4.9,
      reviews: 266,
      isVerified: true,
      hasFastResponse: true,
    );
    _loadReviews();
  }

  @override
  void dispose() {
    _commentCtl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silakan login terlebih dahulu untuk memberikan rating')));
      return;
    }
    if (_myRating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilih rating terlebih dahulu')));
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'serviceId': serviceData.id,
      'userId': user.id?.toString(),
      'userName': user.nama,
      'rating': _myRating,
      'comment': _commentCtl.text.trim(),
    };

    final res = await ApiService.post('reviews', payload);

    setState(() => _isSubmitting = false);

    if (res is Map && res.containsKey('id')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terima kasih atas ulasan Anda'), backgroundColor: Colors.green));
      // Try to refresh service aggregate by fetching services list and updating local state
      final sres = await ApiService.get('services');
      if (sres is List) {
        final found = sres.firstWhere((e) => e['id'] == serviceData.id, orElse: () => null);
        if (found != null) {
          try {
            final svc = Service.fromJson(Map<String, dynamic>.from(found as Map));
            setState(() { serviceData = svc; });
          } catch (_) {
            // fallback: keep existing
          }
        }
      }
      // refresh reviews list (prefer to fetch server reviews and filter by serviceId)
      await _loadReviews();
      _myRating = 0.0;
      _commentCtl.clear();
    } else {
      final msg = (res is Map && res['message'] != null) ? res['message'] : 'Gagal mengirim ulasan';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  Future<void> _loadReviews() async {
    setState(() { _isLoadingReviews = true; });
    try {
      final res = await ApiService.get('reviews');
      if (res is List) {
        final filtered = res.where((r) {
          try {
            return r['serviceId'] == serviceData.id || r['serviceId'].toString() == serviceData.id.toString();
          } catch (_) { return false; }
        }).toList();
        if (!mounted) return;
        setState(() { _reviews = filtered; });
      }
    } catch (e) {
      // ignore
    }
    if (!mounted) return;
    setState(() { _isLoadingReviews = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            // Add wishlist action button
            actions: [
              Consumer2<WishlistProvider, AuthProvider>(
                builder: (context, wishlist, auth, _) {
                  final userId = auth.user?.id ?? 0;
                  final exists = wishlist.items.any((it) {
                    try {
                      return it['id'] == serviceData.id || it['id'].toString() == serviceData.id.toString();
                    } catch (_) {
                      return false;
                    }
                  });

                  return IconButton(
                    tooltip: exists ? 'Hapus dari Wishlist' : 'Tambah ke Wishlist',
                    icon: Icon(
                      exists ? Icons.favorite : Icons.favorite_border,
                      color: exists ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        if (exists) {
                          await wishlist.remove(serviceData.id, userId: userId);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dihapus dari wishlist')));
                        } else {
                          final item = {
                            'id': serviceData.id,
                            'title': serviceData.title,
                            'price': serviceData.price,
                            'seller': serviceData.seller,
                            'category': serviceData.category,
                          };
                          await wishlist.add(item, userId: userId);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ditambahkan ke wishlist')));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengupdate wishlist: $e')));
                      }
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: _getCategoryColor(serviceData.title),
                child: Icon(
                  _getCategoryIcon(serviceData.title),
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Seller
                  Text(
                    serviceData.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, size: 16),
                      ),
                      SizedBox(width: 8),
                      Text(serviceData.seller),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Stats
                  Row(
                    children: [
                      _buildStatItem('Terjual', '${serviceData.sold}'),
                      _buildStatItem('Rating', '${serviceData.rating}'),
                      _buildStatItem('Ulasan', '${serviceData.reviews}'),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Price / Description
                  Text(
                    'Deskripsi Layanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    // try to show description if server provided it, otherwise a short placeholder
                    (serviceData is dynamic && (serviceData is Map || serviceData != null)) ? (serviceData is Service ? (serviceData.title) : '') : '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 20),
                  // Packages selection
                  if (serviceData.packages != null && serviceData.packages!.isNotEmpty) ...[
                    Text('Pilih Paket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Column(
                      children: serviceData.packages!.map((pkg) {
                        final Map<String, dynamic> package = Map<String,dynamic>.from(pkg);
                        final bool selected = _selectedPackage != null && (_selectedPackage!['id'].toString() == package['id'].toString());
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: RadioListTile<String>(
                            value: package['id'].toString(),
                            groupValue: _selectedPackage != null ? _selectedPackage!['id'].toString() : null,
                            onChanged: (v) {
                              setState(() { _selectedPackage = package; });
                            },
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(package['title'] ?? 'Paket')),
                                Text('Rp ${package['price'] ?? 0}'),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((package['description'] ?? '').toString().isNotEmpty) Text(package['description'].toString()),
                                SizedBox(height: 4),
                                Text('${package['delivery_days'] ?? 0} hari • ${package['revisions'] ?? 0} revisi', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                            selected: selected,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12),
                  ],
                  Divider(),

                  // Seller Info
                  Text(
                    'Tentang Penjual',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        serviceData.seller.isNotEmpty ? serviceData.seller[0] : 'F', 
                        style: TextStyle(color: Colors.white)
                      ),
                    ),
                    title: Text(serviceData.seller),
                    subtitle: Text('${serviceData.isVerified ? 'Verified Seller' : ''}${serviceData.isVerified && serviceData.hasFastResponse ? ' • ' : ''}${serviceData.hasFastResponse ? 'Fast Response' : ''}'),
                  ),

                  // Reviews
                  SizedBox(height: 20),
                  Text(
                    'Ulasan (${serviceData.reviews})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_isLoadingReviews)
                    Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  else if (_reviews.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Belum ada ulasan untuk layanan ini.', style: TextStyle(color: Colors.grey[700])),
                    )
                  else ..._reviews.map((r) {
                    final name = r['userName'] ?? r['user'] ?? 'Anonim';
                    final date = r['created_at'] ?? r['createdAt'] ?? '';
                    final comment = r['comment'] ?? '';
                    return _buildReviewItem(name.toString(), date.toString(), comment.toString());
                  }).toList(),

                  SizedBox(height: 12),
                  Text(
                    'Beri Ulasan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 0.5,
                    allowHalfRating: true,
                    itemSize: 28,
                    itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (r) => setState(() => _myRating = r),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _commentCtl,
                    maxLines: 3,
                    decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Tulis komentar (opsional)'),
                  ),
                  SizedBox(height: 8),
                  _isSubmitting
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitReview,
                            child: Text('Kirim Ulasan'),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      // GANTI bagian bottomNavigationBar yang lama dengan ini:
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
              Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.chat),
                label: Text('Chat dengan penjual'),
                onPressed: () async {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final user = auth.user;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silakan login terlebih dahulu untuk memulai chat')));
                    return;
                  }

                  // Build a deterministic conversation identifier between current user and seller.
                  // We use the current user's id plus the seller name (sanitized) so both sides can compute the same id.
                  final buyerToken = user.id?.toString() ?? '';
                  final sellerToken = serviceData.seller.replaceAll(RegExp(r"[^A-Za-z0-9_]"), '');
                  final pair = Uri.encodeComponent('$buyerToken,$sellerToken');
                  final url = 'http://localhost/jasaku_api/api/api.php?resource=chats&conversationBetween=$pair';

                  try {
                    // Try to resolve seller to a numeric user id by querying users
                    String sellerTokenResolved = sellerToken; // default
                    try {
                      final usersRes = await ApiService.get('users');
                      if (usersRes is List) {
                        // Prefer exact match on name, otherwise partial contains
                        var found = usersRes.firstWhere((u) => (u['nama'] ?? '').toString() == serviceData.seller, orElse: () => null);
                        if (found == null) {
                          found = usersRes.firstWhere((u) => (u['nama'] ?? '').toString().toLowerCase().contains(serviceData.seller.toLowerCase()), orElse: () => null);
                        }
                        if (found != null && found['id'] != null) {
                          sellerTokenResolved = found['id'].toString();
                        }
                      }
                    } catch (_) {
                      // ignore lookup errors and fall back to seller name
                    }

                    final pair = Uri.encodeComponent('$buyerToken,$sellerTokenResolved');
                    final url2 = 'http://localhost/jasaku_api/api/api.php?resource=chats&conversationBetween=$pair';
                    final res = await ApiService.get(url2);
                    String convId = '';
                    if (res is Map && res['conversationId'] != null) convId = res['conversationId'].toString();
                    if (convId.isEmpty && res is String) convId = res;
                    if (convId.isEmpty) {
                      // Fallback: create a deterministic id locally
                      convId = 'conv_${buyerToken}_${sellerTokenResolved}';
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          contactName: serviceData.seller,
                          contactInitial: serviceData.seller.isNotEmpty ? serviceData.seller[0] : 'S',
                          service: serviceData,
                          conversationId: convId,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat percakapan: $e'), backgroundColor: Colors.red));
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.shopping_cart),
                label: Text('Order Sekarang'),
                onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateOrderScreen(service: serviceData, selectedPackage: _selectedPackage),
                      ),
                    );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricePackage(String price, String package, String features) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      package,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Chat dengan penjual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              features,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String name, String date, String review) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 8),
            RatingBar.builder(
              initialRating: 5,
              itemSize: 16,
              itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {},
              ignoreGestures: true,
            ),
            SizedBox(height: 8),
            Text(review),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String title) {
    if (title.toLowerCase().contains('logo')) return Colors.purple;
    if (title.toLowerCase().contains('website') || title.toLowerCase().contains('web')) return Colors.blue;
    if (title.toLowerCase().contains('video') || title.toLowerCase().contains('motion')) return Colors.red;
    return Colors.green;
  }

  IconData _getCategoryIcon(String title) {
    if (title.toLowerCase().contains('logo')) return Icons.brush;
    if (title.toLowerCase().contains('website') || title.toLowerCase().contains('web')) return Icons.language;
    if (title.toLowerCase().contains('video') || title.toLowerCase().contains('motion')) return Icons.videocam;
    return Icons.design_services;
  }
}