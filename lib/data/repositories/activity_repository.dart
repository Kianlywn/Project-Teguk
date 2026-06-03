import 'dart:convert';

import 'package:teguk/core/constants/api_constants.dart';
import 'package:teguk/data/services/api_service.dart';

class ActivityRepository {
  Future<List<dynamic>?> getActivities() async {
    final response = await ApiService.get(ApiConstants.activity);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  Future<bool> addActivity(String type, String level) async {
    final response = await ApiService.post(
      ApiConstants.activity,
      body: {
        'activityType': type,
        'activityLevel': level,
      },
    );

    return response.statusCode == 200;
  }
}
