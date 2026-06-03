import 'package:flutter/material.dart';
import 'package:teguk/data/models/weather_model.dart';
import 'package:teguk/data/services/location_service.dart';
import 'package:teguk/data/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherModel? _weather;
  int _waterAdjustment = 0;
  bool _isLoading = false;
  String? _error;

  WeatherModel? get weather => _weather;
  int get waterAdjustment => _waterAdjustment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeather() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        _error = 'Lokasi tidak tersedia';
        return;
      }

      _weather = await WeatherService.getWeatherByCoords(
        position.latitude,
        position.longitude,
      );

      if (_weather == null) {
        _error = 'Data cuaca tidak ditemukan';
        return;
      }

      _waterAdjustment =
          WeatherService.getWaterAdjustment(_weather!.temperature);
    } catch (e) {
      _error = 'Gagal memuat cuaca';
      debugPrint('Error fetching weather: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
