import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/data/repositories/water_repository.dart';
import 'package:teguk/data/services/accelerometer_service.dart';

class WaterProvider extends ChangeNotifier {
  final _repository = WaterRepository();
  final _accelerometerService = AccelerometerService();

  static const _keyTotal = 'water_local_total';
  static const _keyTarget = 'water_local_target';
  static const _keyDate = 'water_local_date';

  int _totalDrink = 0;
  int _target = 2000;
  int _activityAdjustment = 0;
  double _percentage = 0.0;
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  List<dynamic> _history = [];

  int get totalDrink => _totalDrink;
  int get target => _target + _activityAdjustment;
  double get percentage => _percentage;
  double get progress => (_percentage / 100).clamp(0.0, 1.0);
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  List<dynamic> get history => _history;

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _recalcPercentage() {
    int currentTarget = target;
    _percentage =
        currentTarget > 0 ? ((_totalDrink / currentTarget) * 100).clamp(0.0, 100.0) : 0;
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDate, _todayKey());
    await prefs.setInt(_keyTotal, _totalDrink);
    await prefs.setInt(_keyTarget, _target);
  }

  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyDate) != _todayKey()) return;

    _totalDrink = prefs.getInt(_keyTotal) ?? 0;
    _target = prefs.getInt(_keyTarget) ?? _target;
    _recalcPercentage();
    notifyListeners();
  }

  void setTarget(int target) {
    _target = target;
    _recalcPercentage();
    notifyListeners();
  }

  Future<void> initialize({int? fallbackTarget}) async {
    if (fallbackTarget != null) _target = fallbackTarget;
    await loadFromLocal();
    await fetchTodayProgress();

    _accelerometerService.startListening();
    _accelerometerService.activityStream.listen((activity) {
      final adjustment = AccelerometerService.getWaterAdjustment(activity);
      if (_activityAdjustment != adjustment) {
        _activityAdjustment = adjustment;
        _recalcPercentage();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _accelerometerService.dispose();
    super.dispose();
  }

  Future<void> fetchTodayProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      final progress = await _repository.getTodayProgress();
      if (progress != null) {
        _totalDrink = (progress['totalDrink'] as num).toInt();
        final apiTarget = (progress['target'] as num).toInt();
        if (apiTarget > 0) _target = apiTarget;
        _percentage = (progress['percentage'] as num).toDouble();
        await _saveLocal();
      }
    } catch (e) {
      debugPrint('Error fetching water progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addWater(int amountMl) async {
    final previousTotal = _totalDrink;

    _totalDrink += amountMl;
    _recalcPercentage();
    await _saveLocal();
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.addWater(amountMl);
      if (success) {
        await fetchTodayProgress();
        await fetchHistory();
        return true;
      }
      _totalDrink = previousTotal;
      _recalcPercentage();
      await _saveLocal();
      return false;
    } catch (e) {
      debugPrint('Error adding water: $e');
      _totalDrink = previousTotal;
      _recalcPercentage();
      await _saveLocal();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isHistoryLoading = true;
    notifyListeners();

    try {
      final list = await _repository.getHistory();
      if (list != null) _history = list;
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }
}
