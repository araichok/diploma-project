import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_stop.dart';
import '../models/user.dart';

class ApiService {
  static String get _baseUrl => Platform.isAndroid
      ? 'http://10.0.2.2:8080/api/v1'
      : 'http://localhost:8080/api/v1';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _profileCacheKey = 'cached_profile';
  static const String _profileCacheTimeKey = 'cached_profile_time';

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _accessToken;
  String? _refreshToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_profileCacheKey);
    await prefs.remove(_profileCacheTimeKey);
  }

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Map<String, String> get _publicHeaders => {'Content-Type': 'application/json'};

  // ---------- Refresh token ----------
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: _publicHeaders,
        body: json.encode({'refresh_token': _refreshToken}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final newAccess = body['access_token'] as String?;
        final newRefresh = body['refresh_token'] as String?;
        if (newAccess != null && newRefresh != null) {
          await _saveTokens(newAccess, newRefresh);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<http.Response> _requestWithRefresh(Future<http.Response> Function() requestFn) async {
    var response = await requestFn();
    if (response.statusCode == 401 && _refreshToken != null) {
      if (await refreshToken()) {
        response = await requestFn();
      } else {
        await clearTokens();
        throw Exception('Session expired. Please login again.');
      }
    }
    return response;
  }

  // ---------- Auth ----------
 Future<Map<String, dynamic>> register({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  String? phoneNumber,
}) async {
  final res = await http.post(
    Uri.parse('$_baseUrl/register'),
    headers: _publicHeaders,
    body: json.encode({
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber != null && phoneNumber.isNotEmpty ? phoneNumber : '+77777777777', // заглушка
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
    if (body['access_token'] != null && body['refresh_token'] != null) {
      await _saveTokens(body['access_token'], body['refresh_token']);
    }
    return body;
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: _authHeaders,
          body: json.encode({'refresh_token': _refreshToken}),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    await clearTokens();
  }

  // ---------- Profile ----------
  Future<User> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final cachedTime = prefs.getInt(_profileCacheTimeKey);
      if (cachedTime != null && DateTime.now().millisecondsSinceEpoch - cachedTime < 5 * 60 * 1000) {
        final cachedJson = prefs.getString(_profileCacheKey);
        if (cachedJson != null) {
          try {
            final userData = json.decode(cachedJson) as Map<String, dynamic>;
            return User.fromBackendJson(userData);
          } catch (_) {}
        }
      }
    }

    final res = await _requestWithRefresh(() async {
      return await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });

    if (res.statusCode != 200) throw Exception('Failed to load profile');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final userData = body['user'] is Map ? body['user'] as Map<String, dynamic> : body;
    final user = User.fromBackendJson(userData);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileCacheKey, json.encode(userData));
    await prefs.setInt(_profileCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    return user;
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
  }) async {
    final res = await _requestWithRefresh(() async {
      return await http.put(
        Uri.parse('$_baseUrl/profile'),
        headers: _authHeaders,
        body: json.encode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone_number': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 10));
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to update profile');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final userData = body['user'] is Map ? body['user'] as Map<String, dynamic> : body;
    final user = User.fromBackendJson(userData);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCacheKey);
    await prefs.remove(_profileCacheTimeKey);
    return user;
  }

  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final res = await _requestWithRefresh(() async {
      return await http.post(
        Uri.parse('$_baseUrl/change-password'),
        headers: _authHeaders,
        body: json.encode({
          'user_id': userId,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to change password');
    }
  }

  Future<void> deleteUser() async {
    final res = await _requestWithRefresh(() async {
      return await http.delete(
        Uri.parse('$_baseUrl/profile'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to delete account');
    }
    await clearTokens();
  }

  // ---------- Preferences (route generation) ----------
  Future<void> createPreference({
    required String userId,
    required String mood,
    required int budget,
    required int durationHours,
    required String location,
    required String travelDate,
  }) async {
    final res = await _requestWithRefresh(() async {
      return await http.post(
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
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create preference');
    }
  }

  // ---------- Routes ----------
  Future<List<RouteData>> getUserRoutes(String userId) async {
    final res = await _requestWithRefresh(() async {
      return await http.get(
        Uri.parse('$_baseUrl/routes/$userId'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });
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
    final existing = await getUserRoutes(userId);
    final existingIds = existing.map((r) => r.routeId).toSet();
    final hours = int.tryParse(duration.split(' ').first) ?? 2;

    await createPreference(
      userId: userId,
      mood: category.toLowerCase(),
      budget: budget.round(),
      durationHours: hours,
      location: city,
      travelDate: DateTime.now().toIso8601String().split('T').first,
    );

    for (int i = 0; i < 25; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final routes = await getUserRoutes(userId);
      for (final r in routes) {
        if (!existingIds.contains(r.routeId)) return r;
      }
    }

    final finalRoutes = await getUserRoutes(userId);
    if (finalRoutes.isNotEmpty) {
      return finalRoutes.last;
    }
    throw Exception('No route data available');
  }

  // ---------- Feedback ----------
  Future<void> submitFeedback({
    required String userId,
    required String routeId,
    required int rating,
    required String comment,
  }) async {
    final res = await _requestWithRefresh(() async {
      return await http.post(
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
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to submit feedback');
    }
  }

  Future<List<Map<String, dynamic>>> getFeedbackByRoute(String routeId) async {
    final res = await _requestWithRefresh(() async {
      return await http.get(
        Uri.parse('$_baseUrl/feedback/route/$routeId'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['feedbacks'] ?? []);
  }

  // ---------- Notifications ----------
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final res = await _requestWithRefresh(() async {
      return await http.get(
        Uri.parse('$_baseUrl/notifications/$userId'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['notifications'] ?? []);
  }

  // ---------- Admin ----------
  Future<void> addAdmin(String userId) async {
    final res = await _requestWithRefresh(() async {
      return await http.post(
        Uri.parse('$_baseUrl/admin'),
        headers: _authHeaders,
        body: json.encode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));
    });
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
        final body = json.decode(res.body) as Map<String, dynamic>;
        return body['is_admin'] == true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await _requestWithRefresh(() async {
      return await http.get(
        Uri.parse('$_baseUrl/admin/stats'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to load stats');
  }

  Future<List<Map<String, dynamic>>> getAllFeedbacks() async {
    final res = await _requestWithRefresh(() async {
      return await http.get(
        Uri.parse('$_baseUrl/admin/feedbacks'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['feedbacks'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final res = await _requestWithRefresh(() async {
      return await http.get(
        Uri.parse('$_baseUrl/admin/notifications'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['notifications'] ?? []);
  }

  // ---------- History ----------
  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    final res = await _requestWithRefresh(() async {
      return await http.get(
        Uri.parse('$_baseUrl/history/$userId'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['histories'] ?? []);
  }

  Future<void> createHistory({
    required String userId,
    required String routeId,
  }) async {
    final res = await _requestWithRefresh(() async {
      return await http.post(
        Uri.parse('$_baseUrl/history'),
        headers: _authHeaders,
        body: json.encode({'user_id': userId, 'route_id': routeId}),
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to create history');
    }
  }

  Future<void> completeRoute(String routeId) async {
    final res = await _requestWithRefresh(() async {
      return await http.put(
        Uri.parse('$_baseUrl/history/status'),
        headers: _authHeaders,
        body: json.encode({'route_id': routeId, 'status': 'completed'}),
      ).timeout(const Duration(seconds: 10));
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to complete route');
    }
  }

  // ---------- Map routing ----------
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
    return sorted.map((s) => [s.lng, s.lat]).toList();
  }

  static const String _geoapifyKey = '29d08d752cc44792953561b6cdaf446f';
}
