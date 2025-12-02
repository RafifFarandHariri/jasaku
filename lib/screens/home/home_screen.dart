import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:jasaku_app/screens/chat/chat_list_screen.dart';
import 'package:jasaku_app/screens/profile/profile_screen.dart';
import 'package:jasaku_app/screens/product/product_list_screen.dart';
import 'package:jasaku_app/screens/service/service_detail_screen.dart';
import 'package:jasaku_app/models/service.dart';
import 'package:jasaku_app/screens/search/search_screen.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/services_provider.dart';
import 'package:jasaku_app/screens/profile/transactions_screen.dart';

// Allow dragging PageView with mouse on desktop platforms
class _DragScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _incomingCount = 0;
  List<dynamic> _services = [];
  bool _isLoadingServices = true;
  final PageController _bannerController = PageController(viewportFraction: 0.92);
  int _currentBanner = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadIncomingCount();
    _loadServices();
    _startBannerAutoScroll();
  }

  Future<void> _loadServices() async {
    setState(() { _isLoadingServices = true; });
    try {
      final res = await ApiService.get('services');
      if (res is List) {
        if (!mounted) return;
        setState(() { _services = res; _currentBanner = 0; });
        // reset page controller to first
        try { _bannerController.jumpToPage(0); } catch (_) {}
      }
    } catch (e) {
      // ignore
    }
    if (!mounted) return;
    setState(() { _isLoadingServices = false; });
  }

  @override
  void dispose() {
    _stopBannerAutoScroll();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(Duration(seconds: 4), (_) {
      if (!mounted) return;
      final count = (_services.isEmpty ? 1 : (_services.length >= 4 ? 4 : _services.length));
      if (count <= 1) return;
      final next = (_currentBanner + 1) % count;
      try {
        _bannerController.animateToPage(next, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      } catch (_) {}
      setState(() { _currentBanner = next; });
    });
  }

  void _stopBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
  }

  void _goNext() {
    final count = (_services.isEmpty ? 1 : (_services.length >= 4 ? 4 : _services.length));
    if (count <= 1) return;
    final next = (_currentBanner + 1) % count;
    try { _bannerController.animateToPage(next, duration: Duration(milliseconds: 500), curve: Curves.easeInOut); } catch (_) {}
    setState(() { _currentBanner = next; });
  }

  void _goPrev() {
    final count = (_services.isEmpty ? 1 : (_services.length >= 4 ? 4 : _services.length));
    if (count <= 1) return;
    final prev = (_currentBanner - 1 + count) % count;
    try { _bannerController.animateToPage(prev, duration: Duration(milliseconds: 500), curve: Curves.easeInOut); } catch (_) {}
    setState(() { _currentBanner = prev; });
  }

  // Custom ScrollBehavior that allows dragging with a mouse on desktop
  

  Future<void> _loadIncomingCount() async {
    try {
      // fetch orders and compute incoming count for provider
      final count = await _fetchIncomingOrdersCount();
      if (!mounted) return;
      setState(() {
        _incomingCount = count;
      });
    } catch (e) {
      // ignore errors
    }
  }

  Future<int> _fetchIncomingOrdersCount() async {
    try {
      // Use AuthService to get current user, then fetch orders and count those
      final auth = await AuthService.getUserData();
      if (auth == null) return 0;
      final res = await ApiService.get('api/orders/list.php');
      if (res is List) {
        final uid = auth.id?.toString() ?? '';
        int c = 0;
        for (final item in res) {
          if (item is Map) {
            final sellerId = (item['sellerId'] ?? '').toString();
            final sellerName = (item['sellerName'] ?? '').toString();
            if (sellerId == uid || sellerName == auth.nama) c++;
          }
        }
        return c;
      }
    } catch (e) {
      // ignore
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final servicesProv = Provider.of<ServicesProvider>(context);
    // prefer services from ServicesProvider if available
    final List<dynamic> displayServices = (servicesProv.services.isNotEmpty ? servicesProv.services : _services);
    final bool displayLoading = _isLoadingServices || (servicesProv.isLoading == true);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'JASAKU',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.all(8),
            icon: SizedBox(
              width: 40,
              height: 40,
              child: badges.Badge(
                showBadge: true,
                badgeContent: Text('3', style: TextStyle(color: Colors.white, fontSize: 9)),
                position: badges.BadgePosition.topEnd(top: -4, end: -6),
                child: Icon(Icons.chat, color: Colors.black87, size: 22),
              ),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListScreen()));
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.black87),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                _buildSearchBar(context),
                SizedBox(height: 20),

                // Banner carousel: simplified PageView with dots
                SizedBox(
                    height: 160,
                    child: displayLoading
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _bannerController,
                                itemCount: (displayServices.isEmpty ? 1 : (displayServices.length >= 4 ? 4 : displayServices.length)),
                                onPageChanged: (p) => setState(() => _currentBanner = p),
                                itemBuilder: (context, index) {
                                  if (displayServices.isEmpty) {
                                    return Container(
                                      margin: EdgeInsets.symmetric(horizontal: 8),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlue]),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Desain Logo Minimalis & Modern', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                          SizedBox(height: 8),
                                          Text('Website • UI/UX • 3D Print', style: TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                    );
                                  }

                                  final s = displayServices[index];
                                  final title = (s['title'] ?? '').toString();
                                  final category = (s['category'] ?? '').toString();
                                  final serviceType = (s['serviceType'] ?? '').toString();

                                  return GestureDetector(
                                    onTap: () {
                                      final svc = Service(
                                        id: s['id'] is int ? s['id'] : int.tryParse(s['id'].toString()) ?? 0,
                                        title: title,
                                        seller: s['seller'] ?? '',
                                        price: s['price'] is int ? s['price'] : (s['price'] is String ? int.tryParse(s['price'].toString()) ?? 0 : 0),
                                        sold: s['sold'] is int ? s['sold'] : (s['sold'] is String ? int.tryParse(s['sold'].toString()) ?? 0 : 0),
                                        rating: s['rating'] is num ? (s['rating'] as num).toDouble() : 0.0,
                                        reviews: s['reviews'] is int ? s['reviews'] : (s['reviews'] is String ? int.tryParse(s['reviews'].toString()) ?? 0 : 0),
                                        isVerified: (s['is_verified'] == 1 || s['is_verified'] == true),
                                        hasFastResponse: (s['has_fast_response'] == 1 || s['has_fast_response'] == true),
                                        category: category,
                                      );

                                      Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailScreen(service: svc)));
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 8),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlue]),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          SizedBox(height: 8),
                                          Text('$category • $serviceType', style: TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate((displayServices.isEmpty ? 1 : (displayServices.length >= 4 ? 4 : displayServices.length)), (i) {
                                final active = i == _currentBanner;
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 250),
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  width: active ? 18 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: active ? Colors.blue : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: 20),

                // Categories
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCategoryItem(context, 'Website', Icons.language),
                    _buildCategoryItem(context, 'UI/UX', Icons.design_services),
                    _buildCategoryItem(context, '3D Print', Icons.print),
                    _buildCategoryItem(context, 'Logo', Icons.brush),
                  ],
                ),
                SizedBox(height: 30),

                Text(
                  'Recommended Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                // Services List
                if (displayLoading)
                  Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (displayServices.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Belum ada layanan tersedia.', style: TextStyle(color: Colors.grey[700])),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(onPressed: _loadServices, child: Text('Refresh')),
                          ],
                        )
                      ],
                    ),
                  )
                else ...displayServices.map((s) => _buildServiceCardFromMap(context, s)).toList(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, 0),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchScreen()),
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 12),
            Text(
              'Search services...',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(category: title),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: Colors.blue, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, String title, String seller, int sold, double rating, int reviews, String price, {dynamic serviceMap}) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (serviceMap != null) {
            final s = serviceMap;
            final svc = Service(
              id: s['id'] is int ? s['id'] : int.tryParse(s['id'].toString()) ?? 0,
              title: (s['title'] ?? '').toString(),
              seller: s['seller'] ?? '',
              price: s['price'] is int ? s['price'] : (s['price'] is String ? int.tryParse(s['price'].toString()) ?? 0 : 0),
              sold: s['sold'] is int ? s['sold'] : (s['sold'] is String ? int.tryParse(s['sold'].toString()) ?? 0 : 0),
              rating: s['rating'] is num ? (s['rating'] as num).toDouble() : 0.0,
              reviews: s['reviews'] is int ? s['reviews'] : (s['reviews'] is String ? int.tryParse(s['reviews'].toString()) ?? 0 : 0),
              isVerified: (s['is_verified'] == 1 || s['is_verified'] == true),
              hasFastResponse: (s['has_fast_response'] == 1 || s['has_fast_response'] == true),
              category: (s['category'] ?? '').toString(),
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ServiceDetailScreen(service: svc)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.design_services, color: Colors.grey, size: 40),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      seller,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Verified',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Fast Resp',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terjual $sold',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            RatingBar.builder(
                              initialRating: rating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 12,
                              itemBuilder: (context, _) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {},
                              ignoreGestures: true,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '$rating ($reviews)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCardFromMap(BuildContext context, dynamic s) {
    final title = s['title'] ?? 'Untitled';
    final seller = s['seller'] ?? '';
    final sold = s['sold'] is int ? s['sold'] : (s['sold'] != null ? int.tryParse(s['sold'].toString()) ?? 0 : 0);
    final rating = s['rating'] is num ? (s['rating'] as num).toDouble() : 0.0;
    final reviews = s['reviews'] is int ? s['reviews'] : (s['reviews'] != null ? int.tryParse(s['reviews'].toString()) ?? 0 : 0);
    final priceVal = s['price'] ?? 0;
    final price = 'Rp ${priceVal.toString()}';

    return _buildServiceItem(context, title, seller, sold, rating, reviews, price, serviceMap: s);
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: badges.Badge(
            showBadge: _incomingCount > 0,
            badgeContent: Text('$_incomingCount', style: TextStyle(color: Colors.white, fontSize: 10)),
            child: Icon(Icons.shopping_cart),
            position: badges.BadgePosition.topEnd(top: -6, end: -6),
          ),
          label: 'Orders',
        ),
      ],
      onTap: (index) async {
        if (index == 1) { // Search tab
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TransactionsScreen()),
          ).then((_) => _loadIncomingCount());
        }
        // Handle other tabs...
      },
    );
  }
}