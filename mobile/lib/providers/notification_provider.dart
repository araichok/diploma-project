import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadFromBackend(String userId) async {
    try {
      final items = await ApiService().getNotifications(userId);
      _notifications = items.map((n) => AppNotification(
        id: n['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: n['user_id'] as String? ?? userId,
        title: n['type'] as String? ?? 'Notification',
        message: n['message'] as String? ?? '',
        isRead: n['is_read'] as bool? ?? false,
        createdAt: n['created_at'] != null
            ? DateTime.tryParse(n['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      )).toList();
      notifyListeners();
    } catch (_) {}
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

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void clearNotifications() {
    _notifications = [];
    notifyListeners();
  }
}
