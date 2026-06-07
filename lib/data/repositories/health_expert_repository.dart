import 'dart:convert';
import 'package:teguk/core/constants/api_constants.dart';
import 'package:teguk/data/services/api_service.dart';

class HealthExpertRepository {
  Future<List<dynamic>?> getExpertList() async {
    final response = await ApiService.get(ApiConstants.healthExpertList);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  Future<bool> applyAsExpert({
    required String profession,
    required String specialization,
    required String licenseNumber,
    required int experienceYears,
  }) async {
    final response = await ApiService.post(
      ApiConstants.healthExpertApply,
      body: {
        'profession': profession,
        'specialization': specialization,
        'licenseNumber': licenseNumber,
        'experienceYears': experienceYears,
      },
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getMyApplication() async {
    final response = await ApiService.get(ApiConstants.healthExpertMyApplication);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body == null) return null;
      return body as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<dynamic>?> getPendingApplications() async {
    final response = await ApiService.get(ApiConstants.healthExpertPending);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  Future<bool> approveExpert(String id) async {
    final response = await ApiService.put(ApiConstants.healthExpertApprove(id));
    return response.statusCode == 200;
  }

  Future<bool> rejectExpert(String id) async {
    final response = await ApiService.put(ApiConstants.healthExpertReject(id));
    return response.statusCode == 200;
  }
}
