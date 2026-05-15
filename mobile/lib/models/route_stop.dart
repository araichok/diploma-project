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

  // Legacy / mock format
  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    id: json['id'].toString(),
    name: json['name'] as String,
    lat: (json['latitude'] ?? json['lat'] ?? 0).toDouble(),
    lng: (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0).toDouble(),
    order: (json['visit_order'] ?? json['order'] ?? 0) as int,
  );

  // Backend format: places[].{id, name, lat, lon, visit_order}
  factory RouteStop.fromBackendJson(Map<String, dynamic> json) => RouteStop(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    lat: (json['lat'] as num? ?? 0).toDouble(),
    lng: (json['lon'] as num? ?? 0).toDouble(),
    order: json['visit_order'] as int? ?? 0,
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

  // Legacy / mock format
  factory RouteData.fromJson(Map<String, dynamic> json) => RouteData(
    routeId: json['routeId'] as String? ?? json['id'] as String? ?? '',
    routeName: json['routeName'] as String? ?? json['name'] as String? ?? '',
    stops: ((json['stops'] ?? json['places']) as List? ?? [])
        .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
        .toList(),
  );

  // Backend format: {id, title, places:[{id, name, lat, lon, visit_order}]}
  factory RouteData.fromBackendJson(Map<String, dynamic> json) => RouteData(
    routeId: json['id'] as String? ?? '',
    routeName: json['title'] as String? ?? '',
    stops: (json['places'] as List? ?? [])
        .map((p) => RouteStop.fromBackendJson(p as Map<String, dynamic>))
        .toList(),
  );
}
