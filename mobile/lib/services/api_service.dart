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

  static const String _accessTokenKey     = 'access_token';
  static const String _refreshTokenKey    = 'refresh_token';
  static const String _profileCacheKey    = 'cached_profile';
  static const String _profileCacheTimeKey= 'cached_profile_time';
  static const String _currentEmailKey    = 'current_user_email';
  static const String _geoapifyKey        = '29d08d752cc44792953561b6cdaf446f';

  static String _phoneKey(String email) =>
      'phone_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _accessToken;
  String? _refreshToken;
  String? _currentEmail;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken  = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    _currentEmail = prefs.getString(_currentEmailKey);
  }

  Future<void> _saveTokens(String a, String r) async {
    _accessToken = a; _refreshToken = r;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, a);
    await prefs.setString(_refreshTokenKey, r);
  }

  Future<void> clearTokens() async {
    _accessToken = null; _refreshToken = null;
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
  Map<String, String> get _pub => {'Content-Type': 'application/json'};

  // ── Safe JSON decode ──────────────────────────────────────────────────────
  Map<String, dynamic> _json(http.Response res) {
    try {
      final d = json.decode(res.body);
      if (d is Map<String, dynamic>) return d;
      return {'message': d.toString()};
    } catch (_) {
      throw Exception(res.body.trim().isNotEmpty ? res.body.trim() : 'HTTP ${res.statusCode}');
    }
  }

  // ── Refresh / retry ───────────────────────────────────────────────────────
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final res = await http.post(Uri.parse('$_baseUrl/refresh-token'),
          headers: _pub, body: json.encode({'refresh_token': _refreshToken}))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final b = _json(res);
        final a = b['access_token'] as String?;
        final r = b['refresh_token'] as String?;
        if (a != null && r != null) { await _saveTokens(a, r); return true; }
      }
    } catch (_) {}
    return false;
  }

  Future<http.Response> _req(Future<http.Response> Function() fn) async {
    var res = await fn();
    if (res.statusCode == 401 && _refreshToken != null) {
      if (await refreshToken()) res = await fn();
      else { await clearTokens(); throw Exception('Session expired. Please login again.'); }
    }
    return res;
  }

  Future<String> getLocalPhone({String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey(email ?? _currentEmail ?? '')) ?? '';
  }

  Future<void> saveLocalPhone(String phone, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey(email ?? _currentEmail ?? ''), phone);
  }

  Future<Map<String, dynamic>> register({
    required String firstName, required String lastName,
    required String email, required String password, String? phoneNumber,
  }) async {
    final res = await http.post(Uri.parse('$_baseUrl/register'), headers: _pub,
        body: json.encode({'first_name': firstName, 'last_name': lastName,
          'email': email, 'password': password}))
        .timeout(const Duration(seconds: 10));
    final body = _json(res);
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Registration failed');
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await saveLocalPhone(phoneNumber, email: email);
    }
    return body;
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await http.post(Uri.parse('$_baseUrl/login'), headers: _pub,
        body: json.encode({'email': email, 'password': password}))
        .timeout(const Duration(seconds: 10));
    final body = _json(res);
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Invalid email or password');
    if (body['access_token'] != null) await _saveTokens(body['access_token'], body['refresh_token']);
    _currentEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentEmailKey, email);
    return body;
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      try { await http.post(Uri.parse('$_baseUrl/logout'), headers: _authHeaders,
            body: json.encode({'refresh_token': _refreshToken}))
            .timeout(const Duration(seconds: 5)); } catch (_) {}
    }
    await clearTokens();
    _currentEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentEmailKey);
  }

  Future<User> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getInt(_profileCacheTimeKey);
      if (t != null && DateTime.now().millisecondsSinceEpoch - t < 5 * 60 * 1000) {
        final cached = prefs.getString(_profileCacheKey);
        if (cached != null) {
          try {
            final u = json.decode(cached) as Map<String, dynamic>;
            final phone = await getLocalPhone(email: u['email'] as String? ?? '');
            return User.fromBackendJson({...u, 'phone_number': phone});
          } catch (_) {}
        }
      }
    }
    final res = await _req(() => http.get(Uri.parse('$_baseUrl/profile'), headers: _authHeaders)
        .timeout(const Duration(seconds: 10)));
    if (res.statusCode != 200) throw Exception('Failed to load profile');
    final body = _json(res);
    final u = body['user'] is Map ? body['user'] as Map<String, dynamic> : body;
    final email = u['email'] as String? ?? _currentEmail ?? '';
    final phone = await getLocalPhone(email: email);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileCacheKey, json.encode(u));
    await prefs.setInt(_profileCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    return User.fromBackendJson({...u, 'phone_number': phone});
  }

  Future<User> updateProfile({
    required String userId, required String firstName, required String lastName,
    required String email, required String phoneNumber,
  }) async {
    await saveLocalPhone(phoneNumber, email: email);
    final body = json.encode({'first_name': firstName, 'last_name': lastName, 'email': email});
    http.Response res = await _req(() =>
        http.put(Uri.parse('$_baseUrl/profile'), headers: _authHeaders, body: body)
            .timeout(const Duration(seconds: 10)));
    if (res.statusCode == 404) {
      res = await _req(() =>
          http.put(Uri.parse('$_baseUrl/users/$userId'), headers: _authHeaders, body: body)
              .timeout(const Duration(seconds: 10)));
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg; try { msg = (_json(res)['error'] ?? 'Failed to update') as String; } catch (_) { msg = 'HTTP ${res.statusCode}'; }
      throw Exception(msg);
    }
    final rb = _json(res);
    final u = rb['user'] is Map ? rb['user'] as Map<String, dynamic> : rb;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCacheKey); await prefs.remove(_profileCacheTimeKey);
    return User.fromBackendJson({...u, 'phone_number': phoneNumber});
  }

  Future<void> changePassword({required String userId, required String oldPassword, required String newPassword}) async {
    final res = await _req(() => http.put(Uri.parse('$_baseUrl/change-password'), headers: _authHeaders,
        body: json.encode({'user_id': userId, 'old_password': oldPassword, 'new_password': newPassword}))
        .timeout(const Duration(seconds: 10)));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg;
      try { final b = json.decode(res.body) as Map<String, dynamic>; msg = b['error'] ?? b['message'] ?? 'Failed'; }
      catch (_) { msg = res.body.isNotEmpty ? res.body.trim() : 'HTTP ${res.statusCode}'; }
      throw Exception(msg);
    }
  }

  Future<void> deleteUser() async {
    await _req(() => http.delete(Uri.parse('$_baseUrl/profile'), headers: _authHeaders)
        .timeout(const Duration(seconds: 10)));
  }

  Future<List<RouteData>> getUserRoutes(String userId) async {
    final res = await _req(() => http.get(Uri.parse('$_baseUrl/routes/$userId'), headers: _authHeaders)
        .timeout(const Duration(seconds: 10)));
    if (res.statusCode != 200) return [];
    final list = _json(res)['routes'] as List? ?? [];
    return list.map((r) => RouteData.fromBackendJson(r as Map<String, dynamic>)).toList();
  }

  Future<RouteData> createAndWaitForRoute({
    required String userId, required String city,
    required String category, required String duration, required double budget,
  }) async {
    final existing = await getUserRoutes(userId);
    final existingIds = existing.map((r) => r.routeId).toSet();
    final hours = int.tryParse(duration.split(' ').first) ?? 2;
    await createPreference(userId: userId, mood: category.toLowerCase(), budget: budget.round(),
        durationHours: hours, location: city,
        travelDate: DateTime.now().toIso8601String().split('T').first);
    for (int i = 0; i < 40; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final routes = await getUserRoutes(userId);
        for (final r in routes) { if (!existingIds.contains(r.routeId)) return r; }
      } catch (_) {}
    }
    final finalRoutes = await getUserRoutes(userId);
    if (finalRoutes.isNotEmpty) return finalRoutes.last;
    throw Exception('Route not created. Check connection and try again.');
  }

  Future<void> createPreference({
    required String userId, required String mood, required int budget,
    required int durationHours, required String location, required String travelDate,
  }) async {
    await _req(() => http.post(Uri.parse('$_baseUrl/preferences'), headers: _authHeaders,
        body: json.encode({'user_id': userId, 'mood': mood, 'budget': budget,
          'duration': durationHours, 'location': location, 'travel_date': travelDate}))
        .timeout(const Duration(seconds: 10)));
  }

  Future<String> fetchPlaceAddress(String placeId) async {
    if (placeId.isEmpty) return '';
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v2/place-details'
        '?id=${Uri.encodeComponent(placeId)}'
        '&features=details'
        '&apiKey=$_geoapifyKey',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return '';
      final data = json.decode(res.body) as Map<String, dynamic>;
      final features = data['features'] as List? ?? [];
      if (features.isEmpty) return '';
      final props = (features[0] as Map<String, dynamic>)['properties'] as Map<String, dynamic>? ?? {};
      // Try formatted first, then address_line1 + address_line2
      final formatted = props['formatted'] as String? ?? '';
      if (formatted.isNotEmpty) return formatted;
      final line1 = props['address_line1'] as String? ?? '';
      final line2 = props['address_line2'] as String? ?? '';
      return [line1, line2].where((s) => s.isNotEmpty).join(', ');
    } catch (_) {
      return '';
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final res = await _req(() => http.get(Uri.parse('$_baseUrl/admin/stats'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15)));
      if (res.statusCode == 200) return _json(res);
    } catch (_) {}
    return {};
  }

  Future<int> countRoutesForUser(String userId) async {
    try {
      final routes = await getUserRoutes(userId);
      return routes.length;
    } catch (_) { return 0; }
  }

  Future<List<Map<String, dynamic>>> getAllFeedbacks() async {
    try {
      final res = await _req(() => http.get(Uri.parse('$_baseUrl/admin/feedbacks'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10)));
      if (res.statusCode != 200) return [];
      return List<Map<String, dynamic>>.from(_json(res)['feedbacks'] ?? []);
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    try {
      final res = await _req(() => http.get(Uri.parse('$_baseUrl/admin/notifications'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10)));
      if (res.statusCode != 200) return [];
      return List<Map<String, dynamic>>.from(_json(res)['notifications'] ?? []);
    } catch (_) { return []; }
  }

  Future<void> addAdmin(String userId) async {
    final res = await _req(() => http.post(Uri.parse('$_baseUrl/admin'), headers: _authHeaders,
        body: json.encode({'user_id': userId})).timeout(const Duration(seconds: 10)));
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception('Failed to add admin');
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/admin/check/$userId'), headers: _authHeaders)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return _json(res)['is_admin'] == true;
    } catch (_) {}
    return false;
  }

  Future<void> submitFeedback({required String userId, required String routeId,
      required int rating, required String comment}) async {
    final res = await _req(() => http.post(Uri.parse('$_baseUrl/feedback'), headers: _authHeaders,
        body: json.encode({'user_id': userId, 'route_id': routeId, 'location_id': '',
          'rating': rating, 'comment': comment})).timeout(const Duration(seconds: 10)));
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception('Failed to submit feedback');
  }

  Future<List<Map<String, dynamic>>> getFeedbackByRoute(String routeId) async {
    final res = await _req(() => http.get(Uri.parse('$_baseUrl/feedback/route/$routeId'), headers: _authHeaders)
        .timeout(const Duration(seconds: 10)));
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(_json(res)['feedbacks'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final res = await _req(() => http.get(Uri.parse('$_baseUrl/notifications/$userId'), headers: _authHeaders)
        .timeout(const Duration(seconds: 10)));
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(_json(res)['notifications'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    final res = await _req(() => http.get(Uri.parse('$_baseUrl/history/$userId'), headers: _authHeaders)
        .timeout(const Duration(seconds: 10)));
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(_json(res)['histories'] ?? []);
  }

  Future<void> createHistory({required String userId, required String routeId}) async {
    await _req(() => http.post(Uri.parse('$_baseUrl/history'), headers: _authHeaders,
        body: json.encode({'user_id': userId, 'route_id': routeId}))
        .timeout(const Duration(seconds: 10)));
  }

  Future<void> completeRoute(String routeId) async {
    await _req(() => http.put(Uri.parse('$_baseUrl/history/status'), headers: _authHeaders,
        body: json.encode({'route_id': routeId, 'status': 'completed'}))
        .timeout(const Duration(seconds: 10)));
  }

  Future<List<List<double>>> fetchRoutePath(List<RouteStop> stops) async {
    if (stops.length < 2) return [];
    final sorted = [...stops]..sort((a, b) => a.order.compareTo(b.order));
    final waypoints = sorted.map((s) => '${s.lat},${s.lng}').join('|');
    final url = Uri.parse(
        'https://api.geoapify.com/v1/routing?waypoints=$waypoints&mode=drive&apiKey=$_geoapifyKey');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final geom = features[0]['geometry'] as Map<String, dynamic>;
          final type = geom['type'] as String;
          final coords = <List<double>>[];
          if (type == 'MultiLineString') {
            for (final seg in geom['coordinates'] as List) {
              for (final pt in seg as List) { coords.add([(pt as List)[0] as double, pt[1] as double]); }
            }
          } else if (type == 'LineString') {
            for (final pt in geom['coordinates'] as List) { coords.add([(pt as List)[0] as double, pt[1] as double]); }
          }
          if (coords.isNotEmpty) return coords;
        }
      }
    } catch (_) {}
    return sorted.map((s) => [s.lng, s.lat]).toList();
  }
}
