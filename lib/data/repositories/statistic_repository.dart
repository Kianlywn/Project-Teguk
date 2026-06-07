import 'dart:convert';
import 'package:teguk/core/constants/api_constants.dart';
import 'package:teguk/data/services/api_service.dart';

class StatisticsRepository {
  Future<List<dynamic>?> getWeekly() async {
    final response = await ApiService.get(ApiConstants.statsWeekly);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  Future<List<dynamic>?> getMonthly() async {
    final response = await ApiService.get(ApiConstants.statsMonthly);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }
}
