import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP client terpusat dengan header Authorization otomatis.
class ApiService {
  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<http.Response> get(String url) async {
    return http.get(Uri.parse(url), headers: await _headers());
  }

  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    return http.post(
      Uri.parse(url),
      headers: await _headers(withAuth: withAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
