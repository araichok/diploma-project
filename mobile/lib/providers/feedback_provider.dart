import 'package:flutter/material.dart';
import '../models/feedback.dart';

class FeedbackProvider extends ChangeNotifier {
  List<RouteFeedback> _feedbacks = [];

  List<RouteFeedback> get feedbacks => _feedbacks;
  
  List<RouteFeedback> getRouteFeedbacks(String routeId) {
    return _feedbacks.where((f) => f.routeId == routeId).toList();
  }

  double getAverageRating(String routeId) {
    final routeFeedbacks = getRouteFeedbacks(routeId);
    if (routeFeedbacks.isEmpty) return 0;
    final sum = routeFeedbacks.fold<double>(0, (s, f) => s + f.rating);
    return sum / routeFeedbacks.length;
  }

  void addFeedback(RouteFeedback feedback) {
    _feedbacks.insert(0, feedback);
    notifyListeners();
  }

  bool hasUserFeedback(String userId, String routeId) {
    return _feedbacks.any((f) => f.userId == userId && f.routeId == routeId);
  }

  RouteFeedback? getUserFeedback(String userId, String routeId) {
    try {
      return _feedbacks.firstWhere((f) => f.userId == userId && f.routeId == routeId);
    } catch (e) {
      return null;
    }
  }
}