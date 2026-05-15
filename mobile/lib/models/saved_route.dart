class SavedRoute {
  final String id;
  final String routeName;
  final String city;
  final String category;
  final DateTime date;
  final List<String> stops;
  final double rating;
  final String review;

  SavedRoute({
    required this.id,
    required this.routeName,
    required this.city,
    required this.category,
    required this.date,
    required this.stops,
    this.rating = 0,
    this.review = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'routeName': routeName,
    'city': city,
    'category': category,
    'date': date.toIso8601String(),
    'stops': stops,
    'rating': rating,
    'review': review,
  };

  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
    id: json['id'],
    routeName: json['routeName'],
    city: json['city'],
    category: json['category'],
    date: DateTime.parse(json['date']),
    stops: List<String>.from(json['stops']),
    rating: json['rating']?.toDouble() ?? 0,
    review: json['review'] ?? '',
  );
}