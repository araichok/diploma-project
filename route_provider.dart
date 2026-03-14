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
  
  // Getters
  String get location => _location;
  DateTime get selectedDate => _selectedDate;
  String get duration => _duration;
  String get weatherPreference => _weatherPreference;
  double get budget => _budget;
  List<TouristRoute> get generatedRoutes => _generatedRoutes;
  
  // Setters
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
  
  // Generate routes based on mood and preferences
  void generateRoutes(Mood mood) {
    _generatedRoutes = [
      TouristRoute(
        id: '1',
        name: 'Tokyo Hidden Gems',
        description: 'Discover off-the-beaten-path locations that locals love, perfect for adventurous travelers.',
        mood: Mood.adventurous,
        activities: ['Temple Hopping', 'Local Food Tour', 'Secret Gardens', 'Art Alley'],
        durationHours: 8,
        rating: 4.8,
        imageUrl: 'https://via.placeholder.com/400x200/4CAF50',
        waypoints: [
          LatLng(35.6762, 139.6503),
          LatLng(35.6895, 139.6917),
          LatLng(35.7023, 139.7744),
        ],
        weatherPreference: 'any',
        estimatedCost: 450,
      ),
      TouristRoute(
        id: '2',
        name: 'Tokyo Local Favorites',
        description: 'Experience authentic local culture and activities that match your adventurous mood.',
        mood: Mood.adventurous,
        activities: ['Sushi Workshop', 'Samurai Museum', 'Tea Ceremony', 'Night Market'],
        durationHours: 8,
        rating: 4.9,
        imageUrl: 'https://via.placeholder.com/400x200/2196F3',
        waypoints: [
          LatLng(35.6586, 139.7454),
          LatLng(35.6764, 139.7636),
          LatLng(35.7100, 139.8107),
        ],
        weatherPreference: 'any',
        estimatedCost: 380,
      ),
    ];
    notifyListeners();
  }
}