import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_route.dart';

class SavedRoutesProvider extends ChangeNotifier {
  List<SavedRoute> _savedRoutes = [];

  List<SavedRoute> get savedRoutes => _savedRoutes;

  SavedRoutesProvider() {
    _loadSavedRoutes();
  }

  Future<void> _loadSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? routesJson = prefs.getString('saved_routes');
    if (routesJson != null) {
      final List<dynamic> decoded = json.decode(routesJson);
      _savedRoutes = decoded.map((e) => SavedRoute.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> saveRoute(SavedRoute route) async {
    _savedRoutes.insert(0, route);
    await _persistRoutes();
    notifyListeners();
  }

  Future<void> updateReview(String routeId, double rating, String review) async {
    final index = _savedRoutes.indexWhere((r) => r.id == routeId);
    if (index != -1) {
      _savedRoutes[index] = SavedRoute(
        id: _savedRoutes[index].id,
        routeName: _savedRoutes[index].routeName,
        city: _savedRoutes[index].city,
        category: _savedRoutes[index].category,
        date: _savedRoutes[index].date,
        stops: _savedRoutes[index].stops,
        rating: rating,
        review: review,
      );
      await _persistRoutes();
      notifyListeners();
    }
  }

  Future<void> _persistRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final String routesJson = json.encode(_savedRoutes.map((e) => e.toJson()).toList());
    await prefs.setString('saved_routes', routesJson);
  }

  void deleteRoute(String id) {
    _savedRoutes.removeWhere((r) => r.id == id);
    _persistRoutes();
    notifyListeners();
  }
}