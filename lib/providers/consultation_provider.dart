import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/consultation_repository.dart';

class ConsultationProvider extends ChangeNotifier {
  final _repository = ConsultationRepository();

  List<dynamic> _consultations = [];
  List<dynamic> _messages = [];
  bool _isLoading = false;

  List<dynamic> get consultations => _consultations;
  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;

  // Fetch all consultations
  Future<void> fetchConsultations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _repository.getMyConsultations();
      if (list != null) {
        _consultations = list;
      }
    } catch (e) {
      debugPrint('Error fetching consultations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch messages for a specific consultation
  Future<void> fetchMessages(String consultationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _repository.getMessages(consultationId);
      if (list != null) {
        _messages = list;
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new consultation
  Future<bool> createConsultation(String expertId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.createConsultation(expertId);
      if (result != null) {
        await fetchConsultations(); // Refresh list
        return true;
      }
    } catch (e) {
      debugPrint('Error creating consultation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Send a new message
  Future<bool> sendMessage(String consultationId, String message) async {
    try {
      final success = await _repository.sendMessage(consultationId, message);
      if (success) {
        await fetchMessages(consultationId); // Refresh messages list
        return true;
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
    return false;
  }
}
