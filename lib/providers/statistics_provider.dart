import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/statistic_repository.dart';

class StatisticsProvider extends ChangeNotifier {
  final _repository = StatisticsRepository();

  List<dynamic> _weekly = [];
  List<dynamic> _monthly = [];
  bool _isLoading = false;

  List<dynamic> get weekly => _weekly;
  List<dynamic> get monthly => _monthly;
  bool get isLoading => _isLoading;

  Future<void> fetchWeekly() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _repository.getWeekly();
      if (list != null) _weekly = list;
    } catch (e) {
      debugPrint('Error fetching weekly stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthly() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _repository.getMonthly();
      if (list != null) _monthly = list;
    } catch (e) {
      debugPrint('Error fetching monthly stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
