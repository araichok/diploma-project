import 'package:flutter/material.dart';
import '../models/route_stop.dart';
import '../services/api_service.dart';

class MapProvider extends ChangeNotifier {
  RouteData? _routeData;
  bool _isLoading = false;
  String? _error;

  RouteData? get routeData => _routeData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRoute({
    required String city,
    required String category,
    required String duration,
    required double budget,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      _routeData = await apiService.fetchRoute(
        city: city,
        category: category,
        duration: duration,
        budget: budget,
      );
    } catch (e) {
      _error = e.toString();
      print('Error in MapProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearRoute() {
    _routeData = null;
    notifyListeners();
  }
}