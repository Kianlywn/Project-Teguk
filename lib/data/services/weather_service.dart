import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teguk/data/models/weather_model.dart';

class WeatherService {
  static final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<WeatherModel?> getWeatherByCoords(
    double lat,
    double lon,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Hitung tambahan air berdasarkan suhu
  static int getWaterAdjustment(double temperature) {
    if (temperature >= 35) {
      return 500; // sangat panas +500ml
    } else if (temperature >= 30) {
      return 300; // panas +300ml
    } else {
      return 0;
    }
  }
}
