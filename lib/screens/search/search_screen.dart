import 'package:flutter/material.dart';
import 'package:jasaku_app/screens/service/service_detail_screen.dart';
import 'package:jasaku_app/models/service.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/services_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [
    'Desain Logo',
    'Website',
    '3D Printing',
    'UI/UX Design',
    'Video Editing'
  ];

  final List<String> _popularSearches = [
    'Logo Minimalis',
    'Web Developer',
    'Mobile App',
    'Desain Grafis',
    'Social Media',
    '3D Modeling',
    'PCB Design',
    'Arduino'
  ];

  // Real data will be loaded from API via ServicesProvider
  final List<Service> _allResults = [];
  final List<Service> _searchResults = [];
  bool _isSearching = false;
  List<Service> _filteredResults = [];

  void _performSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredResults.clear();
      } else {
        _filteredResults = _allResults.where((service) {
          final q = query.toLowerCase();
          return service.title.toLowerCase().contains(q) ||
              (service.category?.toLowerCase().contains(q) ?? false) ||
              service.seller.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }
    _performSearch(query);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _filteredResults.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    // fetch services once when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sp = Provider.of<ServicesProvider>(context, listen: false);
      if (sp.services.isEmpty) {
        try {
          await sp.fetchServices();
        } catch (_) {}
      }
      if (sp.services.isNotEmpty && _allResults.isEmpty) {
        try {
          setState(() {
            _allResults.addAll(sp.services.map((e) => Service.fromJson(e as Map<String, dynamic>)));
          });
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure provider data is available; when provider is loading the UI will show placeholder
    final sp = Provider.of<ServicesProvider>(context);
    // Map provider services (List<dynamic>) to Service instances if our local cache is empty
    if (_allResults.isEmpty && sp.services.isNotEmpty) {
      try {
        _allResults.addAll(sp.services.map((e) => Service.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: _performSearch,
            onSubmitted: _onSearchSubmitted,
          ),
        ),
        actions: [
          if (_isSearching)
            TextButton(
              onPressed: _clearSearch,
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildSearchSuggestions(),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _onSearchSubmitted(search);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          search,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
          ],

          // Popular Searches
          Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _onSearchSubmitted(search);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        search,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Categories
          SizedBox(height: 32),
          Text(
            'Browse Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
            children: [
              _buildCategoryItem('Website', Icons.language, Colors.blue),
              _buildCategoryItem('UI/UX', Icons.design_services, Colors.purple),
              _buildCategoryItem('3D Print', Icons.print, Colors.orange),
              _buildCategoryItem('Logo', Icons.brush, Colors.green),
              _buildCategoryItem('Video', Icons.videocam, Colors.red),
              _buildCategoryItem('PCB', Icons.memory, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              'No services found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(_filteredResults[index]);
      },
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getCategoryColor(service.category ?? 'Default'),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(service.category ?? 'Default'),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: 12),
              
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    if (service.category != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(service.category!).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          service.category!,
                          style: TextStyle(
                            color: _getCategoryColor(service.category!),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(height: 8),
                    
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
                            Icon(Icons.star, color: Colors.amber, size: 16),
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

  Widget _buildCategoryItem(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        _searchController.text = title;
        _onSearchSubmitted(title);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'website':
        return Colors.blue;
      case 'ui/ux':
        return Colors.purple;
      case '3d print':
        return Colors.orange;
      case 'logo':
        return Colors.green;
      case 'video':
        return Colors.red;
      case 'pcb':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'website':
        return Icons.language;
      case 'ui/ux':
        return Icons.design_services;
      case '3d print':
        return Icons.print;
      case 'logo':
        return Icons.brush;
      case 'video':
        return Icons.videocam;
      case 'pcb':
        return Icons.memory;
      default:
        return Icons.category;
    }
  }
}

// Uses shared Service model from lib/models/service.dart
// Note: Service model does not include category field yet
// If category is needed, update the shared Service model in lib/models/service.dart