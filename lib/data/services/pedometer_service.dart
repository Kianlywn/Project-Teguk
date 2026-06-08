import 'dart:async';
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
    if (!await requestPermission()) {
      debugPrint('Activity recognition permission denied.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _currentDate = _getTodayDateStr();
    
    // Check if we have a baseline for today
    final savedDate = prefs.getString('step_baseline_date');
    if (savedDate == _currentDate) {
      _baselineSteps = prefs.getInt('step_baseline_value') ?? 0;
    } else {
      // It's a new day, baseline will be set on the first event
      _baselineSteps = -1; // Indicate needs setup
    }

    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
  }

  Future<void> _onStepCount(StepCount event) async {
    final rawSteps = event.steps;

    // Check for new day while running
    final todayStr = _getTodayDateStr();
    if (_currentDate != todayStr) {
      _currentDate = todayStr;
      _baselineSteps = rawSteps;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('step_baseline_date', _currentDate);
      await prefs.setInt('step_baseline_value', _baselineSteps);
      _todaySteps = 0;
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
    }
  }

  void _onStepCountError(dynamic error) {
    debugPrint('Pedometer error: $error');
  }

  void stopListening() {
    _stepCountStream?.cancel();
    _stepCountStream = null;
  }
}
