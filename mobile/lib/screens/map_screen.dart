import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../providers/map_provider.dart';
import '../models/route_stop.dart';
import 'feedback_screen.dart';
import '../providers/saved_routes_provider.dart';
import '../models/saved_route.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final routeData = mapProvider.routeData;

    return Scaffold(
      appBar: AppBar(
        title: Text(routeData?.routeName ?? 'Your Route'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: moodProvider.selectedCategory?.color,
      ),
      body: _buildBody(mapProvider, moodProvider, routeData),
    );
  }

  Widget _buildBody(
    MapProvider mapProvider,
    MoodProvider moodProvider,
    RouteData? routeData,
  ) {
    if (mapProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (mapProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load route'),
            const SizedBox(height: 8),
            Text(mapProvider.error!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (routeData == null || routeData.stops.isEmpty) {
      return const Center(child: Text('No route data available'));
    }

    return _buildRouteContent(routeData, moodProvider);
  }

  Widget _buildRouteContent(RouteData routeData, MoodProvider moodProvider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: moodProvider.selectedCategory?.color.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Chip(
                label: Text(moodProvider.selectedCategory?.displayName ?? ''),
                backgroundColor: moodProvider.selectedCategory?.color,
                labelStyle: const TextStyle(color: Colors.white),
              ),
              Chip(
                label: Text('${routeData.stops.length} stops'),
                backgroundColor: Colors.grey[200],
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildMapPlaceholder(routeData, moodProvider),
        ),
        _buildBottomButtons(context, routeData, moodProvider),
        _buildStopsList(routeData, moodProvider),
      ],
    );
  }

  // Временное решение – показываем список точек, вместо интерактивной карты
  Widget _buildMapPlaceholder(RouteData routeData, MoodProvider moodProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 80, color: moodProvider.selectedCategory?.color),
          const SizedBox(height: 16),
          const Text('Map view will be here', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('${routeData.stops.length} points', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    RouteData routeData,
    MoodProvider moodProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _saveRouteToHistory(context, routeData, moodProvider),
              icon: const Icon(Icons.save),
              label: const Text('Save Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: moodProvider.selectedCategory?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopsList(RouteData routeData, MoodProvider moodProvider) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: routeData.stops.length,
        itemBuilder: (context, index) {
          final stop = routeData.stops[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: moodProvider.selectedCategory?.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: moodProvider.selectedCategory?.color.withOpacity(0.3) ?? Colors.grey,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: moodProvider.selectedCategory?.color,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Text(
                  stop.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveRouteToHistory(
    BuildContext context,
    RouteData routeData,
    MoodProvider moodProvider,
  ) {
    final savedRoutesProvider = Provider.of<SavedRoutesProvider>(
      context,
      listen: false,
    );
    final savedRoute = SavedRoute(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routeName: routeData.routeName,
      city: moodProvider.selectedCity,
      category: moodProvider.selectedCategory?.displayName ?? '',
      date: DateTime.now(),
      stops: routeData.stops.map((s) => s.name).toList(),
    );
    savedRoutesProvider.saveRoute(savedRoute);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route saved!'), backgroundColor: Colors.green),
    );
  }
}
