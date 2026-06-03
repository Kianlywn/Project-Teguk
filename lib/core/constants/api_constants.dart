import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Membaca Base URL secara dinamis dari file .env (fallback ke emulator localhost jika kosong)
  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000';

  static final String login = '$baseUrl/api/auth/login';
  static final String register = '$baseUrl/api/auth/register';
  static final String water = '$baseUrl/api/water';
  static final String waterToday = '$baseUrl/api/water/today';
  static final String waterHistory = '$baseUrl/api/water/history';
  static final String consultation = '$baseUrl/api/consultation';
  static final String consultationMessage = '$baseUrl/api/consultation/message';
  static final String consultationMy = '$baseUrl/api/consultation/my-consultations';
  static final String activity = '$baseUrl/api/activity';
}