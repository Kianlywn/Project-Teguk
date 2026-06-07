import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum ActivityLevel {
  stationary, // diam
  walking,    // jalan
  active,     // aktif/olahraga
}

class AccelerometerService {
  // Stream controller untuk broadcast activity level ke seluruh app
  final _activityController = StreamController<ActivityLevel>.broadcast();
  Stream<ActivityLevel> get activityStream => _activityController.stream;

  ActivityLevel _currentActivity = ActivityLevel.stationary;
  ActivityLevel get currentActivity => _currentActivity;

  StreamSubscription? _sensorSubscription;

  // Threshold magnitude untuk klasifikasi aktivitas
  static const double _walkingThreshold = 12.0;
  static const double _activeThreshold = 20.0;

  void startListening() {
    _sensorSubscription = accelerometerEventStream().listen((event) {
      double magnitude = _calculateMagnitude(event.x, event.y, event.z);
      ActivityLevel newActivity = _classifyActivity(magnitude);

      // Hanya emit kalau activity berubah
      if (newActivity != _currentActivity) {
        _currentActivity = newActivity;
        _activityController.add(_currentActivity);
      }
    });
  }

  void stopListening() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  // Hitung magnitude dari 3 axis (x, y, z)
  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  // Klasifikasi aktivitas berdasarkan magnitude
  ActivityLevel _classifyActivity(double magnitude) {
    if (magnitude >= _activeThreshold) {
      return ActivityLevel.active;
    } else if (magnitude >= _walkingThreshold) {
      return ActivityLevel.walking;
    } else {
      return ActivityLevel.stationary;
    }
  }

  // Konversi activity ke tambahan kebutuhan air (ml)
  static int getWaterAdjustment(ActivityLevel activity) {
    switch (activity) {
      case ActivityLevel.active:
        return 500; // +500ml kalau olahraga
      case ActivityLevel.walking:
        return 200; // +200ml kalau jalan
      case ActivityLevel.stationary:
        return 0;
    }
  }

  // Konversi activity ke string label
  static String getActivityLabel(ActivityLevel activity) {
    switch (activity) {
      case ActivityLevel.active:
        return 'Aktif Bergerak';
      case ActivityLevel.walking:
        return 'Sedang Berjalan';
      case ActivityLevel.stationary:
        return 'Tidak Aktif';
    }
  }

  void dispose() {
    stopListening();
    _activityController.close();
  }
}
