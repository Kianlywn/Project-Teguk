import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/water_repository.dart';

class WaterProvider extends ChangeNotifier {
  final _repository = WaterRepository();

  int _totalDrink = 0;
  int _target = 2000;
  double _percentage = 0.0;
  bool _isLoading = false;
  List<dynamic> _history = [];

  int get totalDrink => _totalDrink;
  int get target => _target;
  double get percentage => _percentage;
  bool get isLoading => _isLoading;
  List<dynamic> get history => _history;

  // Fetch today's progress from API
  Future<void> fetchTodayProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      final progress = await _repository.getTodayProgress();
      if (progress != null) {
        _totalDrink = (progress['totalDrink'] as num).toInt();
        _target = (progress['target'] as num).toInt();
        _percentage = (progress['percentage'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Error fetching water progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add water intake
  Future<bool> addWater(int amountMl) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.addWater(amountMl);
      if (success) {
        await fetchTodayProgress(); // Refresh progress
        await fetchHistory();       // Refresh history
        return true;
      }
    } catch (e) {
      debugPrint('Error adding water: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Fetch intake history
  Future<void> fetchHistory() async {
    try {
      final list = await _repository.getHistory();
      if (list != null) {
        _history = list;
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      notifyListeners();
    }
  }
}
