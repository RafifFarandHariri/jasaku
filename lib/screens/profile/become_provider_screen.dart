import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/models/user_model.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:jasaku_app/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:jasaku_app/services/auth_service.dart';
import 'dart:io';
import 'dart:convert';

class BecomeProviderScreen extends StatefulWidget {
  final User user;
  
  const BecomeProviderScreen({Key? key, required this.user}) : super(key: key);

  @override
  _BecomeProviderScreenState createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends State<BecomeProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  // service type and optional portfolios
  final List<String> _serviceTypes = [
    'Desain Grafis',
    'Pemrograman',
    'Elektronik / PCB',
    '3D Modeling',
    'Penulisan & Proofreading',
    'Konsultasi Akademik',
    'Lainnya',
  ];
  String? _selectedServiceType;

  // portfolio entries
  final List<_PortfolioEntry> _portfolios = [];

  // helper: upload a picked file and return public URL or null
  Future<String?> _uploadFile(_PortfolioEntry p) async {
    try {
      if (p.file == null || p.file!.path == null) return null;

      final uploadUrl = Platform.isAndroid
          ? 'http://10.0.2.2/jasaku_api/api/api.php?resource=uploads'
          : 'http://localhost/jasaku_api/api/api.php?resource=uploads';

      final uri = Uri.parse(uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      // attach file
      final path = p.file!.path!;
      request.files.add(await http.MultipartFile.fromPath('file', path));

      // add auth header if available
      try {
        final token = await AuthService.getToken();
        if (token != null && token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
      } catch (_) {}

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
      final body = resp.body;
      try {
        final decoded = body.isNotEmpty ? (await Future(() => jsonDecode(body))) : null;
        if (decoded is Map && decoded['url'] != null) return decoded['url'].toString();
      } catch (_) {
        return null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Send application to server
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        // build payload including serviceType and portfolios
        final payload = {
          'user_id': user?.id ?? 0,
          'description': _descriptionController.text.trim(),
          'serviceType': _selectedServiceType,
          'portfolios': _portfolios.map((p) => p.toJson()).where((m) => m['title']!.isNotEmpty).toList(),
        };

        // Upload files for portfolio entries (if any) and set imageUrl fields
        for (var p in _portfolios) {
          if (p.file != null && (p.imageUrl.text.isEmpty || p.imageUrl.text == p.file!.name)) {
            final url = await _uploadFile(p);
            if (url != null) p.imageUrl.text = url;
          }
        }

        final res = await ApiService.post('api/user/become_provider.php', payload);

        if (res is Map && res['success'] == true) {
          // Update local user state: set role and providerDescription
          final updatedUser = User(
            id: user?.id,
            nrp: user?.nrp ?? '',
            nama: user?.nama ?? '',
            email: user?.email ?? '',
            phone: user?.phone,
            profileImage: user?.profileImage,
            role: 'provider',
            isVerifiedProvider: false,
            providerSince: DateTime.now(),
            providerDescription: _descriptionController.text.trim(),
          );

          await authProvider.updateUser(updatedUser);

          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Permohonan menjadi penyedia dikirim.'), backgroundColor: Colors.green),
          );

          Navigator.pop(context, true); // Return true to indicate success

          // After application success, create portfolio records on server
          try {
            for (var p in _portfolios) {
              final data = p.toJson();
              if ((data['title'] ?? '').isEmpty) continue;
              // create portfolio record via API (use full router URL so ApiService treats it as raw)
              final base = Platform.isAndroid
                  ? 'http://10.0.2.2/jasaku_api/api/api.php?resource=portfolios'
                  : 'http://localhost/jasaku_api/api/api.php?resource=portfolios';
              await ApiService.post(base, {
                'serviceId': null,
                'sellerId': user?.id,
                'title': data['title'],
                'description': data['description'],
                'imageUrl': data['imageUrl'],
              });
            }
          } catch (_) {}
        } else {
          final message = (res is Map && res['message'] != null) ? res['message'].toString() : 'Gagal mengajukan permohonan';
          throw Exception(message);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menjadi penyedia jasa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mulai Menjual Jasa'),
        backgroundColor: Colors.blue,
      ),
      body: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.work_outline, size: 64, color: Colors.blue),
                          SizedBox(height: 16),
                          Text(
                            'Jadi Penyedia Jasa',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tawarkan keahlian Anda dan mulai dapatkan penghasilan dari kampus',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Form description
                  Text(
                    'Deskripsi Jasa Anda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Ceritakan tentang keahlian Anda...\nContoh: "Saya ahli dalam desain PCB, 3D modeling, dan programming. Sudah berpengalaman membuat berbagai project elektronik."',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Silakan isi deskripsi jasa Anda';
                      }
                      if (value.length < 20) {
                        return 'Deskripsi minimal 20 karakter';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Service Type selector
                  Text(
                    'Jenis Jasa (Service Type)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedServiceType,
                    decoration: InputDecoration(border: OutlineInputBorder()),
                    items: _serviceTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedServiceType = v),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Silakan pilih jenis jasa';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Portfolio entries (optional)
                  Text(
                    'Portofolio (Opsional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Column(
                    children: [
                      for (var i = 0; i < _portfolios.length; i++) _buildPortfolioCard(i),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _portfolios.add(_PortfolioEntry());
                            });
                          },
                          icon: Icon(Icons.add),
                          label: Text('Tambah Portofolio'),
                        ),
                      ),
                    ],
                  ),
                  // Benefits list
                  Text(
                    'Keuntungan menjadi penyedia jasa:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildBenefitItem('Dapat penghasilan tambahan'),
                  _buildBenefitItem('Bangun portofolio dan reputasi'),
                  _buildBenefitItem('Jaringan dengan mahasiswa lain'),
                  _buildBenefitItem('Pengalaman kerja nyata'),
                  _buildBenefitItem('Mendapatkan bonus dan diskon khusus'),
                  SizedBox(height: 24),
                  
                  // Submit button
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitApplication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              'MULAI JUAL SEKARANG',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(int index) {
    final p = _portfolios[index];
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Portofolio #${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      p.dispose();
                      _portfolios.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: p.title,
              decoration: InputDecoration(labelText: 'Judul Portofolio', border: OutlineInputBorder()),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: p.description,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: p.imageUrl,
                    decoration: InputDecoration(labelText: 'Image URL (opsional)', border: OutlineInputBorder()),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    // pick file
                    final result = await FilePicker.platform.pickFiles(withData: false);
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      setState(() {
                        p.file = file;
                        p.imageUrl.text = file.name; // temporary display
                      });
                    }
                  },
                  icon: Icon(Icons.attach_file),
                  label: Text('Pilih File'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (var p in _portfolios) {
      p.dispose();
    }
    super.dispose();
  }
}

class _PortfolioEntry {
  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController imageUrl = TextEditingController();
  PlatformFile? file;

  void dispose() {
    title.dispose();
    description.dispose();
    imageUrl.dispose();
  }

  Map<String, String?> toJson() {
    return {
      'title': title.text.trim(),
      'description': description.text.trim(),
      'imageUrl': imageUrl.text.trim(),
    };
  }
}