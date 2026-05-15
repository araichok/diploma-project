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

  final ApiService _api = ApiService();

  Future<void> generateRoute({
    required String userId,
    required String city,
    required String category,
    required String duration,
    required double budget,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routeData = await _api.createAndWaitForRoute(
        userId: userId,
        city: city,
        category: category,
        duration: duration,
        budget: budget,
      );
    } catch (e) {
      _error = e.toString();
      print('MapProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearRoute() {
    _routeData = null;
    _error = null;
    notifyListeners();
  }
}
