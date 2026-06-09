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


String _fmtDuration(int hours) {
  if (hours <= 0) return '';
  return hours == 1 ? '1 hr' : '$hours hrs';
}

List<List<RouteStop>> _groupByDay(List<RouteStop> stops) {
  const hoursPerDay = 8;
  final days = <List<RouteStop>>[];
  var day = <RouteStop>[];
  var used = 0;
  for (final s in stops) {
    final h = s.estimatedTime > 0 ? s.estimatedTime : 1;
    if (day.isNotEmpty && used + h > hoursPerDay) {
      days.add(day);
      day = [];
      used = 0;
    }
    day.add(s);
    used += h;
  }
  if (day.isNotEmpty) days.add(day);
  return days;
}

int _dayOf(List<RouteStop> all, int idx) {
  const hoursPerDay = 8;
  var day = 1;
  var used = 0;
  for (int i = 0; i <= idx && i < all.length; i++) {
    final h = all[i].estimatedTime > 0 ? all[i].estimatedTime : 1;
    if (i > 0 && used + h > hoursPerDay) { day++; used = 0; }
    used += h;
  }
  return day;
}


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
            actions: [
              if (mp.routeData != null && mp.sortedStops.isNotEmpty)
                IconButton(
                  tooltip: 'Day schedule',
                  icon: const Icon(Icons.calendar_view_day_outlined),
                  onPressed: () => _showSchedule(context, mp, mood, color),
                ),
            ],
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
        const Text('Generating your route…',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('This may take up to 2 minutes',
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ]));
    }
    if (mp.error != null && mp.routeData == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to generate route',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(mp.error!, style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back')),
        ]),
      ));
    }
    if (mp.routeData == null || mp.sortedStops.isEmpty) {
      if (mp.error == null) {
        return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(), SizedBox(height: 16), Text('Generating your route…'),
        ]));
      }
      return const Center(child: Text('No route data available'));
    }
    return _buildContent(ctx, mp, mood);
  }

  Widget _buildContent(BuildContext ctx, MapProvider mp, MoodProvider mood) {
    final stops   = mp.sortedStops;
    final current = mp.currentStop;
    final color   = mood.selectedCategory?.color ?? Colors.blue;
    final days    = _groupByDay(stops);
    final currentDay = _dayOf(stops, mp.currentStopIndex);

    return Column(children: [

      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: color.withOpacity(0.1),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Chip(
            label: Text(mood.selectedCategory?.displayName ?? ''),
            backgroundColor: color,
            labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Chip(
            label: Text('Stop ${mp.currentStopIndex + 1}/${stops.length}'),
            backgroundColor: Colors.grey[200],
            labelStyle: const TextStyle(fontSize: 12),
          ),
          if (days.length > 1)
            Chip(
              avatar: Icon(Icons.wb_sunny_outlined, size: 13,
                  color: Colors.white.withOpacity(0.9)),
              label: Text('Day $currentDay/${days.length}'),
              backgroundColor: color.withOpacity(0.8),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
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
          Container(color: Colors.black26,
              child: const Center(child: CircularProgressIndicator())),
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
                    // ✅ FIX: hours not minutes
                    Text(_fmtDuration(current.estimatedTime),
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

      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: mp.isCompleted
            ? _completedButtons(ctx, mp, mood)
            : _navButtons(ctx, mp, mood, color),
      ),

      // ── Horizontal stops strip with day separators ────────────────────
      _stopsList(ctx, mp, mood, days),
    ]);
  }

  Widget _navButtons(BuildContext ctx, MapProvider mp, MoodProvider mood, Color color) {
    final isLast = mp.isLastStop;
    final busy   = mp.isMapRefreshing;
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
                routeId: mp.routeData!.routeId,
                routeName: mp.routeData!.routeName))),
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
        content: Text('Could not complete route. Try again.'),
        backgroundColor: Colors.red));
  }

  Widget _stopsList(BuildContext ctx, MapProvider mp, MoodProvider mood,
      List<List<RouteStop>> days) {
    final stops    = mp.sortedStops;
    final color    = mood.selectedCategory?.color ?? Colors.blue;
    final multiDay = days.length > 1;

    final items = <_StripItem>[];
    int g = 0;
    for (int d = 0; d < days.length; d++) {
      if (multiDay) items.add(_StripItem.header(d + 1));
      for (final s in days[d]) { items.add(_StripItem.stop(s, g++)); }
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, -4)),
      ]),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          if (item.isHeader) {
            return Container(
              width: 52,
              margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(20)),
                child: Text('Day\n${item.day}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.bold, height: 1.2)),
              ),
            );
          }

          final stop    = item.stop!;
          final idx     = item.globalIndex;
          final isDone  = idx < mp.currentStopIndex;
          final isNow   = idx == mp.currentStopIndex;

          return GestureDetector(
            onTap: () => _showStopDetails(ctx, stop, idx + 1, isDone, isNow, color, mp),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDone ? Colors.grey[100] : isNow
                    ? color.withOpacity(0.15) : color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDone ? Colors.grey[300]! : isNow
                        ? color : color.withOpacity(0.25),
                    width: isNow ? 2 : 1),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircleAvatar(
                  backgroundColor: isDone ? Colors.grey
                      : isNow ? color : color.withOpacity(0.5),
                  radius: 13,
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : Text('${idx + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
                const SizedBox(height: 4),
                Text(stop.name,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                        color: isDone ? Colors.grey[500] : Colors.black87),
                    textAlign: TextAlign.center, maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                // ✅ FIX: hours not minutes in strip card
                if (stop.estimatedTime > 0)
                  Text(_fmtDuration(stop.estimatedTime),
                      style: TextStyle(fontSize: 9, color: Colors.grey[400])),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showSchedule(BuildContext ctx, MapProvider mp, MoodProvider mood, Color color) {
    final stops = mp.sortedStops;
    final days  = _groupByDay(stops);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              Icon(Icons.calendar_view_day_outlined, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                'Schedule — ${days.length} day${days.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: days.length,
              itemBuilder: (_, di) {
                final dayStops = days[di];
                final dayHours = dayStops.fold<int>(
                    0, (s, st) => s + (st.estimatedTime > 0 ? st.estimatedTime : 1));
                int startG = 0;
                for (int d = 0; d < di; d++) startG += days[d].length;

                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (di > 0) const SizedBox(height: 16),
                  // Day header bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.wb_sunny_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text('Day ${di + 1}',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      Text(
                        '${dayStops.length} stop${dayStops.length > 1 ? 's' : ''}'
                        ' · ${_fmtDuration(dayHours)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  // Stop rows with timeline
                  ...dayStops.asMap().entries.map((e) {
                    final li   = e.key;
                    final stop = e.value;
                    final gi   = startG + li;
                    final done = gi < mp.currentStopIndex;
                    final now  = gi == mp.currentStopIndex;
                    final last = li == dayStops.length - 1;

                    return IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        // Timeline
                        SizedBox(width: 40, child: Column(children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: done ? Colors.grey[300]
                                : now ? color : color.withOpacity(0.25),
                            child: done
                                ? Icon(Icons.check, size: 14, color: Colors.grey[600])
                                : Text('${gi + 1}',
                                    style: TextStyle(
                                        color: now ? Colors.white : color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                          ),
                          if (!last)
                            Expanded(child: Container(
                                width: 2, color: color.withOpacity(0.2))),
                        ])),
                        const SizedBox(width: 12),
                        // Card
                        Expanded(child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showStopDetails(
                                ctx, stop, gi + 1, done, now, color, mp);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: now ? color.withOpacity(0.08) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: now ? color.withOpacity(0.4) : Colors.grey[200]!,
                                  width: now ? 1.5 : 1),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(stop.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: done ? Colors.grey[500] : Colors.black87),
                                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                                if (now)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: color, borderRadius: BorderRadius.circular(10)),
                                    child: const Text('Now',
                                        style: TextStyle(color: Colors.white,
                                            fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                if (done)
                                  Icon(Icons.check_circle_outline,
                                      size: 16, color: Colors.grey[400]),
                              ]),
                              const SizedBox(height: 4),
                              Row(children: [
                                if (stop.type.isNotEmpty) ...[
                                  Icon(Icons.category_outlined,
                                      size: 11, color: Colors.grey[400]),
                                  const SizedBox(width: 3),
                                  Text(_fmtType(stop.type),
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[500])),
                                  const SizedBox(width: 10),
                                ],
                                if (stop.estimatedTime > 0) ...[
                                  Icon(Icons.schedule_outlined,
                                      size: 11, color: Colors.grey[400]),
                                  const SizedBox(width: 3),
                                  // ✅ FIX: hours in schedule sheet
                                  Text(_fmtDuration(stop.estimatedTime),
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[500])),
                                ],
                                if (stop.estimatedCost > 0) ...[
                                  const SizedBox(width: 10),
                                  Icon(Icons.payments_outlined,
                                      size: 11, color: Colors.grey[400]),
                                  const SizedBox(width: 2),
                                  Text('\$${stop.estimatedCost}',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[500])),
                                ],
                              ]),
                              if (stop.address.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(children: [
                                  Icon(Icons.place_outlined,
                                      size: 11, color: Colors.grey[400]),
                                  const SizedBox(width: 3),
                                  Expanded(child: Text(stop.address,
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[500]),
                                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ]),
                              ],
                            ]),
                          ),
                        )),
                      ]),
                    );
                  }),
                ]);
              },
            ),
          ),
        ]),
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
        dayLabel: _groupByDay(mp.sortedStops).length > 1
            ? 'Day ${_dayOf(mp.sortedStops, num - 1)}'
            : null,
        onAddressResolved: (addr) => mp.updateStopAddress(stop.id, addr),
      ),
    );
  }

  void _saveRoute(BuildContext ctx, RouteData routeData, MoodProvider mood) {
    Provider.of<SavedRoutesProvider>(ctx, listen: false).saveRoute(SavedRoute(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      routeName: routeData.routeName,
      city:      mood.selectedCity,
      category:  mood.selectedCategory?.displayName ?? '',
      date:      DateTime.now(),
      stops:     routeData.stops.map((s) => s.name).toList(),
    ));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Route saved!'), backgroundColor: Colors.green));
  }

  static String _fmtType(String raw) {
    final last = raw.split('.').last.replaceAll('_', ' ');
    return last.isEmpty ? raw : last[0].toUpperCase() + last.substring(1);
  }
}

// ─── Strip item ───────────────────────────────────────────────────────────────
class _StripItem {
  final bool      isHeader;
  final int       day;
  final RouteStop? stop;
  final int       globalIndex;
  _StripItem.header(this.day) : isHeader = true, stop = null, globalIndex = -1;
  _StripItem.stop(this.stop, this.globalIndex) : isHeader = false, day = -1;
}

// ═══════════════════════════════════════════════════════════════════
// Stop Details Sheet
// Shows address, type, HOURS duration, cost, day number, visited/current badge
// ═══════════════════════════════════════════════════════════════════
class _StopDetailsSheet extends StatefulWidget {
  final RouteStop stop;
  final int num;
  final bool isDone;
  final bool isActive;
  final Color color;
  final String? dayLabel;   // e.g. "Day 2" — null for single-day routes
  final void Function(String) onAddressResolved;

  _StopDetailsSheet({
    required this.stop,
    required this.num,
    required this.isDone,
    required this.isActive,
    required this.color,
    required this.dayLabel,
    required this.onAddressResolved,
  });

  @override
  State<_StopDetailsSheet> createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<_StopDetailsSheet> {
  String _address     = '';
  bool   _loadingAddr = false;

  @override
  void initState() {
    super.initState();
    _address = widget.stop.address;
    if (_address.isEmpty && widget.stop.placeId.isNotEmpty) _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    setState(() => _loadingAddr = true);
    try {
      final addr = await ApiService().fetchPlaceAddress(widget.stop.placeId);
      if (mounted) {
        setState(() { _address = addr; _loadingAddr = false; });
        if (addr.isNotEmpty) widget.onAddressResolved(addr);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAddr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final stop  = widget.stop;

    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Drag handle
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),

        // Stop number + name
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: widget.isDone ? Colors.grey
                : widget.isActive ? color : color.withOpacity(0.5),
            child: widget.isDone
                ? const Icon(Icons.check, color: Colors.white)
                : Text('${widget.num}',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stop.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // ✅ Day label shown directly under the name
            if (widget.dayLabel != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wb_sunny_outlined, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(widget.dayLabel!,
                      style: TextStyle(fontSize: 12, color: color,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
          ])),
        ]),
        const SizedBox(height: 16),

        // Address
        _DetailRow(
          icon: Icons.place_outlined, color: color, label: 'Address',
          child: _loadingAddr
              ? Row(children: [
                  SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color)),
                  const SizedBox(width: 8),
                  Text('Loading…', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ])
              : Text(_address.isNotEmpty ? _address : 'Address not available',
                  style: TextStyle(fontSize: 14,
                      color: _address.isNotEmpty ? Colors.grey[800] : Colors.grey[400],
                      fontStyle: _address.isEmpty ? FontStyle.italic : FontStyle.normal)),
        ),

        // Type
        if (stop.type.isNotEmpty) ...[
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.category_outlined, color: color, label: 'Type',
            child: Text(_fmtType(stop.type),
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ),
        ],

        // Duration + Cost
        if (stop.estimatedTime > 0 || stop.estimatedCost > 0) ...[
          const SizedBox(height: 10),
          Row(children: [
            if (stop.estimatedTime > 0) Expanded(child: _DetailRow(
              icon: Icons.schedule_outlined, color: color, label: 'Duration',
              // ✅ FIX: hours not minutes
              child: Text(_fmtDuration(stop.estimatedTime),
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

        // Status badge
        if (widget.isDone)
          _StatusChip(label: 'Visited', icon: Icons.check_circle_outline,
              color: Colors.green)
        else if (widget.isActive)
          _StatusChip(label: 'Current stop', icon: Icons.near_me, color: color),

        const SizedBox(height: 8),
      ]),
    );
  }

  static String _fmtType(String raw) {
    final last = raw.split('.').last.replaceAll('_', ' ');
    return last.isEmpty ? raw : last[0].toUpperCase() + last.substring(1);
  }
}

class _StatusChip extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _StatusChip({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon; final Color color;
  final String label; final Widget child;
  const _DetailRow({required this.icon, required this.color,
      required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500],
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        child,
      ])),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// Before-mood sheet
// ═══════════════════════════════════════════════════════════════════
class _BeforeMoodSheet extends StatefulWidget {
  final Color color;
  final void Function(int) onSelected;
  const _BeforeMoodSheet({required this.color, required this.onSelected});
  @override State<_BeforeMoodSheet> createState() => _BeforeMoodSheetState();
}
class _BeforeMoodSheetState extends State<_BeforeMoodSheet> {
  int? _selected;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(
          color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 20),
      const Text('How are you feeling\nright now?', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text('Before you start the route',
          style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final on = _selected == i;
            return GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 58, height: 68,
                decoration: BoxDecoration(
                    color: on ? widget.color.withOpacity(0.14) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: on ? widget.color : Colors.grey[300]!,
                        width: on ? 2 : 1)),
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
