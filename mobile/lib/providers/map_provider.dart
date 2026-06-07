import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/route_stop.dart';
import '../services/api_service.dart';
import '../services/geoapify_config.dart';

class MapProvider extends ChangeNotifier {
  RouteData? _routeData;
  List<RouteStop> _sortedStops = [];
  List<List<double>>? _routePath;
  List<Uint8List?> _stopImages = [];
  bool _isLoading = false;
  bool _isCompleted = false;
  bool _isMapRefreshing = false;
  String? _error;
  int _currentStopIndex = 0;
  String _markerColor = '#0066FF';
  String _userId = '';
  int? _beforeMood;
  bool _isGenerating = false;

  int? get beforeMood => _beforeMood;
  set beforeMood(int? v) => _beforeMood = v;

  RouteData? get routeData => _routeData;
  Uint8List? get mapImageBytes =>
      _stopImages.isNotEmpty && _currentStopIndex < _stopImages.length
          ? _stopImages[_currentStopIndex]
          : null;
  bool get isLoading => _isLoading;
  bool get isMapRefreshing => _isMapRefreshing;
  bool get isCompleted => _isCompleted;
  String? get error => _error;
  int get currentStopIndex => _currentStopIndex;
  List<RouteStop> get sortedStops => _sortedStops;
  RouteStop? get currentStop =>
      _sortedStops.isNotEmpty ? _sortedStops[_currentStopIndex] : null;
  bool get isLastStop =>
      _sortedStops.isNotEmpty && _currentStopIndex >= _sortedStops.length - 1;

  final ApiService _api = ApiService();

  Future<void> generateRoute({
    required String userId,
    required String city,
    required String category,
    required String duration,
    required double budget,
    String markerColor = '#0066FF',
  }) async {
    if (_isGenerating) {
      debugPrint('[MapProvider] generateRoute already running, skipping');
      return;
    }
    _isGenerating = true;
    _isLoading = true;
    _isCompleted = false;
    _error = null;
    _stopImages = [];
    _routeData = null;
    _sortedStops = [];
    _currentStopIndex = 0;
    _markerColor = markerColor;
    _userId = userId;
    _beforeMood = null;
    notifyListeners();

    try {
      _routeData = await _api.createAndWaitForRoute(
        userId: userId,
        city: city,
        category: category,
        duration: duration,
        budget: budget,
      ).timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw Exception('Route generation timed out. Please try again.'),
      );

      if (_routeData != null) {
        _sortedStops = [..._routeData!.stops]
          ..sort((a, b) => a.order.compareTo(b.order));

        if (_sortedStops.length >= 2) {
          _routePath = await _api.fetchRoutePath(_sortedStops);
        }

        _stopImages = await Future.wait<Uint8List?>(
          List.generate(_sortedStops.length, (i) async {
            try {
              return await _fetchMapImageForStop(i);
            } catch (_) {
              return null;
            }
          }),
        );

        try {
          await _api.createHistory(userId: userId, routeId: _routeData!.routeId);
        } catch (_) {}
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> advanceStop() async {
    if (_routeData == null || isLastStop) return;
    _currentStopIndex++;
    notifyListeners();
  }

  Future<bool> completeRoute() async {
    if (_routeData == null) return false;
    try {
      await _api.completeRoute(_routeData!.routeId);
      _isCompleted = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateStopAddress(String stopId, String address) {
    final idx = _sortedStops.indexWhere((s) => s.id == stopId);
    if (idx < 0 || address.isEmpty) return;
    _sortedStops = List.of(_sortedStops);
    _sortedStops[idx] = _sortedStops[idx].withAddress(address);
    notifyListeners();
  }

  void clearRoute() {
    _routeData = null;
    _sortedStops = [];
    _routePath = null;
    _stopImages = [];
    _error = null;
    _currentStopIndex = 0;
    _isCompleted = false;
    _isGenerating = false;
    _beforeMood = null;
    notifyListeners();
  }


  Future<Uint8List?> _fetchMapImageForStop(int activeIndex) async {
    if (_sortedStops.isEmpty) return null;

    final stops = _sortedStops;
    final minLat = stops.map((s) => s.lat).reduce(min);
    final maxLat = stops.map((s) => s.lat).reduce(max);
    final minLng = stops.map((s) => s.lng).reduce(min);
    final maxLng = stops.map((s) => s.lng).reduce(max);
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final zoom = _calculateZoom(maxLat - minLat, maxLng - minLng, centerLat);

    final markers = <Map<String, dynamic>>[];
    for (int i = 0; i < stops.length; i++) {
      final s = stops[i];
      final String color;
      final String size;
      if (i < activeIndex) {
        color = '#888888';
        size = 'medium';
      } else if (i == activeIndex) {
        color = '#FFD700';
        size = 'large';
      } else {
        color = _markerColor;
        size = 'medium';
      }
      markers.add({
        'lat': s.lat,
        'lon': s.lng,
        'color': color,
        'size': size,
        'type': 'material',
        'text': '${i + 1}',
      });
    }

    final bodyMap = <String, dynamic>{
      'style': 'osm-bright',
      'width': 600,
      'height': 600,
      'center': {'lat': centerLat, 'lon': centerLng},
      'zoom': zoom,
      'markers': markers,
    };

    if (_routePath != null && _routePath!.length >= 2) {
      const maxPoints = 30;
      final step = max(1, (_routePath!.length / maxPoints).ceil());
      final simplified = _simplifyPath(_routePath!, step: step);
      bodyMap['geometries'] = [
        {
          'type': 'polyline',
          'linecolor': '#0066FF',
          'linewidth': 3,
          'lineopacity': 0.8,
          'linestyle': 'solid',
          'value': simplified
              .map((pt) => {'lat': pt[1], 'lon': pt[0]})
              .toList(),
        }
      ];
    }

    final uri = Uri.parse(
      'https://maps.geoapify.com/v1/staticmap?apiKey=${GeoapifyConfig.apiKey}',
    );

    final response = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(bodyMap))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('Static map failed: ${response.statusCode}');
  }

  List<List<double>> _simplifyPath(List<List<double>> path, {int step = 5}) {
    if (path.length <= step) return path;
    final result = <List<double>>[];
    for (int i = 0; i < path.length; i++) {
      if (i == 0 || i == path.length - 1 || i % step == 0) result.add(path[i]);
    }
    return result;
  }

  int _calculateZoom(double latSpan, double lngSpan, double centerLat) {
    if (latSpan == 0 && lngSpan == 0) return 14;
    const imageSize = 600;
    const tileSize = 256;
    const padding = 2.1;
    final effLat = max(latSpan, 0.001) * padding;
    final effLng = max(lngSpan, 0.001) * padding;
    final zoomLng = log(imageSize * 360 / (tileSize * effLng)) / ln2;
    final cosLat = cos(centerLat * pi / 180);
    final zoomLat = log(imageSize * 360 * cosLat / (tileSize * effLat)) / ln2;
    return min(zoomLng, zoomLat).floor().clamp(1, 16);
  }
}
