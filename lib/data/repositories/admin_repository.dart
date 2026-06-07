import 'dart:convert';
import 'package:teguk/core/constants/api_constants.dart';
import 'package:teguk/data/services/api_service.dart';

class AdminRepository {
  Future<Map<String, dynamic>?> getDashboard() async {
    final response = await ApiService.get(ApiConstants.adminDashboard);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<dynamic>?> getPendingExperts() async {
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
