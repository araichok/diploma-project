import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  List<User> _registeredUsers = []; // Список зарегистрированных пользователей

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<bool> register(String email, String name, String phone, String password) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Проверка на существующий email
    if (_registeredUsers.any((user) => user.email == email)) {
      _isLoading = false;
      notifyListeners();
      return false; // Email уже существует
    }
    
    // Проверка на существующий телефон
    if (_registeredUsers.any((user) => user.phone == phone)) {
      _isLoading = false;
      notifyListeners();
      return false; // Телефон уже существует
    }
    
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );
    
    _registeredUsers.add(_currentUser!);
    
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Админ логин
    if (email == 'admin@mail.com' && password == 'admin123') {
      _currentUser = User(
        id: 'admin',
        email: email,
        name: 'Admin',
        phone: '+7 777 777 77 77',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }
    
    // Проверка существующего пользователя
    final existingUser = _registeredUsers.firstWhere(
      (user) => user.email == email,
      orElse: () => _currentUser!,
    );
    
    if (existingUser.id != 'admin') {
      _currentUser = existingUser;
      _isLoading = false;
      notifyListeners();
      return true;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}