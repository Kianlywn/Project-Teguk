import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final _repository = AdminRepository();

  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _pendingExperts = [];
  bool _isLoading = false;

  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<dynamic> get pendingExperts => _pendingExperts;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      _dashboardStats = await _repository.getDashboard();
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingExperts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _repository.getPendingExperts();
      if (list != null) _pendingExperts = list;
    } catch (e) {
      debugPrint('Error fetching pending experts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveExpert(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _repository.approveExpert(id);
      if (success) {
        _pendingExperts.removeWhere((e) => e['id'] == id);
      }
      return success;
    } catch (e) {
      debugPrint('Error approving expert: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectExpert(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _repository.rejectExpert(id);
      if (success) {
        _pendingExperts.removeWhere((e) => e['id'] == id);
      }
      return success;
    } catch (e) {
      debugPrint('Error rejecting expert: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
