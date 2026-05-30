import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'new_content',
      'title': 'New video from Flutter',
      'body': 'Flutter just released "Building Production Apps with Flutter 3"',
      'time': '2 min ago',
      'read': false,
      'icon': Icons.play_circle_filled,
      'color': Color(0xFFFF0000),
    },
    {
      'id': '2',
      'type': 'recommendation',
      'title': 'Recommended for you',
      'body': 'Based on your interests: "Advanced Dart Programming Patterns"',
      'time': '1 hour ago',
      'read': false,
      'icon': Icons.thumb_up_outlined,
      'color': Color(0xFF00D4FF),
    },
    {
      'id': '3',
      'type': 'trending',
      'title': 'Trending now',
      'body': '"Python vs JavaScript in 2024" is trending in your region',
      'time': '3 hours ago',
      'read': true,
      'icon': Icons.trending_up,
      'color': Color(0xFFFF6B6B),
    },
    {
      'id': '4',
      'type': 'achievement',
      'title': 'Achievement unlocked!',
      'body': 'You\'ve watched 5 videos this week. Keep it up!',
      'time': '1 day ago',
      'read': true,
      'icon': Icons.emoji_events,
      'color': Color(0xFFFFD700),
    },
    {
      'id': '5',
      'type': 'new_content',
      'title': 'New from Web Dev Simplified',
      'body': 'Just posted: "CSS Grid vs Flexbox - When to Use Each"',
      'time': '2 days ago',
      'read': true,
      'icon': Icons.play_circle_filled,
      'color': Color(0xFFFF0000),
    },
    {
      'id': '6',
      'type': 'system',
      'title': 'Welcome to Afeedi!',
      'body': 'Start exploring personalized content from your favorite platforms.',
      'time': '3 days ago',
      'read': true,
      'icon': Icons.celebration,
      'color': Color(0xFF7B61FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    AnalyticsService.instance.trackUserInteraction(action: 'screen_view', screen: 'notifications');
    _injectDynamicNotifications();
  }

  Future<void> _injectDynamicNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamicItems = <Map<String, dynamic>>[];

    // Real: saved content count (check SharedPreferences for keys starting with 'saved_')
    final allKeys = prefs.getKeys().where((k) => k.startsWith('saved_')).toList();
    final savedCount = allKeys.where((k) => prefs.getBool(k) == true).length;
    if (savedCount > 0) {
      dynamicItems.add({
        'id': 'dyn_saved',
        'type': 'recommendation',
        'title': 'Your library',
        'body': 'You have $savedCount saved video${savedCount == 1 ? '' : 's'} waiting for you.',
        'time': 'Just now',
        'read': false,
        'icon': Icons.bookmark,
        'color': const Color(0xFF00D4FF),
      });
    }

    // Real: onboarding complete
    final onboarded = prefs.getBool('onboarding_completed') ?? false;
    if (onboarded) {
      final name = prefs.getString('onboarding_user_name') ?? '';
      dynamicItems.add({
        'id': 'dyn_onboard',
        'type': 'system',
        'title': name.isNotEmpty ? 'Welcome, $name!' : 'Your feed is ready',
        'body': 'Your content feed is personalized based on your interests.',
        'time': 'Today',
        'read': true,
        'icon': Icons.celebration,
        'color': const Color(0xFF7B61FF),
      });
    }

    // Real: videos watched
    final watched = prefs.getInt('stat_videos_watched') ?? 0;
    if (watched >= 3) {
      dynamicItems.add({
        'id': 'dyn_watched',
        'type': 'achievement',
        'title': 'Keep watching!',
        'body': 'You\'ve watched $watched video${watched == 1 ? '' : 's'} so far. Keep it up!',
        'time': 'Today',
        'read': false,
        'icon': Icons.emoji_events,
        'color': const Color(0xFFFFD700),
      });
    }

    if (dynamicItems.isNotEmpty && mounted) {
      setState(() {
        // Prepend dynamic notifications before static ones, dedup by id
        final ids = _notifications.map((n) => n['id']).toSet();
        for (final n in dynamicItems.reversed) {
          if (!ids.contains(n['id'])) {
            _notifications.insert(0, n);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    switch (_tabController.index) {
      case 1: return _notifications.where((n) => !n['read']).toList();
      case 2: return _notifications.where((n) => n['type'] == 'recommendation' || n['type'] == 'trending').toList();
      default: return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n['read']).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Flexible(
              child: Text(
                'Notifications',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_unreadCount', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00D4FF),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00D4FF),
          indicatorWeight: 2,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'For You'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          final items = _filteredNotifications;
          if (items.isEmpty) return _buildEmptyState();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1, indent: 72),
            itemBuilder: (ctx, i) => _buildNotificationTile(items[i]),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final isUnread = !(notification['read'] as bool);
    return InkWell(
      onTap: () => _markRead(notification),
      child: Container(
        color: isUnread ? const Color(0xFF00D4FF).withValues(alpha: 0.04) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (notification['color'] as Color).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(notification['icon'] as IconData, color: notification['color'] as Color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] as String,
                          style: TextStyle(
                            color: isUnread ? Colors.white : Colors.white70,
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D4FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['body'] as String,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['time'] as String,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(color: Colors.white54, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const Text(
            "You're all caught up!",
            style: TextStyle(color: Colors.white38, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _markRead(Map<String, dynamic> notification) {
    setState(() => notification['read'] = true);
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n['read'] = true;
      }
    });
  }
}
