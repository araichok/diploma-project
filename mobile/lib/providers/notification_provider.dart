import 'package:flutter/material.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void sendRouteGeneratedNotification(String userId, String routeName) {
    addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: 'New Route Generated!',
      message: 'Your route "$routeName" has been created. Check it out!',
      createdAt: DateTime.now(),
    ));
  }

  void clearNotifications() {
    _notifications = [];
    notifyListeners();
  }
}