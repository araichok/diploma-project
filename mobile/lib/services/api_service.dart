import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_stop.dart';

class ApiService {
  // Android emulator needs 10.0.2.2 (host loopback alias); iOS simulator shares the Mac's network stack
  static String get _baseUrl => Platform.isAndroid
      ? 'http://10.0.2.2:8080/api/v1'
      : 'http://localhost:8080/api/v1';
  static const String _tokenKey = 'auth_token';

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Map<String, String> get _publicHeaders => {'Content-Type': 'application/json'};

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: _publicHeaders,
      body: json.encode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Registration failed');
    return body;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: _publicHeaders,
      body: json.encode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10));
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Invalid email or password');
    if (body['access_token'] != null) await _saveToken(body['access_token']);
    return body;
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: _authHeaders,
        body: json.encode({'refresh_token': ''}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
    await clearToken();
  }

  // ── Preferences → triggers async route generation ─────────────────────────

  Future<void> createPreference({
    required String userId,
    required String mood,
    required int budget,
    required int durationHours,
    required String location,
    required String travelDate,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/preferences'),
      headers: _authHeaders,
      body: json.encode({
        'user_id': userId,
        'mood': mood,
        'budget': budget,
        'duration': durationHours,
        'location': location,
        'travel_date': travelDate,
      }),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create preference');
    }
  }

  // ── Routes ────────────────────────────────────────────────────────────────

  Future<List<RouteData>> getUserRoutes(String userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/routes/$userId'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = body['routes'] as List? ?? [];
    return list.map((r) => RouteData.fromBackendJson(r as Map<String, dynamic>)).toList();
  }

  Future<RouteData> createAndWaitForRoute({
    required String userId,
    required String city,
    required String category,
    required String duration,
    required double budget,
  }) async {
    // Snapshot existing route IDs so we can detect the new one
    final existing = await getUserRoutes(userId);
    final existingIds = existing.map((r) => r.routeId).toSet();

    // Parse "2 часа" → 2
    final hours = int.tryParse(duration.split(' ').first) ?? 2;

    await createPreference(
      userId: userId,
      mood: category.toLowerCase(),
      budget: budget.round(),
      durationHours: hours,
      location: city,
      travelDate: DateTime.now().toIso8601String().split('T').first,
    );

    // Poll until a new route appears (up to 30 s)
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final routes = await getUserRoutes(userId);
      for (final r in routes) {
        if (!existingIds.contains(r.routeId)) return r;
      }
    }
    throw Exception('Route generation timed out. Please try again.');
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  Future<void> submitFeedback({
    required String userId,
    required String routeId,
    required int rating,
    required String comment,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/feedback'),
      headers: _authHeaders,
      body: json.encode({
        'user_id': userId,
        'route_id': routeId,
        'location_id': '',
        'rating': rating,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to submit feedback');
    }
  }

  Future<List<Map<String, dynamic>>> getFeedbackByRoute(String routeId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/feedback/route/$routeId'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['feedbacks'] ?? []);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/notifications/$userId'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['notifications'] ?? []);
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  Future<void> addAdmin(String userId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/admin'),
      headers: _authHeaders,
      body: json.encode({'user_id': userId}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to add admin');
    }
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/check/$userId'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return (json.decode(res.body) as Map<String, dynamic>)['is_admin'] == true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/stats'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to load stats');
  }

  Future<List<Map<String, dynamic>>> getAllFeedbacks() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/feedbacks'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['feedbacks'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/notifications'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['notifications'] ?? []);
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/history/$userId'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['histories'] ?? []);
  }

  Future<void> createHistory({
    required String userId,
    required String routeId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/history'),
      headers: _authHeaders,
      body: json.encode({'user_id': userId, 'route_id': routeId}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to create history');
    }
  }

  Future<void> completeRoute(String routeId) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/history/status'),
      headers: _authHeaders,
      body: json.encode({'route_id': routeId, 'status': 'completed'}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to complete route');
    }
  }

  // ── Map / Routing ─────────────────────────────────────────────────────────

  Future<List<List<double>>> fetchRoutePath(List<RouteStop> stops) async {
    if (stops.length < 2) return [];

    final sorted = [...stops]..sort((a, b) => a.order.compareTo(b.order));
    final waypoints = sorted.map((s) => '${s.lat},${s.lng}').join('|');
    final url = Uri.parse(
      'https://api.geoapify.com/v1/routing?waypoints=$waypoints&mode=drive&apiKey=${_geoapifyKey}',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final geometry = features[0]['geometry'] as Map<String, dynamic>;
          final type = geometry['type'] as String;
          final coords = <List<double>>[];
          if (type == 'MultiLineString') {
            for (final segment in geometry['coordinates'] as List) {
              for (final pt in segment as List) {
                coords.add([(pt as List)[0] as double, pt[1] as double]);
              }
            }
          } else if (type == 'LineString') {
            for (final pt in geometry['coordinates'] as List) {
              coords.add([(pt as List)[0] as double, pt[1] as double]);
            }
          }
          if (coords.isNotEmpty) return coords;
        }
      }
    } catch (_) {}

    // Fallback: straight lines between stops
    return sorted.map((s) => [s.lng, s.lat]).toList();
  }

  static const String _geoapifyKey = '29d08d752cc44792953561b6cdaf446f';
}
