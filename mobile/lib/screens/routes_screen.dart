import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import '../models/route.dart';
import '../models/mood.dart';
import 'breathing_exercise_screen.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);
    final routes = routeProvider.generatedRoutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Personalized Routes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routeProvider.location.isNotEmpty 
                      ? routeProvider.location[0].toUpperCase() + routeProvider.location.substring(1).toLowerCase()
                      : 'No Location Selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Breathing Exercise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Take a moment to center yourself with a breathing exercise tailored to your mood',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
      body: routes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No routes generated yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go back and complete your preferences',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Preferences'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                return RouteCard(route: routes[index]);
              },
            ),
    );
  }
}

class RouteCard extends StatelessWidget {
  final TouristRoute route;

  const RouteCard({super.key, required this.route});

  Color _getCityColor(String cityName) {
    final city = cityName.toLowerCase();
    if (city.contains('madrid')) return Colors.red;
    if (city.contains('barcelona')) return Colors.blue;
    if (city.contains('paris')) return Colors.pink;
    if (city.contains('tokyo')) return Colors.orange;
    if (city.contains('rome')) return Colors.purple;
    if (city.contains('london')) return Colors.indigo;
    return Colors.teal;
  }
  
  String _getMoodName(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return 'Happy';
      case Mood.romantic:
        return 'Romantic';
      case Mood.adventurous:
        return 'Adventurous';
      case Mood.thrilling:
        return 'Thrilling & Exciting';
      case Mood.curious:
        return 'Curious';
      case Mood.relaxed:
        return 'Relaxed';
      default:
        return 'Happy';
    }
  }

  @override
  Widget build(BuildContext context) {
    String cityName = route.name.split(' ')[0];
    Color cityColor = _getCityColor(cityName);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cityColor,
                  cityColor.withOpacity(0.7),
                  cityColor.withOpacity(0.4),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCityIcon(cityName),
                        size: 80,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cityName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        route.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            route.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${route.durationHours} hrs',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${route.estimatedCost} USD',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Text(
                  route.description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Activities:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: route.activities.map((activity) {
                    return Chip(
                      label: Text(activity),
                      backgroundColor: cityColor.withOpacity(0.1),
                      labelStyle: TextStyle(fontSize: 12, color: cityColor),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Route Map',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 48, color: cityColor),
                        const SizedBox(height: 8),
                        Text(
                          'Map view with ${route.waypoints.length} points',
                          style: TextStyle(color: cityColor),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            _showRouteDetails(context);
                          },
                          icon: Icon(Icons.location_on, color: cityColor),
                          label: Text(
                            'View Route Details',
                            style: TextStyle(color: cityColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showRouteDetails(context);
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cityColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${route.name} saved to favorites!'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: cityColor,
                            ),
                          );
                        },
                        icon: Icon(Icons.favorite_border, color: cityColor),
                        label: Text('Save', style: TextStyle(color: cityColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cityColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BreathingExerciseScreen(
                            mood: route.mood,
                            location: cityName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.self_improvement),
                    label: const Text('Start Breathing Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCityIcon(String cityName) {
    final city = cityName.toLowerCase();
    if (city.contains('madrid')) return Icons.location_city;
    if (city.contains('barcelona')) return Icons.beach_access;
    if (city.contains('paris')) return Icons.account_balance;
    if (city.contains('tokyo')) return Icons.temple_buddhist;
    if (city.contains('rome')) return Icons.museum;
    if (city.contains('london')) return Icons.castle;
    return Icons.travel_explore;
  }
  
  void _showRouteDetails(BuildContext context) {
    String cityName = route.name.split(' ')[0];
    Color cityColor = _getCityColor(cityName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route.name, style: TextStyle(color: cityColor)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Duration: ${route.durationHours} hours'),
              const SizedBox(height: 8),
              Text('Estimated Cost: \$${route.estimatedCost}'),
              const SizedBox(height: 8),
              Text('Weather: ${route.weatherPreference}'),
              const SizedBox(height: 8),
              Text('Mood: ${_getMoodName(route.mood)}'),
              const SizedBox(height: 8),
              const Text('Route Stops:'),
              const SizedBox(height: 4),
              ...route.waypoints.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(
                    '• Stop ${entry.key + 1}: ${entry.value.latitude.toStringAsFixed(4)}, ${entry.value.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: cityColor)),
          ),
        ],
      ),
    );
  }
}
