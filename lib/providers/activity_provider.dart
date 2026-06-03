import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/core/constants/api_constants.dart';

class ActivityProvider extends ChangeNotifier {
  List<dynamic> _activities = [];
  bool _isLoading = false;

  List<dynamic> get activities => _activities;
  bool get isLoading => _isLoading;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Fetch activities
  Future<void> fetchActivities() async {
    final token = await _getToken();
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.activity),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _activities = jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add activity
  Future<bool> addActivity(String type, String level) async {
    final token = await _getToken();
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.activity),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'activityType': type,
          'activityLevel': level,
        }),
      );

      if (response.statusCode == 200) {
        await fetchActivities(); // Refresh activities
        return true;
      }
    } catch (e) {
      debugPrint('Error adding activity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
