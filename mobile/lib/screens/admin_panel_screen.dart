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

  // Статистика
  Map<String, dynamic> _stats = {};
  bool _statsLoading = true;
  String? _statsError;

  // Отзывы
  List<dynamic> _feedbacks = [];
  bool _feedbacksLoading = true;
  String? _feedbacksError;

  // Уведомления
  List<dynamic> _notifications = [];
  bool _notificationsLoading = true;
  String? _notificationsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadStats(),
      _loadFeedbacks(),
      _loadNotifications(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final stats = await _api.getAdminStats();
      setState(() {
        _stats = stats;
        _statsError = null;
      });
    } catch (e) {
      setState(() => _statsError = e.toString());
    } finally {
      setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _feedbacksLoading = true);
    try {
      final feedbacks = await _api.getAllFeedbacks();
      setState(() {
        _feedbacks = feedbacks;
        _feedbacksError = null;
      });
    } catch (e) {
      setState(() => _feedbacksError = e.toString());
    } finally {
      setState(() => _feedbacksLoading = false);
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _notificationsLoading = true);
    try {
      final notifications = await _api.getAllNotifications();
      setState(() {
        _notifications = notifications;
        _notificationsError = null;
      });
    } catch (e) {
      setState(() => _notificationsError = e.toString());
    } finally {
      setState(() => _notificationsLoading = false);
    }
  }

  void _showAddAdminDialog() {
    final TextEditingController userIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Admin'),
        content: TextField(
          controller: userIdController,
          decoration: const InputDecoration(hintText: 'User ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = userIdController.text.trim();
              if (userId.isEmpty) return;
              try {
                await _api.addAdmin(userId);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin added'), backgroundColor: Colors.green),
                );
                _loadAllData(); // обновить статистику
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
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('You are not an admin')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
            Tab(icon: Icon(Icons.feedback), text: 'Feedbacks'),
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StatsTab(stats: _stats, isLoading: _statsLoading, error: _statsError),
          _FeedbacksTab(
            feedbacks: _feedbacks,
            isLoading: _feedbacksLoading,
            error: _feedbacksError,
            onAddAdmin: _showAddAdminDialog,
          ),
          _NotificationsTab(
            notifications: _notifications,
            isLoading: _notificationsLoading,
            error: _notificationsError,
          ),
        ],
      ),
    );
  }
}

// ---------- Вкладки ----------
class _StatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;

  const _StatsTab({required this.stats, required this.isLoading, this.error});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    final items = [
      ('Users', stats['total_users'] ?? 0, Icons.people),
      ('Routes', stats['total_routes'] ?? 0, Icons.route),
      ('Feedbacks', stats['total_feedbacks'] ?? 0, Icons.rate_review),
      ('Notifications', stats['total_notifications'] ?? 0, Icons.notifications),
    ];

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: items.map((item) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$3, size: 48, color: Colors.red.shade700),
                const SizedBox(height: 12),
                Text(item.$2.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item.$1, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FeedbacksTab extends StatelessWidget {
  final List<dynamic> feedbacks;
  final bool isLoading;
  final String? error;
  final VoidCallback onAddAdmin;

  const _FeedbacksTab({
    required this.feedbacks,
    required this.isLoading,
    this.error,
    required this.onAddAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: onAddAdmin,
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Make Admin'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));
    if (feedbacks.isEmpty) return const Center(child: Text('No feedbacks yet'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feedbacks.length,
      itemBuilder: (context, i) {
        final f = feedbacks[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Text(f['userName'][0].toUpperCase())),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f['userName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(f['routeName'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (star) {
                        return Icon(
                          star < (f['rating'] as int) ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(f['comment']),
                const SizedBox(height: 8),
                Text(
                  _formatDate(DateTime.parse(f['createdAt'])),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
}

class _NotificationsTab extends StatelessWidget {
  final List<dynamic> notifications;
  final bool isLoading;
  final String? error;

  const _NotificationsTab({required this.notifications, required this.isLoading, this.error});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));
    if (notifications.isEmpty) return const Center(child: Text('No notifications'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, i) {
        final n = notifications[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: n['isRead'] ? Colors.grey.shade200 : Colors.red.shade100,
            child: Icon(Icons.notifications, color: n['isRead'] ? Colors.grey : Colors.red),
          ),
          title: Text(n['title'], style: TextStyle(fontWeight: n['isRead'] ? FontWeight.normal : FontWeight.bold)),
          subtitle: Text(n['message']),
          trailing: Text(_formatTime(DateTime.parse(n['createdAt'])), style: const TextStyle(fontSize: 12)),
          onTap: () {
            // можно пометить прочитанным, если есть API
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}
