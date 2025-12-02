import 'package:flutter/material.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/services_provider.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({Key? key}) : super(key: key);

  @override
  _CreateAdScreenState createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _customCategoryCtl = TextEditingController();
  String _category = 'Desain Grafis';
  bool _loading = false;
  List<Map<String, dynamic>> _packages = [];

  @override
  void dispose() {
    _titleCtl.dispose();
    _priceCtl.dispose();
    _descCtl.dispose();
    _customCategoryCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final title = _titleCtl.text.trim();
    final price = int.tryParse(_priceCtl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final desc = _descCtl.text.trim();

    final categoryValue = _category == 'Lainnya' ? _customCategoryCtl.text.trim() : _category;

    final payload = {
      'title': title,
      'seller': user?.nama ?? 'Unknown',
      'price': price,
      'description': desc,
      'category': categoryValue,
      'packages': _packages,
      // mark as verified so it appears immediately in public listings/slider
      'is_verified': 1,
      'has_fast_response': 1,
    };

    try {
      final res = await ApiService.post('services', payload);
      if (res is Map && (res['id'] != null || res['ok'] == true)) {
        // Merge server response with submitted payload to create a full service map
        final Map<String, dynamic> created = {};
        if (res is Map) created.addAll(Map<String, dynamic>.from(res));
        created.addAll(payload.cast<String, dynamic>());
        // ensure id exists
        if (created['id'] == null && res is Map && res['id'] != null) created['id'] = res['id'];
        // add to ServicesProvider so Home slider updates immediately
        try {
          final sp = Provider.of<ServicesProvider>(context, listen: false);
          sp.addService(created);
          // refresh from server to make sure we show the persisted record
          try { await sp.fetchServices(); } catch (_) {}
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Iklan berhasil dipasang'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        final msg = res is Map && res['message'] != null ? res['message'].toString() : 'Gagal memasang iklan';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddPackageDialog() async {
    final _pkgTitle = TextEditingController();
    final _pkgPrice = TextEditingController();
    final _pkgDelivery = TextEditingController();
    final _pkgRevisions = TextEditingController();
    final _pkgDesc = TextEditingController();

    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Paket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _pkgTitle, decoration: InputDecoration(labelText: 'Judul Paket')),
              TextField(controller: _pkgPrice, decoration: InputDecoration(labelText: 'Harga (Rp)'), keyboardType: TextInputType.number),
              TextField(controller: _pkgDelivery, decoration: InputDecoration(labelText: 'Waktu pengerjaan (hari)'), keyboardType: TextInputType.number),
              TextField(controller: _pkgRevisions, decoration: InputDecoration(labelText: 'Revisi (jumlah)'), keyboardType: TextInputType.number),
              TextField(controller: _pkgDesc, decoration: InputDecoration(labelText: 'Deskripsi paket'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Tambah')),
        ],
      ),
    );

    if (res == true) {
      final title = _pkgTitle.text.trim();
      if (title.isEmpty) return;
      final price = int.tryParse(_pkgPrice.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final delivery = int.tryParse(_pkgDelivery.text) ?? 0;
      final revisions = int.tryParse(_pkgRevisions.text) ?? 0;
      final desc = _pkgDesc.text.trim();

      setState(() {
        _packages.add({
          'title': title,
          'price': price,
          'delivery_days': delivery,
          'revisions': revisions,
          'description': desc,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pasang Iklan Jasaku')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtl,
                decoration: InputDecoration(labelText: 'Judul Iklan'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _priceCtl,
                decoration: InputDecoration(labelText: 'Harga (Rp)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Harga wajib diisi' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: [
                  'Desain Grafis',
                  'Web Development',
                  'Video & Motion',
                  'Lainnya'
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
                decoration: InputDecoration(labelText: 'Kategori'),
              ),
              if (_category == 'Lainnya') ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _customCategoryCtl,
                  decoration: InputDecoration(labelText: 'Kategori (isi sendiri)'),
                  validator: (v) => (_category == 'Lainnya' && (v == null || v.trim().isEmpty)) ? 'Kategori wajib diisi' : null,
                ),
              ],
              SizedBox(height: 12),
              TextFormField(
                controller: _descCtl,
                decoration: InputDecoration(labelText: 'Deskripsi'),
                maxLines: 5,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
              ),
              SizedBox(height: 20),

              // Packages section
              Text('Paket Pembelian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (_packages.isEmpty)
                Text('Belum ada paket. Tambah paket agar pembeli bisa memilih varian.', style: TextStyle(color: Colors.grey[600]))
              else
                Column(
                  children: _packages.asMap().entries.map((e) {
                    final idx = e.key;
                    final pkg = e.value;
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(pkg['title'] ?? ''),
                        subtitle: Text('Rp ${pkg['price'] ?? 0} • ${pkg['delivery_days'] ?? 0} hari • ${pkg['revisions'] ?? 0} revisi'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() { _packages.removeAt(idx); });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAddPackageDialog,
                    icon: Icon(Icons.add),
                    label: Text('Tambah Paket'),
                  ),
                  SizedBox(width: 12),
                  if (_packages.isNotEmpty)
                    Text('${_packages.length} paket', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? CircularProgressIndicator(color: Colors.white) : Text('Pasang Iklan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
