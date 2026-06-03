import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/core/constants/api_constants.dart';

class ConsultationRepository {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get My Consultations
  Future<List<dynamic>?> getMyConsultations() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(ApiConstants.consultationMy),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  // Get Messages for a Consultation
  Future<List<dynamic>?> getMessages(String consultationId) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${ApiConstants.consultation}/$consultationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  // Create a Consultation
  Future<Map<String, dynamic>?> createConsultation(String expertId) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse(ApiConstants.consultation),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'expertId': expertId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  // Send Message
  Future<bool> sendMessage(String consultationId, String message) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse(ApiConstants.consultationMessage),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'consultationId': consultationId,
        'message': message,
      }),
    );

    return response.statusCode == 200;
  }
}
