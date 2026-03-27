import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../models/route.dart';

class RouteProvider extends ChangeNotifier {
  String _location = '';
  DateTime _selectedDate = DateTime.now();
  String _duration = 'Full Day (8 hours)';
  String _weatherPreference = 'Any Weather';
  double _budget = 500;
  List<TouristRoute> _generatedRoutes = [];
  
  String get location => _location;
  DateTime get selectedDate => _selectedDate;
  String get duration => _duration;
  String get weatherPreference => _weatherPreference;
  double get budget => _budget;
  List<TouristRoute> get generatedRoutes => _generatedRoutes;
  
  void setLocation(String location) {
    _location = location;
    notifyListeners();
  }
  
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  void setDuration(String duration) {
    _duration = duration;
    notifyListeners();
  }
  
  void setWeatherPreference(String preference) {
    _weatherPreference = preference;
    notifyListeners();
  }
  
  void setBudget(double budget) {
    _budget = budget;
    notifyListeners();
  }
  
  String _formatCityName(String city) {
    if (city.isEmpty) return '';
    return city[0].toUpperCase() + city.substring(1).toLowerCase();
  }
  
  void generateRoutes(Mood mood) {
    if (_location.isEmpty) {
      _generatedRoutes = [];
      notifyListeners();
      return;
    }
    
    String formattedCity = _formatCityName(_location);
    
    _generatedRoutes = [
      TouristRoute(
        id: '1',
        name: '$formattedCity Hidden Gems',
        description: 'Discover off-the-beaten-path locations that locals love in $formattedCity, perfect for ${mood.displayName.toLowerCase()} travelers.',
        mood: mood,
        activities: _getActivitiesForCityAndMood(_location, mood, true),
        durationHours: _getDurationHours(_duration),
        rating: 4.8,
        imageUrl: _getCityImage(_location, 1),
        waypoints: _getWaypointsForCity(_location, 0),
        weatherPreference: _weatherPreference.toLowerCase(),
        estimatedCost: _budget.toInt(),
      ),
      TouristRoute(
        id: '2',
        name: '$formattedCity Local Favorites',
        description: 'Experience authentic local culture and activities in $formattedCity that match your ${mood.displayName.toLowerCase()} mood.',
        mood: mood,
        activities: _getActivitiesForCityAndMood(_location, mood, false),
        durationHours: _getDurationHours(_duration),
        rating: 4.9,
        imageUrl: _getCityImage(_location, 2),
        waypoints: _getWaypointsForCity(_location, 1),
        weatherPreference: _weatherPreference.toLowerCase(),
        estimatedCost: (_budget * 0.8).toInt(),
      ),
    ];
    notifyListeners();
  }
  
  int _getDurationHours(String duration) {
    if (duration.contains('Half Day')) return 4;
    if (duration.contains('Full Day')) return 8;
    return 8;
  }
  
  List<String> _getActivitiesForCityAndMood(String city, Mood mood, bool isFirstRoute) {
    Map<String, List<String>> cityActivities = {
      'madrid': ['Royal Palace', 'Prado Museum', 'Retiro Park', 'Plaza Mayor', 'San Miguel Market'],
      'barcelona': ['Sagrada Familia', 'Park Güell', 'Las Ramblas', 'Gothic Quarter', 'Camp Nou'],
      'paris': ['Eiffel Tower', 'Louvre', 'Notre-Dame', 'Montmartre', 'Seine Cruise'],
      'tokyo': ['Shibuya', 'Senso-ji', 'Meiji Shrine', 'Tsukiji Market', 'Shinjuku'],
      'rome': ['Colosseum', 'Vatican', 'Trevi Fountain', 'Roman Forum', 'Pantheon'],
      'london': ['Big Ben', 'London Eye', 'British Museum', 'Tower of London', 'Hyde Park'],
    };
    
    List<String> activities = cityActivities[city.toLowerCase()] ?? cityActivities['tokyo']!;
    
    switch (mood) {
      case Mood.romantic:
        return isFirstRoute 
            ? [activities[0], 'Sunset Views', 'Romantic Dinner', activities[3]]
            : [activities[1], 'Candle Light Tour', 'Wine Tasting', activities[4]];
      case Mood.adventurous:
        return isFirstRoute
            ? [activities[0], 'Hidden Spots', 'Local Adventure', activities[2]]
            : [activities[1], 'Extreme Tour', 'Secret Locations', activities[4]];
      case Mood.thrilling:
        return isFirstRoute
            ? [activities[0], 'Adrenaline Rush', 'Extreme Sports', activities[2]]
            : [activities[1], 'Night Adventure', 'Fast & Furious', activities[4]];
      case Mood.curious:
        return isFirstRoute
            ? [activities[0], 'Museum Tour', 'Historical Sites', activities[3]]
            : [activities[2], 'Science Center', 'Cultural Exploration', activities[1]];
      case Mood.relaxed:
        return isFirstRoute
            ? ['Peaceful Parks', 'Spa Time', 'Quiet Cafes', 'Meditation']
            : ['Garden Walks', 'Slow Tour', 'Relaxation Points', 'Tea Houses'];
      case Mood.happy:
      default:
        return isFirstRoute
            ? [activities[0], 'Joyful Places', 'Fun Activities', activities[3]]
            : [activities[1], 'Entertainment', 'Food & Fun', activities[4]];
    }
  }
  
  String _getCityImage(String city, int index) {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    
    Color color = colors[city.hashCode.abs() % colors.length];
    
    return 'color_${color.value}_$index';
  }
  
  List<RoutePoint> _getWaypointsForCity(String city, int routeIndex) {
    Map<String, List<List<RoutePoint>>> cityWaypoints = {
      'madrid': [
        [
          const RoutePoint(40.4168, -3.7038),  // Puerta del Sol
          const RoutePoint(40.4131, -3.6924),  // Prado Museum
          const RoutePoint(40.4245, -3.7115),  // Royal Palace
          const RoutePoint(40.4203, -3.7057),  // Plaza Mayor
        ],
        [
          const RoutePoint(40.4200, -3.7060),
          const RoutePoint(40.4250, -3.7100),
          const RoutePoint(40.4150, -3.6950),
          const RoutePoint(40.4180, -3.7020),
        ],
      ],
      'barcelona': [
        [
          const RoutePoint(41.3851, 2.1734),
          const RoutePoint(41.4036, 2.1744),
          const RoutePoint(41.3809, 2.1228),
          const RoutePoint(41.3952, 2.1705),
        ],
        [
          const RoutePoint(41.3900, 2.1650),
          const RoutePoint(41.4000, 2.1700),
          const RoutePoint(41.3850, 2.1800),
          const RoutePoint(41.3950, 2.1550),
        ],
      ],
      'paris': [
        [
          const RoutePoint(48.8566, 2.3522),
          const RoutePoint(48.8606, 2.3376),
          const RoutePoint(48.8584, 2.2945),
          const RoutePoint(48.8738, 2.2950),
        ],
        [
          const RoutePoint(48.8800, 2.3400),
          const RoutePoint(48.8650, 2.3300),
          const RoutePoint(48.8500, 2.3500),
          const RoutePoint(48.8900, 2.3600),
        ],
      ],
      'tokyo': [
        [
          const RoutePoint(35.6762, 139.6503),
          const RoutePoint(35.6895, 139.6917),
          const RoutePoint(35.7023, 139.7744),
        ],
        [
          const RoutePoint(35.6586, 139.7454),
          const RoutePoint(35.6764, 139.7636),
          const RoutePoint(35.7100, 139.8107),
        ],
      ],
    };
    
    List<List<RoutePoint>> waypoints = cityWaypoints[city.toLowerCase()] ?? cityWaypoints['tokyo']!;
    return waypoints[routeIndex % waypoints.length];
  }
}
