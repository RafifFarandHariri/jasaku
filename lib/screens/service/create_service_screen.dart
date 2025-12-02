import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:jasaku_app/providers/services_provider.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({Key? key}) : super(key: key);

  @override
  _CreateServiceScreenState createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descriptionCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _customCategoryCtl = TextEditingController();
  final _customServiceTypeCtl = TextEditingController();
  String? _category;
  String? _serviceType;
  bool _isLoading = false;

  final List<String> _categories = [
    'Desain Grafis',
    'Pemrograman',
    'Elektronik / PCB',
    '3D Modeling',
    'Penulisan & Proofreading',
    'Konsultasi Akademik',
    'Lainnya',
  ];

  @override
  void dispose() {
    _titleCtl.dispose();
    _descriptionCtl.dispose();
    _priceCtl.dispose();
    _customCategoryCtl.dispose();
    _customServiceTypeCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final chosenCategory = (_category == 'Lainnya' ? _customCategoryCtl.text.trim() : (_category ?? _categories.first));
    final chosenServiceType = (_serviceType == 'Lainnya' ? _customServiceTypeCtl.text.trim() : (_serviceType ?? chosenCategory));

    final payload = {
      'title': _titleCtl.text.trim(),
      'seller': user?.nama ?? user?.id?.toString() ?? 'unknown',
      'description': _descriptionCtl.text.trim(),
      'price': int.tryParse(_priceCtl.text.trim()) ?? 0,
      'category': chosenCategory,
      'serviceType': chosenServiceType,
    };

    final res = await ApiService.post('services', payload);

    setState(() => _isLoading = false);

    if (res is Map && res.containsKey('id')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jasa berhasil dibuat (id: ${res['id']})'), backgroundColor: Colors.green),
      );
      // merge server response with our local payload to ensure UI fields exist
      try {
        final created = Map<String, dynamic>.from(res);
        // ensure common fields exist so Home UI shows correct info immediately
        created['title'] = (created['title'] ?? payload['title']) ?? 'Untitled';
        created['description'] = (created['description'] ?? payload['description']) ?? '';
        created['price'] = (created['price'] ?? payload['price']) ?? 0;
        created['category'] = (created['category'] ?? payload['category']) ?? '';
        created['serviceType'] = (created['serviceType'] ?? payload['serviceType']) ?? '';
        created['seller'] = (created['seller'] ?? payload['seller']) ?? '';
        // ensure numeric fields are numbers
        if (created['price'] is String) created['price'] = int.tryParse(created['price']) ?? 0;
        if (created['sold'] == null) created['sold'] = 0;
        if (created['rating'] == null) created['rating'] = 0.0;
        if (created['reviews'] == null) created['reviews'] = 0;

        final sp = Provider.of<ServicesProvider>(context, listen: false);
        sp.addService(created);
        Navigator.pop(context, created);
      } catch (e) {
        // fallback: return raw res
        try {
          final sp = Provider.of<ServicesProvider>(context, listen: false);
          sp.addService(Map<String, dynamic>.from(res));
        } catch (_) {}
        Navigator.pop(context, Map<String, dynamic>.from(res));
      }
    } else if (res is Map && res['success'] == false) {
      final msg = res['message'] ?? 'Gagal membuat jasa';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Respons tidak dikenali dari server'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buat Jasa Baru')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtl,
                decoration: InputDecoration(labelText: 'Judul Jasa', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Masukkan judul jasa' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtl,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'Deskripsi Jasa (opsional)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 10) return 'Deskripsi terlalu pendek (minimal 10 karakter)';
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _priceCtl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Harga (IDR)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Masukkan harga';
                  if (int.tryParse(v.trim()) == null) return 'Harga harus berupa angka';
                  return null;
                },
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                decoration: InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Pilih kategori';
                  if (v == 'Lainnya' && _customCategoryCtl.text.trim().isEmpty) return 'Masukkan kategori kustom';
                  return null;
                },
              ),
              if (_category == 'Lainnya') ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _customCategoryCtl,
                  decoration: InputDecoration(labelText: 'Masukkan kategori', border: OutlineInputBorder()),
                  validator: (v) {
                    if (_category == 'Lainnya') {
                      if (v == null || v.trim().isEmpty) return 'Masukkan kategori kustom';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _serviceType,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                decoration: InputDecoration(labelText: 'Service Type', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _serviceType = v),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Pilih service type';
                  if (v == 'Lainnya' && _customServiceTypeCtl.text.trim().isEmpty) return 'Masukkan service type kustom';
                  return null;
                },
              ),
              if (_serviceType == 'Lainnya') ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _customServiceTypeCtl,
                  decoration: InputDecoration(labelText: 'Masukkan service type', border: OutlineInputBorder()),
                  validator: (v) {
                    if (_serviceType == 'Lainnya') {
                      if (v == null || v.trim().isEmpty) return 'Masukkan service type kustom';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text('Buat Jasa'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
