import 'dart:io';
import 'package:jasaku_app/services/api_service.dart';

class GoodHealthAdapter {
  // Return router base depending on platform (emulator vs desktop)
  static String routerBase() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2/jasaku_api/api/api.php';
    }
    // desktop / other
    return 'http://localhost/jasaku_api/api/api.php';
  }

  // Auth: login
  static Future<dynamic> login(String username, String password, {String? idPasien}) async {
    final base = routerBase();
    final uri = '$base?resource=auth&action=login';
    final payload = {
      'username': username,
      'password': password,
      if (idPasien != null) 'idPasien': idPasien,
    };
    return await ApiService.post(uri, payload);
  }

  // Auth: register (if needed) - maps to users create
  static Future<dynamic> registerPasien(String nama, String hp, String email) async {
    final base = routerBase();
    final uri = '$base?resource=users&action=create_pasien';
    final payload = {'nama': nama, 'hp': hp, 'email': email};
    return await ApiService.post(uri, payload);
  }

  // Orders / pesan_obat
  static Future<dynamic> fetchPesanObats({required String idPasien, String? isSelesai}) async {
    final base = routerBase();
    final q = '&id_pasien=${Uri.encodeComponent(idPasien)}' + (isSelesai != null ? '&is_selesai=${Uri.encodeComponent(isSelesai)}' : '');
    final uri = '$base?resource=orders&action=list$q';
    return await ApiService.get(uri);
  }

  static Future<dynamic> createPesanObat(Map<String, dynamic> body) async {
    final base = routerBase();
    final uri = '$base?resource=orders&action=create';
    return await ApiService.post(uri, body);
  }

  static Future<dynamic> deletePesanObat(String id) async {
    final base = routerBase();
    final uri = '$base?resource=orders&action=delete&id=${Uri.encodeComponent(id)}';
    return await ApiService.get(uri);
  }

  static Future<dynamic> updatePesanObat(String id, Map<String, dynamic> body) async {
    final base = routerBase();
    final uri = '$base?resource=orders&action=update&id=${Uri.encodeComponent(id)}';
    // use POST with body
    return await ApiService.post(uri, body);
  }

  // Registrations (regis_poli)
  static Future<dynamic> fetchRegisPolis(String idPasien) async {
    final base = routerBase();
    final uri = '$base?resource=registrations&action=list&pasien_id=${Uri.encodeComponent(idPasien)}';
    return await ApiService.get(uri);
  }

  static Future<dynamic> createRegisPoli(Map<String, dynamic> body) async {
    final base = routerBase();
    final uri = '$base?resource=registrations&action=create';
    return await ApiService.post(uri, body);
  }

  static Future<dynamic> deleteRegisPoli(String id) async {
    final base = routerBase();
    final uri = '$base?resource=registrations&action=delete&id=${Uri.encodeComponent(id)}';
    return await ApiService.get(uri);
  }

  // Simple list endpoints
  static Future<dynamic> fetchObat() async {
    final base = routerBase();
    final uri = '$base?resource=services&action=list_obat';
    return await ApiService.get(uri);
  }

  static Future<dynamic> fetchDokter() async {
    final base = routerBase();
    final uri = '$base?resource=services&action=list_dokter';
    return await ApiService.get(uri);
  }
}
