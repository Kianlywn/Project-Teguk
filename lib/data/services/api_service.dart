import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> _withRetry(Future<http.Response> Function() request) async {
    int attempts = 0;
    // Retry 1: 0s, Retry 2: 1s, Retry 3: 3s
    final delays = [0, 1, 3]; 

    while (true) {
      try {
        // Wrap request in a timeout to force TimeoutException if backend hangs
        return await request().timeout(const Duration(seconds: 10));
      } catch (e) {
        if (e is SocketException || e is TimeoutException) {
          if (attempts < delays.length) {
            await Future.delayed(Duration(seconds: delays[attempts]));
            attempts++;
            continue;
          }
        }
        // Rethrow if it's not a network error or we ran out of retries
        rethrow;
      }
    }
  }

  static Future<http.Response> get(String url) async {
    return _withRetry(() async => http.get(Uri.parse(url), headers: await _headers()));
  }

  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    return _withRetry(() async => http.post(
      Uri.parse(url),
      headers: await _headers(withAuth: withAuth),
      body: body != null ? jsonEncode(body) : null,
    ));
  }

  static Future<http.Response> put(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    return _withRetry(() async => http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    ));
  }

  static Future<http.Response> delete(String url) async {
    return _withRetry(() async => http.delete(Uri.parse(url), headers: await _headers()));
  }
}
