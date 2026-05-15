import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../providers/map_provider.dart';
import '../providers/saved_routes_provider.dart';
import '../models/route_stop.dart';
import '../models/saved_route.dart';
import 'feedback_screen.dart';

const _moodEmojis = ['😞', '😕', '😐', '🙂', '😄'];
const _moodLabels = ['Bad', 'Not great', 'Neutral', 'Good', 'Great'];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _beforeMoodPickerShown = false;

  void _maybeShowBeforeMoodPicker(BuildContext context, MapProvider mapProvider, Color color) {
    if (_beforeMoodPickerShown) return;
    if (mapProvider.isLoading || mapProvider.routeData == null) return;
    _beforeMoodPickerShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        enableDrag: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _BeforeMoodSheet(
          color: color,
          onSelected: (mood) {
            mapProvider.beforeMood = mood;
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final routeData = mapProvider.routeData;
    final color = moodProvider.selectedCategory?.color ?? Colors.blue;

    _maybeShowBeforeMoodPicker(context, mapProvider, color);

    return Scaffold(
      appBar: AppBar(
        title: Text(routeData?.routeName ?? 'Your Route'),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating your route...'),
          ],
        ),
      );
    }

    final routeData = mapProvider.routeData;

    if (mapProvider.error != null && routeData == null) {
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

    if (routeData == null || mapProvider.sortedStops.isEmpty) {
      return const Center(child: Text('No route data available'));
    }

    return _buildRouteContent(mapProvider, moodProvider);
  }

  Widget _buildRouteContent(MapProvider mapProvider, MoodProvider moodProvider) {
    final stops = mapProvider.sortedStops;
    final current = mapProvider.currentStop;
    final color = moodProvider.selectedCategory?.color ?? Colors.blue; // local — needed in helper widgets

    return Column(
      children: [
        // Header chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: color.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Chip(
                label: Text(moodProvider.selectedCategory?.displayName ?? ''),
                backgroundColor: color,
                labelStyle: const TextStyle(color: Colors.white),
              ),
              Chip(
                label: Text(
                  'Stop ${mapProvider.currentStopIndex + 1} of ${stops.length}',
                ),
                backgroundColor: Colors.grey[200],
              ),
            ],
          ),
        ),

        // Map image
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              mapProvider.mapImageBytes != null
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.memory(
                        mapProvider.mapImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('Map unavailable',
                              style: TextStyle(color: Colors.grey[600])),
                          if (mapProvider.error != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                mapProvider.error!,
                                style: const TextStyle(fontSize: 11, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
              // Overlay spinner when refreshing after Next Stop
              if (mapProvider.isMapRefreshing)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),

        // Current stop card
        if (current != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: color.withOpacity(0.08),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: mapProvider.isCompleted
                      ? Colors.green
                      : Colors.amber[700],
                  radius: 20,
                  child: Icon(
                    mapProvider.isCompleted
                        ? Icons.check
                        : Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mapProvider.isCompleted
                            ? 'Route completed!'
                            : 'Now at: ${current.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (!mapProvider.isCompleted &&
                          !mapProvider.isLastStop)
                        Text(
                          'Next: ${stops[mapProvider.currentStopIndex + 1].name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Action buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: mapProvider.isCompleted
              ? _buildCompletedButtons(mapProvider, moodProvider)
              : _buildNavigationButtons(mapProvider, moodProvider, color),
        ),

        // Stops scroll list
        _buildStopsList(mapProvider, moodProvider),
      ],
    );
  }

  Widget _buildNavigationButtons(
    MapProvider mapProvider,
    MoodProvider moodProvider,
    Color color,
  ) {
    final isLast = mapProvider.isLastStop;
    final busy = mapProvider.isMapRefreshing;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    if (isLast) {
                      await _onCompleteRoute(mapProvider, moodProvider);
                    } else {
                      await mapProvider.advanceStop();
                    }
                  },
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isLast ? Icons.flag : Icons.navigate_next),
            label: Text(isLast ? 'Complete Route' : 'Next Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLast ? Colors.green : color,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedButtons(
    MapProvider mapProvider,
    MoodProvider moodProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _saveRouteToHistory(
              mapProvider.routeData!,
              moodProvider,
            ),
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => FeedbackScreen(
                  routeId: mapProvider.routeData!.routeId,
                  routeName: mapProvider.routeData!.routeName,
                ),
              ),
            ),
            icon: const Icon(Icons.star),
            label: const Text('Rate Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onCompleteRoute(
    MapProvider mapProvider,
    MoodProvider moodProvider,
  ) async {
    final success = await mapProvider.completeRoute();
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark route as completed. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStopsList(MapProvider mapProvider, MoodProvider moodProvider) {
    final stops = mapProvider.sortedStops;
    final color = moodProvider.selectedCategory?.color ?? Colors.blue;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: stops.length,
        itemBuilder: (context, index) {
          final stop = stops[index];
          final isDone = index < mapProvider.currentStopIndex;
          final isActive = index == mapProvider.currentStopIndex;
          final bgColor = isDone
              ? Colors.grey[200]!
              : isActive
                  ? color.withOpacity(0.15)
                  : color.withOpacity(0.06);
          final borderColor = isDone
              ? Colors.grey[400]!
              : isActive
                  ? color
                  : color.withOpacity(0.25);
          final avatarColor = isDone
              ? Colors.grey
              : isActive
                  ? color
                  : color.withOpacity(0.5);

          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: avatarColor,
                  radius: 16,
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  stop.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: isDone ? Colors.grey[600] : Colors.black87,
                  ),
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

  void _saveRouteToHistory(RouteData routeData, MoodProvider moodProvider) {
    final savedRoutesProvider =
        Provider.of<SavedRoutesProvider>(context, listen: false);
    savedRoutesProvider.saveRoute(SavedRoute(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routeName: routeData.routeName,
      city: moodProvider.selectedCity,
      category: moodProvider.selectedCategory?.displayName ?? '',
      date: DateTime.now(),
      stops: routeData.stops.map((s) => s.name).toList(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _BeforeMoodSheet extends StatefulWidget {
  final Color color;
  final void Function(int) onSelected;
  const _BeforeMoodSheet({required this.color, required this.onSelected});

  @override
  State<_BeforeMoodSheet> createState() => _BeforeMoodSheetState();
}

class _BeforeMoodSheetState extends State<_BeforeMoodSheet> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How are you feeling\nright now?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Before you start the route',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final on = _selected == i;
              return GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 58,
                  height: 68,
                  decoration: BoxDecoration(
                    color: on
                        ? widget.color.withOpacity(0.14)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: on ? widget.color : Colors.grey[300]!,
                      width: on ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_moodEmojis[i],
                          style: TextStyle(fontSize: on ? 28 : 22)),
                      const SizedBox(height: 3),
                      Text(
                        _moodLabels[i],
                        style: TextStyle(
                          fontSize: 9,
                          color: on ? widget.color : Colors.grey[500],
                          fontWeight: on ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Skip',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _selected != null
                      ? () => widget.onSelected(_selected!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Let's go!"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
