class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  bool isRead;
  final DateTime createdAt;
  final String? routeId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.routeId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
    'routeId': routeId,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'],
    userId: json['userId'],
    title: json['title'],
    message: json['message'],
    isRead: json['isRead'],
    createdAt: DateTime.parse(json['createdAt']),
    routeId: json['routeId'],
  );
}