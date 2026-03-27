import 'mood.dart';

class RoutePoint {
  final double latitude;
  final double longitude;
  
  const RoutePoint(this.latitude, this.longitude);
  
  @override
  String toString() => '($latitude, $longitude)';
}

class TouristRoute {
  final String id;
  final String name;
  final String description;
  final Mood mood;
  final List<String> activities;
  final int durationHours;
  final double rating;
  final String imageUrl;
  final List<RoutePoint> waypoints;
  final String weatherPreference;
  final int estimatedCost;

  TouristRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.mood,
    required this.activities,
    required this.durationHours,
    required this.rating,
    required this.imageUrl,
    required this.waypoints,
    required this.weatherPreference,
    required this.estimatedCost,
  });
}
