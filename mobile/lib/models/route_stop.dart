class RouteStop {
  final String id;
  final String placeId;   
  final String name;
  final double lat;
  final double lng;
  final int order;
  final int dayNumber;
  final String address;
  final String type;
  final int estimatedTime;
  final int estimatedCost;

  RouteStop({
    required this.id,
    this.placeId = '',
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
    this.dayNumber = 1,
    this.address = '',
    this.type = '',
    this.estimatedTime = 0,
    this.estimatedCost = 0,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    id:            json['id'].toString(),
    placeId:       json['place_id'] as String? ?? '',
    name:          json['name'] as String? ?? '',
    lat:           (json['latitude'] ?? json['lat'] ?? 0).toDouble(),
    lng:           (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0).toDouble(),
    order:         (json['visit_order'] ?? json['order'] ?? 0) as int,
    dayNumber:     json['day_number'] as int? ?? 1,
    address:       json['address'] as String? ?? '',
    type:          json['type'] as String? ?? '',
    estimatedTime: (json['estimated_time'] as num? ?? 0).toInt(),
    estimatedCost: (json['estimated_cost'] as num? ?? 0).toInt(),
  );

  factory RouteStop.fromBackendJson(Map<String, dynamic> json) => RouteStop(
    id:            json['id']?.toString() ?? '',
    placeId:       json['place_id'] as String? ?? '',
    name:          json['name'] as String? ?? '',
    lat:           (json['lat'] as num? ?? 0).toDouble(),
    lng:           (json['lon'] as num? ?? 0).toDouble(),
    order:         json['visit_order'] as int? ?? 0,
    dayNumber:     json['day_number'] as int? ?? 1,
    address:       json['address'] as String? ?? '',
    type:          json['type'] as String? ?? '',
    estimatedTime: (json['estimated_time'] as num? ?? 0).toInt(),
    estimatedCost: (json['estimated_cost'] as num? ?? 0).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'place_id':       placeId,
    'name':           name,
    'lat':            lat,
    'lng':            lng,
    'visit_order':    order,
    'day_number':     dayNumber,
    'address':        address,
    'type':           type,
    'estimated_time': estimatedTime,
    'estimated_cost': estimatedCost,
  };

  RouteStop withAddress(String addr) => RouteStop(
    id:            id,
    placeId:       placeId,
    name:          name,
    lat:           lat,
    lng:           lng,
    order:         order,
    dayNumber:     dayNumber,
    address:       addr,
    type:          type,
    estimatedTime: estimatedTime,
    estimatedCost: estimatedCost,
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
    routeId:   json['routeId'] as String? ?? json['id'] as String? ?? '',
    routeName: json['routeName'] as String? ?? json['name'] as String? ?? '',
    stops: ((json['stops'] ?? json['places']) as List? ?? [])
        .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
        .toList(),
  );

  factory RouteData.fromBackendJson(Map<String, dynamic> json) => RouteData(
    routeId:   json['id'] as String? ?? '',
    routeName: json['title'] as String? ?? '',
    stops: (json['places'] as List? ?? [])
        .map((p) => RouteStop.fromBackendJson(p as Map<String, dynamic>))
        .toList(),
  );
}
