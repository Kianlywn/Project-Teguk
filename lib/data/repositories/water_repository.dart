import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/core/constants/api_constants.dart';

class WaterRepository {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get Today's Progress
  Future<Map<String, dynamic>?> getTodayProgress() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(ApiConstants.waterToday),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  // Add Water Intake
  Future<bool> addWater(int amountMl) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse(ApiConstants.water),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'amountMl': amountMl}),
    );

    return response.statusCode == 200;
  }

  // Get Water History
  Future<List<dynamic>?> getHistory() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(ApiConstants.waterHistory),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }
}
