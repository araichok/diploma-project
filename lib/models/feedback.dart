class RouteFeedback {
  final String id;
  final String userId;
  final String userName;
  final String routeId;
  final String routeName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  RouteFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.routeId,
    required this.routeName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'routeId': routeId,
    'routeName': routeName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RouteFeedback.fromJson(Map<String, dynamic> json) => RouteFeedback(
    id: json['id'],
    userId: json['userId'],
    userName: json['userName'],
    routeId: json['routeId'],
    routeName: json['routeName'],
    rating: json['rating'],
    comment: json['comment'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}