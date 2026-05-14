class RouteStop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int order;

  RouteStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    id: json['id'].toString(),
    name: json['name'],
    lat: (json['latitude'] ?? json['lat']).toDouble(),
    lng: (json['longitude'] ?? json['lng']).toDouble(),
    order: json['order'] ?? 0,
  );
}

class RouteData {
  final String routeId;
  final String routeName;
  final List<RouteStop> stops;

  RouteData({
    required this.routeId,
    required this.routeName,
    required this.stops,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) => RouteData(
    routeId: json['routeId'] ?? json['id'],
    routeName: json['routeName'] ?? json['name'],
    stops: (json['stops'] as List).map((s) => RouteStop.fromJson(s)).toList(),
  );
}