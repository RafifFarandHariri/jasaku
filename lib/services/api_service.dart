import 'dart:async';
// Removed duplicate import
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jasaku_app/services/auth_service.dart';

/// Centralized API helper with simple `get`, `post`, and `put` helpers.
class ApiService {
  static const String emulatorRouter = 'http://10.0.2.2/jasaku_api/api/api.php';
  static const String physicalRouter = 'http://localhost/jasaku_api/api/api.php';

  static String? _cachedRouter;

  static Future<String> _getRouter() async {
    if (_cachedRouter != null) return _cachedRouter!;
    try {
      if (Platform.isAndroid) {
        _cachedRouter = emulatorRouter;
      } else {
        _cachedRouter = physicalRouter;
      }
    } catch (_) {
      _cachedRouter = physicalRouter;
    }
    return _cachedRouter!;
  }

  static Future<Map<String, String>> _headers() async {
    final h = <String, String>{'Content-Type': 'application/json'};
    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    } catch (_) {}
    return h;
  }

  static Future<dynamic> _runRequest(Future<http.Response> Function() request) async {
    const int maxAttempts = 3;
    const Duration timeout = Duration(seconds: 10);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await request().timeout(timeout);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return {'success': false, 'status': response.statusCode, 'body': response.body};
        }

        final contentType = (response.headers['content-type'] ?? '').toLowerCase();
        if (!contentType.contains('application/json')) {
          try {
            return jsonDecode(response.body);
          } on FormatException {
            return {'success': false, 'message': 'Invalid JSON', 'body': response.body};
          }
        }

        return jsonDecode(response.body);
      } on TimeoutException catch (e) {
        if (attempt == maxAttempts) return {'success': false, 'message': 'Timeout: $e'};
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      } on SocketException catch (e) {
        if (attempt == maxAttempts) return {'success': false, 'message': 'Network error: $e'};
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      } catch (e) {
        return {'success': false, 'message': 'Error: $e'};
      }
    }

    return {'success': false, 'message': 'Failed to connect'};
  }

  static Future<dynamic> get(String endpoint) async {
    final router = await _getRouter();
    Uri uri;
    final ep = endpoint.trim();
    if (ep.startsWith('http')) {
      uri = Uri.parse(ep);
    } else if (ep.contains('api.php') || ep.contains('resource=')) {
      uri = Uri.parse(ep);
    } else {
      uri = Uri.parse('$router?resource=${Uri.encodeComponent(ep)}');
    }
    final h = await _headers();
    return _runRequest(() => http.get(uri, headers: h));
  }

  static Future<dynamic> post(String endpoint, dynamic body) async {
    final router = await _getRouter();
    Uri uri;
    final ep = endpoint.trim();
    if (ep.startsWith('http')) {
      uri = Uri.parse(ep);
    } else if (ep.contains('api.php') || ep.contains('resource=')) {
      uri = Uri.parse(ep);
    } else {
      uri = Uri.parse('$router?resource=${Uri.encodeComponent(ep)}');
    }
    final h = await _headers();
    return _runRequest(() => http.post(uri, headers: h, body: jsonEncode(body)));
  }

  static Future<dynamic> put(String endpoint, dynamic body) async {
    final router = await _getRouter();
    Uri uri;
    final ep = endpoint.trim();
    if (ep.startsWith('http')) {
      uri = Uri.parse(ep);
    } else if (ep.contains('api.php') || ep.contains('resource=')) {
      uri = Uri.parse(ep);
    } else {
      uri = Uri.parse('$router?resource=${Uri.encodeComponent(ep)}');
    }
    final h = await _headers();
    return _runRequest(() => http.put(uri, headers: h, body: jsonEncode(body)));
  }
}