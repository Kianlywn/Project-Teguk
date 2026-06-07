import 'dart:convert';
import 'package:teguk/core/constants/api_constants.dart';
import 'package:teguk/data/services/api_service.dart';

class UserRepository {
  Future<Map<String, dynamic>?> getProfile() async {
    final response = await ApiService.get(ApiConstants.userProfile);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> updateProfile({
    required String fullName,
    required int age,
    required double weight,
    required String gender,
    required String activityLevel,
    required String environmentCondition,
  }) async {
    final response = await ApiService.put(
      ApiConstants.userProfile,
      body: {
        'fullName': fullName,
        'age': age,
        'weight': weight,
        'gender': gender,
        'activityLevel': activityLevel,
        'environmentCondition': environmentCondition,
      },
    );
    return response.statusCode == 200;
  }
}
