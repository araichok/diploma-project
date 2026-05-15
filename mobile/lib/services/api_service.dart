import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_stop.dart';

class ApiService {
  static const String baseUrl = 'https://repo-production-6b56.up.railway.app/api';

  // ---------- Роутинг / предпочтения ----------
  Future<Map<String, dynamic>> createPreferences({
    required String userId,
    required String city,
    required String category,
    required String duration,
    required double budget,
  }) async {
    final url = Uri.parse('$baseUrl/v1/preferences');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'city': city,
        'category': category,
        'duration': duration,
        'budget': budget,
      }),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Create preferences failed: ${response.statusCode}');
    }
    return json.decode(response.body);
  }

  Future<RouteData?> fetchRouteByUserId(String userId) async {
    final url = Uri.parse('$baseUrl/v1/routes/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return RouteData.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Fetch route failed: ${response.statusCode}');
    }
  }

  Future<RouteData> createAndWaitForRoute({
    required String userId,
    required String city,
    required String category,
    required String duration,
    required double budget,
    int maxAttempts = 15,
    Duration delay = const Duration(seconds: 2),
  }) async {
    await createPreferences(
      userId: userId,
      city: city,
      category: category,
      duration: duration,
      budget: budget,
    );
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(delay);
      final route = await fetchRouteByUserId(userId);
      if (route != null) return route;
    }
    throw Exception('Route generation timeout');
  }

  // ---------- Фидбэк ----------
  Future<void> sendFeedback({
    required String userId,
    required String routeId,
    required double rating,
    required String comment,
  }) async {
    final url = Uri.parse('$baseUrl/v1/feedback');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'route_id': routeId,
        'rating': rating,
        'comment': comment,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Feedback failed: ${response.statusCode}');
    }
  }

  // ---------- Админка ----------
  Future<void> addAdmin(String userId) async {
    final url = Uri.parse('$baseUrl/v1/admin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Add admin failed: ${response.statusCode}');
    }
  }

  Future<bool> isAdmin(String userId) async {
    final url = Uri.parse('$baseUrl/v1/admin/check/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['is_admin'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final url = Uri.parse('$baseUrl/v1/admin/stats');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Stats failed: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getAllFeedbacks() async {
    final url = Uri.parse('$baseUrl/v1/admin/feedbacks');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Feedbacks list failed: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getAllNotifications() async {
    final url = Uri.parse('$baseUrl/v1/admin/notifications');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Notifications list failed: ${response.statusCode}');
    }
  }
}
