import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../providers/map_provider.dart';
import '../models/route_stop.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  void _loadRouteData() async {
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    await mapProvider.loadRoute(
      city: moodProvider.selectedCity,
      category: moodProvider.selectedCategory?.name ?? 'happy',
      duration: moodProvider.duration,
      budget: moodProvider.budget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(mapProvider.routeData?.routeName ?? 'Route Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: moodProvider.selectedCategory?.color,
      ),
      body: _buildBody(mapProvider, moodProvider),
    );
  }

  Widget _buildBody(MapProvider mapProvider, MoodProvider moodProvider) {
    if (mapProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final routeData = mapProvider.routeData;
    if (routeData == null || routeData.stops.isEmpty) {
      return const Center(child: Text('No route data available'));
    }
    
    return _buildMap(routeData, moodProvider);
  }

  Widget _buildMap(RouteData routeData, MoodProvider moodProvider) {
    final apiKey = dotenv.env['GEOAPIFY_API_KEY'] ?? '';
    
    // Строим URL для статической карты Geoapify
    final markers = routeData.stops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;
      return '&marker=lonlat:${stop.lng},${stop.lat};color:${_getColorHex(moodProvider)};size:medium;text:${index + 1}';
    }).join('');
    
    final center = 'lonlat:${routeData.stops.first.lng},${routeData.stops.first.lat}';
    
    final imageUrl = 'https://maps.geoapify.com/v1/staticmap?style=osm-bright&width=600&height=600&zoom=13&center=$center$markers&apiKey=$apiKey';
    
    return Column(
      children: [
        // Информация о маршруте
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
        
        // Статическая картинка
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load map'),
                      const SizedBox(height: 8),
                      Text('Error: $error', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        
        // Кнопки действий
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Route saved!')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: moodProvider.selectedCategory?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Список остановок
        Container(
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
                  border: Border.all(color: moodProvider.selectedCategory?.color.withOpacity(0.3) ?? Colors.grey),
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
        ),
      ],
    );
  }
  
  String _getColorHex(MoodProvider moodProvider) {
    final color = moodProvider.selectedCategory?.color ?? Colors.blue;
    return '#${color.value.toRadixString(16).substring(2)}';
  }
}