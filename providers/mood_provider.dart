import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodProvider extends ChangeNotifier {
  Mood? _selectedMood;
  
  Mood? get selectedMood => _selectedMood;
  
  void selectMood(Mood mood) {
    _selectedMood = mood;
    notifyListeners();
  }
}
