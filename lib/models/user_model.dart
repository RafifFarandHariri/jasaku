class User {
  int? id;
  String nrp;
  String nama;
  String email;
  String? phone;
  String? profileImage;
  String role;
  bool isVerifiedProvider;
  DateTime? providerSince;
  String? providerDescription;

  User({
    this.id,
    required this.nrp,
    required this.nama,
    required this.email,
    this.phone,
    this.profileImage,
    this.role = 'customer',
    this.isVerifiedProvider = false,
    this.providerSince,
    this.providerDescription,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nrp: json['nrp'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profile_image'],
      role: json['role'] ?? 'customer',
      isVerifiedProvider: (() {
        final v = json['is_verified_provider'];
        if (v is bool) return v;
        if (v is int) return v != 0;
        if (v is String) {
          final s = v.toLowerCase();
          return s == '1' || s == 'true' || s == 'yes';
        }
        return false;
      })(),
      providerSince: json['provider_since'] != null 
          ? DateTime.parse(json['provider_since']) 
          : null,
      providerDescription: json['provider_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nrp': nrp,
      'nama': nama,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'role': role,
      'is_verified_provider': isVerifiedProvider,
      'provider_since': providerSince?.toIso8601String(),
      'provider_description': providerDescription,
    };
  }

  bool get isProvider => role == 'provider';

  @override
  String toString() {
    return 'User{id: $id, nama: $nama, email: $email, role: $role}';
  }
}