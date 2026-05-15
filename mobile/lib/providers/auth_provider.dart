import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _lastError;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  String? get lastError => _lastError;

  final ApiService _api = ApiService();

  // email, name, phone kept for signature compatibility with LoginScreen
  Future<bool> register(String email, String name, String phone, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final parts = name.trim().split(RegExp(r'\s+'));
      final firstName = parts.first;
      // Backend requires last_name min=2; fall back to firstName if not provided
      final lastName = parts.length > 1 ? parts.skip(1).join(' ') : firstName;
      await _api.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _cleanGrpcError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // gRPC errors arrive as "Exception: rpc error: code = X desc = <message>"
  String _cleanGrpcError(String raw) {
    final descMatch = RegExp(r'desc = (.+)$').firstMatch(raw);
    if (descMatch != null) return descMatch.group(1)!;
    final exMatch = RegExp(r'Exception: (.+)$').firstMatch(raw);
    if (exMatch != null) return exMatch.group(1)!;
    return raw;
  }

  // name param kept for signature compatibility with LoginScreen (unused by backend)
  Future<bool> login(String email, String password, String name) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final data = await _api.login(email: email, password: password);
      final userData = data['user'] as Map<String, dynamic>? ?? {};
      _currentUser = User.fromBackendJson(userData);

      // admin-service is the source of truth for admin status
      final adminStatus = await _api.isAdmin(_currentUser!.id);
      if (adminStatus) {
        _currentUser = User.fromBackendJson({...userData, 'role': 'admin'});
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _cleanGrpcError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _currentUser = null;
    notifyListeners();
  }
}
