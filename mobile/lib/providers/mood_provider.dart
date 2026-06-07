import 'package:flutter/material.dart';

enum TravelCategory {
  calm,
  happy,
  romantic,
  active,
  cultural,
  food,
  shopping,
}

extension TravelCategoryExtension on TravelCategory {
  String get displayName {
    switch (this) {
      case TravelCategory.calm: return 'Calm';
      case TravelCategory.happy: return 'Happy';
      case TravelCategory.romantic: return 'Romantic';
      case TravelCategory.active: return 'Active';
      case TravelCategory.cultural: return 'Cultural';
      case TravelCategory.food: return 'Food';
      case TravelCategory.shopping: return 'Shopping';
    }
  }

  IconData get icon {
    switch (this) {
      case TravelCategory.calm: return Icons.spa;
      case TravelCategory.happy: return Icons.emoji_emotions;
      case TravelCategory.romantic: return Icons.favorite;
      case TravelCategory.active: return Icons.directions_run;
      case TravelCategory.cultural: return Icons.museum;
      case TravelCategory.food: return Icons.restaurant;
      case TravelCategory.shopping: return Icons.shopping_bag;
    }
  }

  Color get color {
    switch (this) {
      case TravelCategory.calm: return Colors.teal;
      case TravelCategory.happy: return Colors.amber;
      case TravelCategory.romantic: return Colors.redAccent;
      case TravelCategory.active: return Colors.orange;
      case TravelCategory.cultural: return Colors.purple;
      case TravelCategory.food: return Colors.deepOrange;
      case TravelCategory.shopping: return Colors.pink;
    }
  }
}

class MoodProvider extends ChangeNotifier {
  TravelCategory? _selectedCategory;
  String _selectedCity = '';
  String _duration = '2 часа';
  DateTime _selectedDate = DateTime.now();
  double _budget = 500;

  TravelCategory? get selectedCategory => _selectedCategory;
  String get selectedCity => _selectedCity;
  String get duration => _duration;
  DateTime get selectedDate => _selectedDate;
  double get budget => _budget;

  void selectCategory(TravelCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  void setDuration(String duration) {
    _duration = duration;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setBudget(double budget) {
    _budget = budget;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCategory = null;
    notifyListeners();
  }
}
