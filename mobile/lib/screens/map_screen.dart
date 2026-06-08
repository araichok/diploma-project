import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../providers/map_provider.dart';
import '../providers/saved_routes_provider.dart';
import '../models/route_stop.dart';
import '../models/saved_route.dart';
import '../services/api_service.dart';
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

  void _maybeShowBeforeMoodPicker(MapProvider mp, Color color) {
    if (_beforeMoodPickerShown) return;
    if (mp.isLoading || mp.routeData == null) return;
    _beforeMoodPickerShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        enableDrag: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _BeforeMoodSheet(
          color: color,
          onSelected: (mood) { mp.beforeMood = mood; Navigator.pop(context); },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MapProvider, MoodProvider>(
      builder: (context, mp, mood, _) {
        final color = mood.selectedCategory?.color ?? Colors.blue;
        _maybeShowBeforeMoodPicker(mp, color);
        return Scaffold(
          appBar: AppBar(
            title: Text(mp.routeData?.routeName ?? 'Your Route',
                style: const TextStyle(fontSize: 16)),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context)),
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          body: _buildBody(context, mp, mood),
        );
      },
    );
  }

  Widget _buildBody(BuildContext ctx, MapProvider mp, MoodProvider mood) {
    if (mp.isLoading) {
      final color = mood.selectedCategory?.color ?? Colors.blue;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: color),
        const SizedBox(height: 20),
        const Text('Generating your route…', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('This may take up to 2 minutes', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ]));
    }
    if (mp.error != null && mp.routeData == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to generate route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(mp.error!, style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back')),
        ],
      )));
    }
    if (mp.routeData == null || mp.sortedStops.isEmpty) {
      if (mp.error == null) {
        return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(), SizedBox(height: 16), Text('Generating your route…'),
        ]));
      }
      return const Center(child: Text('No route data available'));
    }
    return _buildRouteContent(ctx, mp, mood);
  }

  Widget _buildRouteContent(BuildContext ctx, MapProvider mp, MoodProvider mood) {
    final stops = mp.sortedStops;
    final current = mp.currentStop;
    final color = mood.selectedCategory?.color ?? Colors.blue;

    return Column(children: [
      // ── header chips ────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: color.withOpacity(0.1),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Chip(label: Text(mood.selectedCategory?.displayName ?? ''),
              backgroundColor: color, labelStyle: const TextStyle(color: Colors.white, fontSize: 12)),
          Chip(label: Text('Stop ${mp.currentStopIndex + 1} of ${stops.length}'),
              backgroundColor: Colors.grey[200], labelStyle: const TextStyle(fontSize: 12)),
        ]),
      ),

      Expanded(child: Stack(alignment: Alignment.center, children: [
        mp.mapImageBytes != null
            ? InteractiveViewer(minScale: 0.5, maxScale: 4,
                child: Image.memory(mp.mapImageBytes!, fit: BoxFit.contain))
            : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 8),
                Text('Map unavailable', style: TextStyle(color: Colors.grey[600])),
              ])),
        if (mp.isMapRefreshing)
          Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
      ])),

      if (current != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: color.withOpacity(0.08),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: mp.isCompleted ? Colors.green : color,
              radius: 22,
              child: Icon(mp.isCompleted ? Icons.check : Icons.location_on,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mp.isCompleted ? 'Route completed! 🎉' : current.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (!mp.isCompleted && current.address.isNotEmpty)
                Row(children: [
                  const Icon(Icons.place, size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Expanded(child: Text(current.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis)),
                ]),
              if (!mp.isCompleted && (current.estimatedTime > 0 || current.estimatedCost > 0))
                Row(children: [
                  if (current.estimatedTime > 0) ...[
                    const Icon(Icons.schedule, size: 12, color: Colors.blueGrey),
                    const SizedBox(width: 3),
                    Text('${current.estimatedTime} min',
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    const SizedBox(width: 10),
                  ],
                  if (current.estimatedCost > 0) ...[
                    const Icon(Icons.attach_money, size: 12, color: Colors.blueGrey),
                    Text('\$${current.estimatedCost}',
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  ],
                ]),
              if (!mp.isCompleted && !mp.isLastStop)
                Text('Next: ${stops[mp.currentStopIndex + 1].name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ])),
          ]),
        ),

      // ── action buttons ───────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: mp.isCompleted
            ? _completedButtons(ctx, mp, mood)
            : _navButtons(ctx, mp, mood, color),
      ),

      // ── horizontal stops list ────────────────────────────────────────────
      _stopsList(ctx, mp, mood),
    ]);
  }

  Widget _navButtons(BuildContext ctx, MapProvider mp, MoodProvider mood, Color color) {
    final isLast = mp.isLastStop;
    final busy = mp.isMapRefreshing;
    return Row(children: [
      Expanded(child: OutlinedButton.icon(
          onPressed: busy ? null : () => Navigator.pop(ctx),
          icon: const Icon(Icons.arrow_back), label: const Text('Back'))),
      const SizedBox(width: 8),
      Expanded(flex: 2, child: ElevatedButton.icon(
        onPressed: busy ? null : () async {
          if (isLast) await _onComplete(ctx, mp, mood); else await mp.advanceStop();
        },
        icon: busy
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(isLast ? Icons.flag : Icons.navigate_next),
        label: Text(isLast ? 'Complete Route' : 'Next Stop'),
        style: ElevatedButton.styleFrom(
            backgroundColor: isLast ? Colors.green : color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14)),
      )),
    ]);
  }

  Widget _completedButtons(BuildContext ctx, MapProvider mp, MoodProvider mood) {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(
          onPressed: () => _saveRoute(ctx, mp.routeData!, mood),
          icon: const Icon(Icons.save), label: const Text('Save'))),
      const SizedBox(width: 8),
      Expanded(child: ElevatedButton.icon(
        onPressed: () => Navigator.pushReplacement(ctx, MaterialPageRoute(
            builder: (_) => FeedbackScreen(
                routeId: mp.routeData!.routeId, routeName: mp.routeData!.routeName))),
        icon: const Icon(Icons.star), label: const Text('Rate Route'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700], foregroundColor: Colors.white),
      )),
    ]);
  }

  Future<void> _onComplete(BuildContext ctx, MapProvider mp, MoodProvider mood) async {
    final ok = await mp.completeRoute();
    if (!mounted) return;
    if (!ok) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Could not complete route. Try again.'), backgroundColor: Colors.red));
  }

  // ── Horizontal stops strip ─────────────────────────────────────────────────
  Widget _stopsList(BuildContext ctx, MapProvider mp, MoodProvider mood) {
    final stops = mp.sortedStops;
    final color = mood.selectedCategory?.color ?? Colors.blue;
    return Container(
      height: 140,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -4)),
      ]),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        itemCount: stops.length,
        itemBuilder: (_, index) {
          final stop   = stops[index];
          final isDone   = index < mp.currentStopIndex;
          final isActive = index == mp.currentStopIndex;
          return GestureDetector(
            onTap: () => _showStopDetails(ctx, stop, index + 1, isDone, isActive, color, mp),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isDone ? Colors.grey[100] : isActive ? color.withOpacity(0.15) : color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDone ? Colors.grey[300]! : isActive ? color : color.withOpacity(0.25),
                    width: isActive ? 2 : 1),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircleAvatar(
                  backgroundColor: isDone ? Colors.grey : isActive ? color : color.withOpacity(0.5),
                  radius: 14,
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text('${index + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
                const SizedBox(height: 5),
                Text(stop.name,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isDone ? Colors.grey[500] : Colors.black87),
                    textAlign: TextAlign.center, maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (stop.address.isNotEmpty)
                  Text(stop.address,
                      style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showStopDetails(BuildContext ctx, RouteStop stop, int num,
      bool isDone, bool isActive, Color color, MapProvider mp) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StopDetailsSheet(
        stop: stop,
        num: num,
        isDone: isDone,
        isActive: isActive,
        color: color,
        onAddressResolved: (resolvedAddress) {
          mp.updateStopAddress(stop.id, resolvedAddress);
        },
      ),
    );
  }

  void _saveRoute(BuildContext ctx, RouteData routeData, MoodProvider mood) {
    Provider.of<SavedRoutesProvider>(ctx, listen: false).saveRoute(SavedRoute(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routeName: routeData.routeName,
      city: mood.selectedCity,
      category: mood.selectedCategory?.displayName ?? '',
      date: DateTime.now(),
      stops: routeData.stops.map((s) => s.name).toList(),
    ));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Route saved!'), backgroundColor: Colors.green));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Stop Details Sheet — fetches address from Geoapify when missing
// ═════════════════════════════════════════════════════════════════════════════
class _StopDetailsSheet extends StatefulWidget {
  final RouteStop stop;
  final int num;
  final bool isDone;
  final bool isActive;
  final Color color;
  final void Function(String address) onAddressResolved;

  _StopDetailsSheet({
    required this.stop,
    required this.num,
    required this.isDone,
    required this.isActive,
    required this.color,
    required this.onAddressResolved,
  });

  @override
  State<_StopDetailsSheet> createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<_StopDetailsSheet> {
  String _address = '';
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _address = widget.stop.address;
    // If address is missing but we have a placeId, fetch it from Geoapify
    if (_address.isEmpty && widget.stop.placeId.isNotEmpty) {
      _fetchAddress();
    }
  }

  Future<void> _fetchAddress() async {
    setState(() => _loadingAddress = true);
    try {
      final addr = await ApiService().fetchPlaceAddress(widget.stop.placeId);
      if (mounted) {
        setState(() {
          _address = addr;
          _loadingAddress = false;
        });
        if (addr.isNotEmpty) widget.onAddressResolved(addr);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final stop  = widget.stop;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── drag handle ────────────────────────────────────────────────
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // ── stop number + name ─────────────────────────────────────────
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: widget.isDone ? Colors.grey : widget.isActive ? color : color.withOpacity(0.5),
              child: widget.isDone
                  ? const Icon(Icons.check, color: Colors.white)
                  : Text('${widget.num}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(stop.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ]),

          const SizedBox(height: 16),

          // ── address ────────────────────────────────────────────────────
          _DetailRow(
            icon: Icons.place_outlined,
            color: color,
            label: 'Address',
            child: _loadingAddress
                ? Row(children: [
                    SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: color)),
                    const SizedBox(width: 8),
                    Text('Loading address…',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  ])
                : Text(
                    _address.isNotEmpty ? _address : 'Address not available',
                    style: TextStyle(
                        fontSize: 14,
                        color: _address.isNotEmpty ? Colors.grey[800] : Colors.grey[400],
                        fontStyle: _address.isEmpty ? FontStyle.italic : FontStyle.normal),
                  ),
          ),

          if (stop.type.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.category_outlined,
              color: color,
              label: 'Type',
              child: Text(
                _formatType(stop.type),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],

          if (stop.estimatedTime > 0 || stop.estimatedCost > 0) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (stop.estimatedTime > 0) Expanded(child: _DetailRow(
                icon: Icons.schedule_outlined, color: color, label: 'Duration',
                child: Text('${stop.estimatedTime} min',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              )),
              if (stop.estimatedCost > 0) Expanded(child: _DetailRow(
                icon: Icons.payments_outlined, color: color, label: 'Est. cost',
                child: Text('\$${stop.estimatedCost}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              )),
            ]),
          ],

          const SizedBox(height: 20),

          if (widget.isDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.4))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text('Visited', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
              ]),
            )
          else if (widget.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.near_me, size: 16, color: color),
                const SizedBox(width: 6),
                Text('Current stop', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ]),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatType(String raw) {
    final parts = raw.split('.');
    final last = parts.last.replaceAll('_', ' ');
    return last.isEmpty ? raw : last[0].toUpperCase() + last.substring(1);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Widget child;

  const _DetailRow({required this.icon, required this.color,
      required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        child,
      ])),
    ]);
  }
}

class _BeforeMoodSheet extends StatefulWidget {
  final Color color;
  final void Function(int) onSelected;
  const _BeforeMoodSheet({required this.color, required this.onSelected});
  @override State<_BeforeMoodSheet> createState() => _BeforeMoodSheetState();
}
class _BeforeMoodSheetState extends State<_BeforeMoodSheet> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('How are you feeling\nright now?', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Before you start the route', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) {
          final on = _selected == i;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 58, height: 68,
              decoration: BoxDecoration(
                  color: on ? widget.color.withOpacity(0.14) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: on ? widget.color : Colors.grey[300]!, width: on ? 2 : 1)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_moodEmojis[i], style: TextStyle(fontSize: on ? 28 : 22)),
                const SizedBox(height: 3),
                Text(_moodLabels[i], style: TextStyle(fontSize: 9,
                    color: on ? widget.color : Colors.grey[500],
                    fontWeight: on ? FontWeight.bold : FontWeight.normal)),
              ]),
            ),
          );
        })),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Skip', style: TextStyle(color: Colors.grey[500])))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: _selected != null ? () => widget.onSelected(_selected!) : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: widget.color, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text("Let's go!"),
          )),
        ]),
      ]),
    );
  }
}
