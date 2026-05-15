import 'package:flutter/material.dart';
import '../models/feedback.dart';
import '../services/api_service.dart';

class FeedbackProvider extends ChangeNotifier {
  List<RouteFeedback> _feedbacks = [];

  List<RouteFeedback> get feedbacks => _feedbacks;

  List<RouteFeedback> getRouteFeedbacks(String routeId) =>
      _feedbacks.where((f) => f.routeId == routeId).toList();

  double getAverageRating(String routeId) {
    final list = getRouteFeedbacks(routeId);
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (s, f) => s + f.rating) / list.length;
  }

  bool hasUserFeedback(String userId, String routeId) =>
      _feedbacks.any((f) => f.userId == userId && f.routeId == routeId);

  RouteFeedback? getUserFeedback(String userId, String routeId) {
    try {
      return _feedbacks.firstWhere((f) => f.userId == userId && f.routeId == routeId);
    } catch (_) {
      return null;
    }
  }

  // Sends to backend and updates local cache for immediate UI update
  Future<bool> submitFeedback({
    required String userId,
    required String userName,
    required String routeId,
    required String routeName,
    required double rating,
    required String comment,
  }) async {
    try {
      await ApiService().submitFeedback(
        userId: userId,
        routeId: routeId,
        rating: rating.round(),
        comment: comment.isEmpty ? 'No comment' : comment,
      );
      _feedbacks.insert(0, RouteFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        routeId: routeId,
        routeName: routeName,
        rating: rating,
        comment: comment.isEmpty ? 'No comment' : comment,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
