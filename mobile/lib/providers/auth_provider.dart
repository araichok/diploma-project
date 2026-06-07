import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _roleKey = 'user_role';

  Future<bool> register(String email, String name, String phoneNumber, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final parts = name.trim().split(RegExp(r'\s+'));
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.skip(1).join(' ') : firstName;
      await _api.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _cleanError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password, String name) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final data = await _api.login(email: email, password: password);
      final userData = data['user'] as Map<String, dynamic>? ?? {};

      final phone = await _api.getLocalPhone();
      _currentUser = User.fromBackendJson({...userData, 'phone_number': phone});

      final adminStatus = await _api.isAdmin(_currentUser!.id);
      if (adminStatus) {
        _currentUser = User.fromBackendJson({...userData, 'role': 'admin', 'phone_number': phone});
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, _currentUser!.role.name);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _cleanError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> restoreSession() async {
    try {
      final user = await _api.getProfile(forceRefresh: false);
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString(_roleKey) ?? 'user';
      if (savedRole == 'admin') {
        _currentUser = User.fromBackendJson({
          ...user.toJson(),
          'role': 'admin',
        });
      } else {
        _currentUser = user;
      }
      notifyListeners();
    } catch (_) {
      // no valid session
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _api.updateProfile(
        userId:      _currentUser?.id ?? '',
        firstName:   firstName,
        lastName:    lastName,
        email:       email,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      _lastError = _cleanError(e.toString());
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.changePassword(
        userId: _currentUser!.id,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      _lastError = _cleanError(e.toString());
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.deleteUser();
      await _api.logout();
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roleKey);
    } catch (e) {
      _lastError = _cleanError(e.toString());
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    notifyListeners();
  }

  String _cleanError(String raw) {
    final descMatch = RegExp(r'desc = (.+)$').firstMatch(raw);
    if (descMatch != null) return descMatch.group(1)!;
    final exMatch = RegExp(r'Exception: (.+)$').firstMatch(raw);
    if (exMatch != null) return exMatch.group(1)!;
    return raw;
  }
}
