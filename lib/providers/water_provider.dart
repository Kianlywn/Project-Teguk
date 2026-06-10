import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/data/repositories/water_repository.dart';
import 'package:teguk/data/services/location_service.dart';
import 'dart:async';

class WaterProvider extends ChangeNotifier {
  final _repository = WaterRepository();

  static const _keyTotal = 'water_local_total';
  static const _keyTarget = 'water_local_target';
  static const _keyDate = 'water_local_date';
  static const _keyManualAdj = 'water_local_manual_adj';

  int _totalDrink = 0;
  int _target = 2000;
  int _manualAdjustment = 0;
  double _percentage = 0.0;
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  List<dynamic> _history = [];

  bool _showMountainBanner = false;
  bool get showMountainBanner => _showMountainBanner;
  
  StreamSubscription? _locationSubscription;

  int get totalDrink => _totalDrink;
  int get target => _target + _manualAdjustment;
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
    await prefs.setInt(_keyManualAdj, _manualAdjustment);
  }

  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDate);
    
    if (savedDate != _todayKey()) {
      _manualAdjustment = 0;
      await prefs.setInt(_keyManualAdj, 0);
      return;
    }

    _totalDrink = prefs.getInt(_keyTotal) ?? 0;
    _target = prefs.getInt(_keyTarget) ?? _target;
    _manualAdjustment = prefs.getInt(_keyManualAdj) ?? 0;
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

    _locationSubscription = LocationService.getPositionStream().listen(
      (position) {
        if (position.altitude > 1500 && !_showMountainBanner && _manualAdjustment < 1000) {
          _showMountainBanner = true;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  void ignoreMountainBanner() {
    _showMountainBanner = false;
    notifyListeners();
  }

  Future<void> addMountainAdjustment() async {
    _showMountainBanner = false;
    _manualAdjustment += 1000;
    _recalcPercentage();
    await _saveLocal();
    notifyListeners();
  }

  Future<void> addManualActivityAdjustment(int ml) async {
    _manualAdjustment += ml;
    _recalcPercentage();
    await _saveLocal();
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
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
