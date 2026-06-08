import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  Map<String, dynamic> _stats = {};
  bool _statsLoading = true;

  List<Map<String, dynamic>> _feedbacks = [];
  bool _feedbacksLoading = true;

  List<Map<String, dynamic>> _notifications = [];
  bool _notificationsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadStats(), _loadFeedbacks(), _loadNotifications()]);
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _statsLoading = true);
    try {
      final stats = await _api.getAdminStats();
      if (mounted) setState(() { _stats = stats; });
    } catch (_) {}
    if (mounted) setState(() => _statsLoading = false);
  }

  Future<void> _loadFeedbacks() async {
    if (!mounted) return;
    setState(() => _feedbacksLoading = true);
    try {
      final list = await _api.getAllFeedbacks();
      if (mounted) setState(() { _feedbacks = list; });
    } catch (_) {}
    if (mounted) setState(() => _feedbacksLoading = false);
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _notificationsLoading = true);
    try {
      final list = await _api.getAllNotifications();
      if (mounted) setState(() { _notifications = list; });
    } catch (_) {}
    if (mounted) setState(() => _notificationsLoading = false);
  }

  void _showAddAdminDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Administrator'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'User ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final userId = ctrl.text.trim();
              if (userId.isEmpty) return;
              try {
                await _api.addAdmin(userId);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin added'), backgroundColor: Colors.green),
                );
                _loadAll();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('You are not an administrator')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Stats'),
            Tab(icon: Icon(Icons.rate_review_outlined), text: 'Feedbacks'),
            Tab(icon: Icon(Icons.notifications_outlined), text: 'Notifications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StatsTab(
            stats: _stats,
            isLoading: _statsLoading,
            feedbackCount: _feedbacks.length,
            notifCount: _notifications.length,
            onAddAdmin: _showAddAdminDialog,
            onRefresh: _loadAll,
          ),
          _FeedbacksTab(
            feedbacks: _feedbacks,
            isLoading: _feedbacksLoading,
          ),
          _NotificationsTab(
            notifications: _notifications,
            isLoading: _notificationsLoading,
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isLoading;
  final int feedbackCount;
  final int notifCount;
  final VoidCallback onAddAdmin;
  final VoidCallback onRefresh;

  const _StatsTab({
    required this.stats,
    required this.isLoading,
    required this.feedbackCount,
    required this.notifCount,
    required this.onAddAdmin,
    required this.onRefresh,
  });

  int _intVal(String key) {
    final v = stats[key];
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final totalUsers  = _intVal('total_users');
    final totalRoutes = _intVal('total_routes');
    final totalFb     = _intVal('total_feedbacks') > 0 ? _intVal('total_feedbacks') : feedbackCount;
    final totalNotifs = _intVal('total_notifications') > 0 ? _intVal('total_notifications') : notifCount;

    final items = [
      _StatItem('Users',         totalUsers,  Icons.people_alt_outlined,   Colors.blue),
      _StatItem('Routes',        totalRoutes, Icons.route_outlined,         Colors.green),
      _StatItem('Feedbacks',     totalFb,     Icons.rate_review_outlined,   Colors.orange),
      _StatItem('Notifications', totalNotifs, Icons.notifications_outlined, Colors.purple),
    ];

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.2,    // taller cards = no overflow
            children: items.map((item) => _StatCard(item: item)).toList(),
          ),

          if (totalUsers == 0 && totalRoutes == 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Users & Routes show 0: the CountUsers/CountRoutes gRPC calls in user-service and route-generation-service are returning errors. Check that both microservices are running and reachable from the API gateway.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: onAddAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Assign New Administrator'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // Use LayoutBuilder so the card adapts to whatever height the grid gives it
      child: LayoutBuilder(builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 24, color: item.color),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.value.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  item.label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FeedbacksTab extends StatelessWidget {
  final List<Map<String, dynamic>> feedbacks;
  final bool isLoading;
  const _FeedbacksTab({required this.feedbacks, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (feedbacks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No feedbacks yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: feedbacks.length,
      itemBuilder: (_, i) {
        final f      = feedbacks[i];
        final rating = (f['rating'] as num?)?.toInt() ?? 0;
        final userId = _short(f['user_id']);
        final routeId = _short(f['route_id']);
        final comment = f['comment'] as String? ?? '';
        final createdAt = f['created_at'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.red.shade100,
                      child: Text(
                        userId.isNotEmpty ? userId[0].toUpperCase() : '?',
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User …$userId',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Route …$routeId',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (s) => Icon(
                        s < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 15,
                        color: Colors.amber,
                      )),
                    ),
                  ],
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(comment, style: const TextStyle(fontSize: 13)),
                ],
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(_fmtDate(createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _short(dynamic v) {
    final s = (v ?? '').toString();
    return s.length > 8 ? s.substring(s.length - 8) : s;
  }

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${d.day}.${d.month}.${d.year}  '
             '${d.hour.toString().padLeft(2, '0')}:'
             '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return raw; }
  }
}

class _NotificationsTab extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  const _NotificationsTab({required this.notifications, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No notifications', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: notifications.length,
      itemBuilder: (_, i) {
        final n      = notifications[i];
        final isRead = n['is_read'] as bool? ?? false;
        final msg    = n['message'] as String? ?? '';
        final type   = n['type'] as String? ?? '';
        final createdAt = n['created_at'] as String? ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isRead ? Colors.grey.shade200 : Colors.red.shade100,
            child: Icon(Icons.notifications,
                color: isRead ? Colors.grey : Colors.red.shade700, size: 20),
          ),
          title: Text(type.isNotEmpty ? type : 'Notification',
              style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
          subtitle: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: createdAt.isNotEmpty
              ? Text(_relTime(createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey))
              : null,
        );
      },
    );
  }

  String _relTime(String raw) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(raw));
      if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)  return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return raw; }
  }
}
