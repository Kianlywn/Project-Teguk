import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  StreamSubscription<StepCount>? _stepCountStream;
  int _todaySteps = 0;
  int _baselineSteps = 0;
  String _currentDate = '';
  DateTime? _lastStepTime;
  int _lastRawSteps = 0;

  // Stream controller to broadcast today's steps
  final _stepController = StreamController<int>.broadcast();
  Stream<int> get stepStream => _stepController.stream;
  int get todaySteps => _todaySteps;

  String _getTodayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status == PermissionStatus.granted;
  }

  Future<void> startListening() async {
    if (!await Permission.activityRecognition.isGranted) {
      debugPrint('Activity recognition permission not granted. Pedometer will not start.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _currentDate = _getTodayDateStr();

    // Check if we have a baseline for today
    final savedDate = prefs.getString('step_baseline_date');
    if (savedDate == _currentDate) {
      _baselineSteps = prefs.getInt('step_baseline_value') ?? 0;
      // Restore saved today steps so count persists across app restarts
      _todaySteps = prefs.getInt('step_today_value') ?? 0;
      _stepController.add(_todaySteps);
    } else {
      // It's a new day — save yesterday's steps to history before resetting
      if (savedDate != null) {
        final yesterdaySteps = prefs.getInt('step_today_value') ?? 0;
        if (yesterdaySteps > 0) {
          final historyStr = prefs.getString('step_history') ?? '{}';
          final Map<String, dynamic> historyMap = jsonDecode(historyStr);
          historyMap[savedDate] = yesterdaySteps;
          await prefs.setString('step_history', jsonEncode(historyMap));
        }
      }
      // Reset for today — baseline will be set on the first pedometer event
      _baselineSteps = -1;
      _todaySteps = 0;
      await prefs.setInt('step_today_value', 0);
      _stepController.add(_todaySteps);
    }

    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
  }

  Future<void> _onStepCount(StepCount event) async {
    final rawSteps = event.steps;
    final now = DateTime.now();

    // --- Anti-jitter filter ---
    // If steps jump too fast (> 5 steps per second), it's likely sensor noise.
    // Walking is typically 1-3 steps/sec, running ~3-5 steps/sec.
    if (_lastStepTime != null && _lastRawSteps > 0) {
      final elapsed = now.difference(_lastStepTime!).inMilliseconds;
      final stepDelta = rawSteps - _lastRawSteps;
      if (elapsed > 0 && stepDelta > 0) {
        final stepsPerSecond = (stepDelta * 1000) / elapsed;
        if (stepsPerSecond > 5) {
          // Too fast, likely noise — skip this event
          debugPrint('Pedometer: skipping noisy event ($stepsPerSecond steps/s)');
          return;
        }
      }
    }
    _lastStepTime = now;
    _lastRawSteps = rawSteps;

    // Check for new day while running
    final todayStr = _getTodayDateStr();
    if (_currentDate != todayStr) {
      // Save yesterday's steps to history
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('step_history') ?? '{}';
      final Map<String, dynamic> historyMap = jsonDecode(historyStr);
      historyMap[_currentDate] = _todaySteps;
      await prefs.setString('step_history', jsonEncode(historyMap));

      _currentDate = todayStr;
      _baselineSteps = rawSteps;
      await prefs.setString('step_baseline_date', _currentDate);
      await prefs.setInt('step_baseline_value', _baselineSteps);
      _todaySteps = 0;
      await prefs.setInt('step_today_value', 0);
      _stepController.add(_todaySteps);
      return;
    }

    if (_baselineSteps == -1) {
      // First event of the day
      _baselineSteps = rawSteps;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('step_baseline_date', _currentDate);
      await prefs.setInt('step_baseline_value', _baselineSteps);
    }

    int calculatedSteps = rawSteps - _baselineSteps;

    // In case the phone rebooted, the rawSteps will restart from 0,
    // making calculatedSteps negative. We need to reset baseline.
    if (calculatedSteps < 0) {
      _baselineSteps = rawSteps;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('step_baseline_value', _baselineSteps);
      calculatedSteps = 0;
    }

    if (calculatedSteps != _todaySteps) {
      _todaySteps = calculatedSteps;
      _stepController.add(_todaySteps);
      // Persist today's steps
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('step_today_value', _todaySteps);
    }
  }

  void _onStepCountError(dynamic error) {
    debugPrint('Pedometer error: $error');
  }

  void stopListening() {
    _stepCountStream?.cancel();
    _stepCountStream = null;
  }

  Future<Map<String, int>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString('step_history') ?? '{}';
    final Map<String, dynamic> historyMap = jsonDecode(historyStr);
    return historyMap.map((key, value) => MapEntry(key, value as int));
  }
}
