class Service {
  final int id;
  final String title;
  final String seller;
  final int price;
  final int sold;
  final double rating;
  final int reviews;
  final bool isVerified;
  final bool hasFastResponse;
  final String? category;
  final List<Map<String, dynamic>>? packages;

  const Service({
    required this.id,
    required this.title,
    required this.seller,
    required this.price,
    required this.sold,
    required this.rating,
    required this.reviews,
    this.isVerified = true,
    this.hasFastResponse = true,
    this.category,
    this.packages,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    // API returns fields as strings or numbers depending on source, be defensive
    int parseInt(dynamic v, [int def = 0]) {
      if (v == null) return def;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? def;
    }

    double parseDouble(dynamic v, [double def = 0.0]) {
      if (v == null) return def;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    return Service(
      id: parseInt(json['id'] ?? json['serviceId'] ?? json['service_id'], 0),
      title: json['title']?.toString() ?? json['serviceTitle']?.toString() ?? 'No title',
      seller: json['seller']?.toString() ?? json['sellerName']?.toString() ?? '',
      price: parseInt(json['price'] ?? 0, 0),
      sold: parseInt(json['sold'] ?? 0, 0),
      rating: parseDouble(json['rating'] ?? 0.0, 0.0),
      reviews: parseInt(json['reviews'] ?? 0, 0),
      isVerified: (json['is_verified'] != null) ? (json['is_verified'].toString() == '1' || json['is_verified'].toString().toLowerCase() == 'true') : true,
      hasFastResponse: (json['has_fast_response'] != null) ? (json['has_fast_response'].toString() == '1' || json['has_fast_response'].toString().toLowerCase() == 'true') : true,
      category: json['category']?.toString(),
      packages: (json['packages'] is List) ? List<Map<String,dynamic>>.from((json['packages'] as List).map((e) => Map<String,dynamic>.from(e as Map))) : null,
    );
  }
}
