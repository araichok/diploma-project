import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/notification_provider.dart';
import '../models/feedback.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final feedbackProvider = Provider.of<FeedbackProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text('You don\'t have admin access'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: Colors.red.shade700,
              child: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.feedback), text: 'Feedbacks'),
                  Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
                  Tab(icon: Icon(Icons.people), text: 'Stats'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _FeedbacksTab(feedbacks: feedbackProvider.feedbacks),
                  _NotificationsTab(notificationProvider: notificationProvider),
                  _StatsTab(feedbackProvider: feedbackProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbacksTab extends StatelessWidget {
  final List<RouteFeedback> feedbacks;

  const _FeedbacksTab({required this.feedbacks});

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No feedbacks yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        final f = feedbacks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(f.userName[0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            f.routeName,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < f.rating.toInt() ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(f.comment),
                const SizedBox(height: 8),
                Text(
                  _formatDate(f.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }
}

class _NotificationsTab extends StatelessWidget {
  final NotificationProvider notificationProvider;

  const _NotificationsTab({required this.notificationProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (notificationProvider.notifications.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => notificationProvider.markAllAsRead(),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark All as Read'),
            ),
          ),
        Expanded(
          child: notificationProvider.notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notificationProvider.notifications.length,
                  itemBuilder: (context, index) {
                    final n = notificationProvider.notifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: n.isRead ? Colors.grey.shade200 : Colors.red.shade100,
                        child: Icon(Icons.notifications, color: n.isRead ? Colors.grey : Colors.red),
                      ),
                      title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(n.message),
                      trailing: Text(_formatTime(n.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      onTap: () => notificationProvider.markAsRead(n.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _StatsTab extends StatelessWidget {
  final FeedbackProvider feedbackProvider;

  const _StatsTab({required this.feedbackProvider});

  @override
  Widget build(BuildContext context) {
    final allFeedbacks = feedbackProvider.feedbacks;
    final avgRating = allFeedbacks.isEmpty 
        ? 0 
        : allFeedbacks.fold<double>(0, (s, f) => s + f.rating) / allFeedbacks.length;
    
    final ratingDistribution = [0, 0, 0, 0, 0];
    for (var f in allFeedbacks) {
      final index = f.rating.toInt() - 1;
      if (index >= 0 && index < 5) ratingDistribution[index]++;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Average Rating', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < avgRating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text('(${allFeedbacks.length} reviews)', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rating Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...List.generate(5, (i) {
                    final percent = allFeedbacks.isEmpty ? 0 : (ratingDistribution[4 - i] / allFeedbacks.length) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text('${5 - i} ★')),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percent / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.amber,
                            ),
                          ),
                          SizedBox(width: 40, child: Text('${percent.toStringAsFixed(0)}%')),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}