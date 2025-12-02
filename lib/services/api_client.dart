// Simple API client using `http` package
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  String? token;

  ApiClient(this.baseUrl, {this.token});

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<Map<String, dynamic>> register(String nama, String email, String password) async {
    final apiPath = baseUrl.endsWith('api.php')
        ? baseUrl
        : (baseUrl.endsWith('/') ? '${baseUrl}api.php' : '$baseUrl/api.php');
    final url = Uri.parse('$apiPath?resource=auth&action=register');
    try {
      final res = await http
          .post(url, headers: _headers(), body: jsonEncode({'nama': nama, 'email': email, 'password': password}))
          .timeout(const Duration(seconds: 30));
      // debug
      print('POST $url -> ${res.statusCode}');
      print('Response body: ${res.body}');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      print('Register request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final apiPath = baseUrl.endsWith('api.php')
        ? baseUrl
        : (baseUrl.endsWith('/') ? '${baseUrl}api.php' : '$baseUrl/api.php');
    final url = Uri.parse('$apiPath?resource=auth&action=login');
    try {
      final res = await http
          .post(url, headers: _headers(), body: jsonEncode({'email': email, 'password': password}))
          .timeout(const Duration(seconds: 30));
      print('POST $url -> ${res.statusCode}');
      print('Response body: ${res.body}');
      final Map<String, dynamic> data = jsonDecode(res.body);
    if (data.containsKey('token')) token = data['token'];
    return data;
    } catch (e) {
      print('Login request failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getServices() async {
    final apiPath = baseUrl.endsWith('api.php')
        ? baseUrl
        : (baseUrl.endsWith('/') ? '${baseUrl}api.php' : '$baseUrl/api.php');
    final url = Uri.parse('$apiPath?resource=services');
    try {
      final res = await http.get(url, headers: _headers(json: true)).timeout(const Duration(seconds: 30));
      print('GET $url -> ${res.statusCode}');
      print('Response body: ${res.body}');
      return jsonDecode(res.body) as List<dynamic>;
    } catch (e) {
      print('GetServices failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    final apiPath = baseUrl.endsWith('api.php')
        ? baseUrl
        : (baseUrl.endsWith('/') ? '${baseUrl}api.php' : '$baseUrl/api.php');
    final url = Uri.parse('$apiPath?resource=orders');
    try {
      final res = await http.post(url, headers: _headers(), body: jsonEncode(order)).timeout(const Duration(seconds: 30));
      print('POST $url -> ${res.statusCode}');
      print('Response body: ${res.body}');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      print('CreateOrder failed: $e');
      rethrow;
    }
  }
}
