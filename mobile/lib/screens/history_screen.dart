import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
  late Future<List<_HistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
    _future = _fetchAll(userId);
  }

  Future<List<_HistoryItem>> _fetchAll(String userId) async {
    final entries = await _api.getHistory(userId);
    if (entries.isEmpty) return [];

    // Sort newest first
    entries.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
      final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    // Fetch feedback for completed routes in parallel
    final feedbacks = await Future.wait(
      entries.map((e) async {
        if ((e['status'] ?? '') != 'completed') return <Map<String, dynamic>>[];
        try {
          return await _api.getFeedbackByRoute(e['route_id'] ?? '');
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      }),
    );

    return List.generate(entries.length, (i) {
      final e = entries[i];
      final fb = feedbacks[i];
      double? rating;
      String? comment;
      if (fb.isNotEmpty) {
        rating = (fb.first['rating'] as num?)?.toDouble();
        comment = fb.first['comment'] as String?;
      }
      return _HistoryItem(
        historyId: e['history_id'] ?? '',
        routeId: e['route_id'] ?? '',
        routeName: e['route_name'] ?? 'Unnamed route',
        mood: e['mood'] ?? '',
        status: e['status'] ?? 'planned',
        date: DateTime.tryParse(e['created_at'] ?? ''),
        feedbackRating: rating,
        feedbackComment: comment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _load()),
          ),
        ],
      ),
      body: FutureBuilder<List<_HistoryItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load history',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _load()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No routes yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Text('Your completed walks will appear here',
                      style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _load()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _RouteCard(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryItem {
  final String historyId;
  final String routeId;
  final String routeName;
  final String mood;
  final String status;
  final DateTime? date;
  final double? feedbackRating;
  final String? feedbackComment;

  const _HistoryItem({
    required this.historyId,
    required this.routeId,
    required this.routeName,
    required this.mood,
    required this.status,
    required this.date,
    this.feedbackRating,
    this.feedbackComment,
  });
}

class _RouteCard extends StatelessWidget {
  final _HistoryItem item;
  const _RouteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final completed = item.status == 'completed';
    final statusColor = completed ? Colors.green : Colors.amber[700]!;
    final statusLabel = completed ? 'Completed' : 'Planned';

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: status + date
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        completed ? Icons.check_circle_outline : Icons.schedule,
                        size: 13,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Spacer(),
                if (item.date != null)
                  Text(
                    _formatDate(item.date!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Route name
            Text(
              item.routeName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Mood tag
            if (item.mood.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.mood, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(
                    _capitalize(item.mood),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            // Feedback
            if (item.feedbackRating != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StarRow(rating: item.feedbackRating!),
                  const SizedBox(width: 8),
                  Text(
                    item.feedbackRating!.toStringAsFixed(0),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              if (item.feedbackComment != null &&
                  item.feedbackComment!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.feedbackComment!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: Colors.amber[600],
        );
      }),
    );
  }
}
