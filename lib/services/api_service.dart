import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_stop.dart';

class ApiService {
  // Если нет бэкенда, используем демо-данные
  static const bool useMockData = true; // Включите мок-данные
  static const String baseUrl = 'http://localhost:8080/api'; // Замените когда будет бэкенд
  
  Future<RouteData> fetchRoute({
    required String city,
    required String category,
    required String duration,
    required double budget,
  }) async {
    if (useMockData) {
      // Возвращаем демо-данные вместо запроса к бэкенду
      await Future.delayed(const Duration(seconds: 1));
      return _getMockRouteData(city, category);
    }
    
    try {
      final url = Uri.parse('$baseUrl/generate-route');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'city': city,
          'category': category,
          'duration': duration,
          'budget': budget,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return RouteData.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
      // При ошибке возвращаем демо-данные
      return _getMockRouteData(city, category);
    }
  }
  
  RouteData _getMockRouteData(String city, String category) {
    final stops = _getMockStops(city);
    return RouteData(
      routeId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      routeName: '$city ${category.toUpperCase()} Tour',
      stops: stops,
    );
  }
  
  List<RouteStop> _getMockStops(String city) {
    if (city == 'Астана') {
      return [
        RouteStop(id: '1', name: 'Байтерек', lat: 51.1282, lng: 71.4305, order: 0),
        RouteStop(id: '2', name: 'Хан Шатыр', lat: 51.1472, lng: 71.4457, order: 1),
        RouteStop(id: '3', name: 'Национальный музей', lat: 51.1255, lng: 71.4289, order: 2),
        RouteStop(id: '4', name: 'Парк Жастар', lat: 51.1565, lng: 71.4352, order: 3),
      ];
    } else {
      return [
        RouteStop(id: '1', name: 'Кок-Тобе', lat: 43.2421, lng: 76.9485, order: 0),
        RouteStop(id: '2', name: 'Медеу', lat: 43.1547, lng: 77.0599, order: 1),
        RouteStop(id: '3', name: 'Зеленый Базар', lat: 43.2613, lng: 76.9402, order: 2),
        RouteStop(id: '4', name: 'Парк Горького', lat: 43.2463, lng: 76.9465, order: 3),
      ];
    }
  }
}