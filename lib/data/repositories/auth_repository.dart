import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/core/constants/api_constants.dart';

class AuthRepository {
  // Simpan token & data user ke local storage
  Future<void> _saveSession(String token, String role, String email, String fullname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setString('email', email);
    await prefs.setString('fullname', fullname);
  }

  // Ambil token (untuk cek apakah sudah login)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Ambil role user yang sedang login
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<String?> getFullname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fullname');
  }

  /// false = perlu ProfileSetupScreen (setelah register User)
  Future<bool> isProfileSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('profile_setup_complete') ?? true;
  }

  Future<void> setProfileSetupComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_setup_complete', value);
  }

  // Logout — hapus semua session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      await _saveSession(
        data['token'],
        data['role'],
        data['email'],
        data['fullname'],
      );
      return {'success': true, 'role': data['role'], 'fullname': data['fullname']};
    }

    return {'success': false, 'message': data.toString()};
  }

  // Register User
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required int age,
    required double weight,
    required String gender,
    required String activityLevel,
    required String environmentCondition,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'age': age,
        'weight': weight,
        'gender': gender,
        'activityLevel': activityLevel,
        'environmentCondition': environmentCondition,
        'role': 'User',
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data == 'Register Success') {
      return {'success': true};
    }

    return {'success': false, 'message': data.toString()};
  }

  // Register Health Expert
  Future<Map<String, dynamic>> registerExpert({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'age': 0,
        'weight': 0,
        'gender': '',
        'activityLevel': '',
        'environmentCondition': '',
        'role': 'HealthExpert',
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data == 'Register Success') {
      return {'success': true};
    }

    return {'success': false, 'message': data.toString()};
  }
}