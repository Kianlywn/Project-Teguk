import 'package:flutter/material.dart';
import 'package:teguk/data/services/pedometer_service.dart';

class ActivityProvider extends ChangeNotifier {
  Map<String, int> _history = {};
  bool _isLoading = false;
  int _currentSteps = 0;

  Map<String, int> get history => _history;
  bool get isLoading => _isLoading;
  int get currentSteps => _currentSteps;

  final PedometerService _pedometer = PedometerService();

  ActivityProvider() {
    _initPedometer();
    fetchHistory();
  }

  void _initPedometer() {
    _pedometer.startListening();
    _pedometer.stepStream.listen((steps) {
      _currentSteps = steps;
      notifyListeners();
    });
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _pedometer.getHistory();
    } catch (e) {
      debugPrint('Error fetching step history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
