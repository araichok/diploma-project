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

enum DurationUnit { hours, days }

class MoodProvider extends ChangeNotifier {
  TravelCategory? _selectedCategory;
  String _selectedCity = '';
  int _durationHours = 2;
  DurationUnit _durationUnit = DurationUnit.hours;
  DateTime _selectedDate = DateTime.now();
  double _budget = 500;

  TravelCategory? get selectedCategory => _selectedCategory;
  String get selectedCity => _selectedCity;
  DateTime get selectedDate => _selectedDate;
  double get budget => _budget;
  int get durationHours => _durationHours;
  DurationUnit get durationUnit => _durationUnit;

  String get duration => '$_durationHours часов';

  String get durationDisplay {
    if (_durationUnit == DurationUnit.hours) {
      return '$_durationHours ${_hoursLabel(_durationHours)}';
    } else {
      final days = (_durationHours / 24).round().clamp(1, 30);
      return '$days ${_daysLabel(days)}';
    }
  }

  String _hoursLabel(int n) {
    if (n == 1) return 'час';
    if (n >= 2 && n <= 4) return 'часа';
    return 'часов';
  }

  String _daysLabel(int n) {
    if (n == 1) return 'день';
    if (n >= 2 && n <= 4) return 'дня';
    return 'дней';
  }

  void selectCategory(TravelCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  void setDuration(String duration) {
    final hours = int.tryParse(duration.split(' ').first) ?? 2;
    _durationHours = hours;
    notifyListeners();
  }

  void setDurationHours(int hours) {
    _durationHours = hours.clamp(1, 720); 
    notifyListeners();
  }

  void setDurationUnit(DurationUnit unit) {
    if (_durationUnit == unit) return;
    if (unit == DurationUnit.days) {
      final days = (_durationHours / 24).ceil().clamp(1, 30);
      _durationHours = days * 24;
    } else {
      final days = (_durationHours / 24).round().clamp(1, 30);
      _durationHours = days; 
      if (_durationHours > 24) _durationHours = 24;
    }
    _durationUnit = unit;
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
