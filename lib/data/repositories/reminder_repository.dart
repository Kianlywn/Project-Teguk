import 'dart:convert';
import 'package:teguk/core/constants/api_constants.dart';
import 'package:teguk/data/services/api_service.dart';

class ReminderRepository {
  Future<List<dynamic>?> getReminders() async {
    final response = await ApiService.get(ApiConstants.reminder);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  Future<bool> addReminder(String reminderTime, int intervalMinutes) async {
    final response = await ApiService.post(
      ApiConstants.reminder,
      body: {
        'reminderTime': reminderTime,
        'intervalMinutes': intervalMinutes,
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteReminder(String id) async {
    final response = await ApiService.delete('${ApiConstants.reminder}/$id');
    return response.statusCode == 200;
  }
}
