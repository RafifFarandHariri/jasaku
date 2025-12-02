import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:jasaku_app/screens/service/service_detail_screen.dart';
import 'package:jasaku_app/models/service.dart';


class ProductListScreen extends StatefulWidget {
  final String category;

  const ProductListScreen({Key? key, required this.category}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final List<Service> _services = [
    Service(
      id: 1,
      title: 'Design Logo Murah & Terbaik - Bebas Revisi',
      seller: 'Fadhil Jofan Syahputra',
      price: 50000,
      sold: 300,
      rating: 4.9,
      reviews: 266,
      isVerified: true,
      hasFastResponse: true,
    ),
    Service(
      id: 2,
      title: 'Design Website HTML CSS JS PHP',
      seller: 'Hanan Rasyad Sadad',
      price: 500000,
      sold: 800,
      rating: 4.9,
      reviews: 760,
      isVerified: true,
      hasFastResponse: true,
    ),
    Service(
      id: 3,
      title: 'Logo Minimalis UMKM, FASHION, TOKO ONLINE, KO...',
      seller: 'Alman Wicaksono',
      price: 75000,
      sold: 250,
      rating: 4.1,
      reviews: 150,
      isVerified: true,
      hasFastResponse: true,
    ),
    Service(
      id: 4,
      title: 'Jasa Pembuatan Web Aplikasi Modern',
      seller: 'Capek Jadek Alta Shibaidi Abigaya Tanmanya Tiratayam',
      price: 1000000,
      sold: 1000,
      rating: 4.9,
      reviews: 956,
      isVerified: true,
      hasFastResponse: true,
    ),
    Service(
      id: 5,
      title: 'Video Editor Professional Apa Saja Bisa',
      seller: 'Tirta Affandi',
      price: 250000,
      sold: 500,
      rating: 4.5,
      reviews: 471,
      isVerified: true,
      hasFastResponse: true,
    ),
    Service(
      id: 6,
      title: 'Professional Motion Graphics Editing | SUPER CEPAT DAN ...',
      seller: 'Tirta Affandi',
      price: 300000,
      sold: 321,
      rating: 4.1,
      reviews: 150,
      isVerified: true,
      hasFastResponse: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.category,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Filter functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort & Filter Bar
          _buildSortFilterBar(),
          
          // Products List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                return _buildServiceCard(_services[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_services.length} jasa ditemukan',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                'Urutkan: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              DropdownButton<String>(
                value: 'Populer',
                items: [
                  'Populer',
                  'Termurah',
                  'Termahal',
                  'Rating Tertinggi',
                  'Terbaru',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  // Sort functionality
                },
                underline: SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(service: service),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _getCategoryColor(service.title),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(service.title),
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(width: 12),
              
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      service.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    
                    // Seller
                    Text(
                      service.seller,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    
                    // Badges
                    Row(
                      children: [
                        if (service.isVerified)
                          _buildBadge('Verified', Colors.green),
                        if (service.hasFastResponse)
                          SizedBox(width: 6),
                        if (service.hasFastResponse)
                          _buildBadge('Fast Resp', Colors.orange),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Stats & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terjual ${service.sold}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Row(
                          children: [
                            RatingBar.builder(
                              initialRating: service.rating,
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
                              '${service.rating} (${service.reviews})',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Price
                    Text(
                      'Rp ${service.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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

// Uses `Service` model from `lib/models/service.dart`