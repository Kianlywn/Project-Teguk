import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/activity_repository.dart';
import 'package:teguk/data/services/pedometer_service.dart';

class ActivityProvider extends ChangeNotifier {
  final _repository = ActivityRepository();

  List<dynamic> _activities = [];
  bool _isLoading = false;
  int _currentSteps = 0;

  List<dynamic> get activities => _activities;
  bool get isLoading => _isLoading;
  int get currentSteps => _currentSteps;

  ActivityProvider() {
    _initPedometer();
  }

  void _initPedometer() {
    final pedometer = PedometerService();
    pedometer.startListening();
    pedometer.stepStream.listen((steps) {
      _currentSteps = steps;
      notifyListeners();
    });
  }

  Future<void> fetchActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _repository.getActivities();
      if (list != null) _activities = list;
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addActivity(String type, String level) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.addActivity(type, level);
      if (success) await fetchActivities();
      return success;
    } catch (e) {
      debugPrint('Error adding activity: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
