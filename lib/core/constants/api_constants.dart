import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static final String baseUrl =
      dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000';

  // Auth
  static final String login = '$baseUrl/api/auth/login';
  static final String register = '$baseUrl/api/auth/register';

  // Users
  static final String userProfile = '$baseUrl/api/users/profile';

  // Water
  static final String water = '$baseUrl/api/water';
  static final String waterToday = '$baseUrl/api/water/today';
  static final String waterHistory = '$baseUrl/api/water/history';

  // Activity
  static final String activity = '$baseUrl/api/activity';

  // Reminder
  static final String reminder = '$baseUrl/api/reminder';

  // Consultation
  static final String consultation = '$baseUrl/api/consultation';
  static final String consultationMessage = '$baseUrl/api/consultation/message';
  static final String consultationMy = '$baseUrl/api/consultation/my-consultations';

  // Health Expert
  static final String healthExpertList = '$baseUrl/api/healthexpert/list';
  static final String healthExpertApply = '$baseUrl/api/healthexpert/apply';
  static final String healthExpertMyApplication = '$baseUrl/api/healthexpert/my-application';
  static final String healthExpertPending = '$baseUrl/api/healthexpert/pending';
  static String healthExpertApprove(String id) => '$baseUrl/api/healthexpert/approve/$id';
  static String healthExpertReject(String id) => '$baseUrl/api/healthexpert/reject/$id';

  // Statistics
  static final String statsWeekly = '$baseUrl/api/statistics/weekly';
  static final String statsMonthly = '$baseUrl/api/statistics/monthly';

  // Admin
  static final String adminDashboard = '$baseUrl/api/admin/dashboard';
  static final String adminUsers = '$baseUrl/api/admin/users';
  static final String adminExperts = '$baseUrl/api/admin/experts';
}
