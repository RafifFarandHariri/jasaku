// Dart example: simple API client using `http` package
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
    final url = Uri.parse('$baseUrl/api.php?resource=auth&action=register');
    final res = await http.post(url, headers: _headers(), body: jsonEncode({'nama': nama, 'email': email, 'password': password}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api.php?resource=auth&action=login');
    final res = await http.post(url, headers: _headers(), body: jsonEncode({'email': email, 'password': password}));
    final Map<String, dynamic> data = jsonDecode(res.body);
    if (data.containsKey('token')) token = data['token'];
    return data;
  }

  Future<List<dynamic>> getServices() async {
    final url = Uri.parse('$baseUrl/api.php?resource=services');
    final res = await http.get(url, headers: _headers(json: true));
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    final url = Uri.parse('$baseUrl/api.php?resource=orders');
    final res = await http.post(url, headers: _headers(), body: jsonEncode(order));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

// Usage:
// final client = ApiClient('http://10.0.2.2/jasaku_api/api');
// await client.login('you@example.com', 'password');
// final services = await client.getServices();
