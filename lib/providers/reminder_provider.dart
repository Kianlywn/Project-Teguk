import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/data/repositories/reminder_repository.dart';
import 'package:teguk/data/services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  final _repository = ReminderRepository();

  List<dynamic> _reminders = [];
  bool _isLoading = false;

  List<dynamic> get reminders => _reminders;
  bool get isLoading => _isLoading;

  Future<void> fetchReminders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _repository.getReminders();
      if (list != null) {
        _reminders = list;
        // Cache to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_reminders', jsonEncode(_reminders));
        
        // Reschedule local notifications
        await NotificationService().rescheduleAll(_reminders);
      }
    } catch (e) {
      debugPrint('Error fetching reminders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReminder(String time, int interval) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _repository.addReminder(time, interval);
      if (success) await fetchReminders();
      return success;
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReminder(String id) async {
    try {
      final success = await _repository.deleteReminder(id);
      if (success) {
        _reminders.removeWhere((r) => r['id'] == id);
        await NotificationService().cancelReminder(id);
        
        // Update cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_reminders', jsonEncode(_reminders));
      }
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      return false;
    }
  }
}
