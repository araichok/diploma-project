import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as googleMaps;
import '../providers/mood_provider.dart';
import '../providers/route_provider.dart';
import '../widgets/breathing_exercise_card.dart';
import '../models/mood.dart';
import '../models/route.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late googleMaps.GoogleMapController _mapController;
  final Set<googleMaps.Marker> _markers = {};
  final Set<googleMaps.Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMapData();
    });
  }

  void _setupMapData() {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    
    for (var route in routeProvider.generatedRoutes) {
      for (var i = 0; i < route.waypoints.length; i++) {
        _markers.add(
          googleMaps.Marker(
            markerId: googleMaps.MarkerId('${route.id}_$i'),
            position: googleMaps.LatLng(
              route.waypoints[i].latitude,
              route.waypoints[i].longitude,
            ),
            infoWindow: googleMaps.InfoWindow(
              title: route.name,
              snippet: route.activities[i % route.activities.length],
            ),
          ),
        );
      }
      
      if (route.waypoints.length > 1) {
        _polylines.add(
          googleMaps.Polyline(
            polylineId: googleMaps.PolylineId(route.id),
            points: route.waypoints
                .map((wp) => googleMaps.LatLng(wp.latitude, wp.longitude))
                .toList(),
            color: Colors.blue,
            width: 5,
          ),
        );
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Personalized Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (moodProvider.selectedMood != null) {
                routeProvider.generateRoutes(moodProvider.selectedMood!);
                _markers.clear();
                _polylines.clear();
                _setupMapData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          BreathingExerciseCard(
            mood: moodProvider.selectedMood?.displayName ?? 'Adventurous',
          ),
          
          // Map view
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: googleMaps.GoogleMap(
                initialCameraPosition: const googleMaps.CameraPosition(
                  target: googleMaps.LatLng(35.6762, 139.6503),
                  zoom: 12,
                ),
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
          ),
          
          // Routes list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routeProvider.generatedRoutes.length,
              itemBuilder: (context, index) {
                final route = routeProvider.generatedRoutes[index];
                return _buildRouteCard(route, moodProvider.selectedMood);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(TouristRoute route, Mood? mood) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: mood?.color.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              image: DecorationImage(
                image: NetworkImage(route.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          route.rating.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${route.durationHours} hrs',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Activities:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: route.activities.map((activity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: mood?.color.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        activity,
                        style: TextStyle(
                          color: mood?.color ?? Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Est. Cost: \$${route.estimatedCost}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing details for ${route.name}'),
                            backgroundColor: mood?.color ?? Colors.blue,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: mood?.color ?? Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(color: mood?.color ?? Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}