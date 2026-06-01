import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<int> _readIds = {};

  static const _notifications = [
    {
      'id': 1,
      'section': 'TODAY',
      'icon': Icons.trending_up_rounded,
      'iconColor': Color(0xFFFF3C7E),
      'title': 'Trending in Technology',
      'body': 'New content is trending in your interests',
      'time': '2h ago',
    },
    {
      'id': 2,
      'section': 'TODAY',
      'icon': Icons.smart_display_rounded,
      'iconColor': Color(0xFFFF0000),
      'title': 'New videos available',
      'body': 'Fresh content matched to your preferences',
      'time': '5h ago',
    },
    {
      'id': 3,
      'section': 'YESTERDAY',
      'icon': Icons.star_rounded,
      'iconColor': Color(0xFFFFD700),
      'title': 'Weekly digest ready',
      'body': 'Your top picks from this week',
      'time': '1d ago',
    },
    {
      'id': 4,
      'section': 'YESTERDAY',
      'icon': Icons.person_add_rounded,
      'iconColor': Color(0xFF00D4FF),
      'title': 'Discover new creators',
      'body': 'Check out rising stars in gaming',
      'time': '1d ago',
    },
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        _readIds.add(n['id'] as int);
      }
    });
  }

  void _markRead(int id) {
    if (!_readIds.contains(id)) {
      setState(() => _readIds.add(id));
    }
  }

  bool _isUnread(int id) => !_readIds.contains(id);

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => _isUnread(n['id'] as int))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text('Notifications',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: unreadCount > 0 ? _markAllRead : null,
            child: Text('Mark all read',
                style: TextStyle(
                    color: unreadCount > 0
                        ? AppTheme.primaryCyan
                        : Colors.white30,
                    fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _buildSections(),
      ),
    );
  }

  List<Widget> _buildSections() {
    final widgets = <Widget>[];
    String? lastSection;

    for (final n in _notifications) {
      final section = n['section'] as String;
      final id = n['id'] as int;

      if (section != lastSection) {
        if (lastSection != null) widgets.add(const SizedBox(height: 16));
        widgets.add(_NotifSection(title: section));
        lastSection = section;
      }

      widgets.add(_NotifCard(
        icon: n['icon'] as IconData,
        iconColor: n['iconColor'] as Color,
        title: n['title'] as String,
        body: n['body'] as String,
        time: n['time'] as String,
        isUnread: _isUnread(id),
        onTap: () => _markRead(id),
      ));
    }

    return widgets;
  }
}

class _NotifSection extends StatelessWidget {
  final String title;
  const _NotifSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool isUnread;
  final VoidCallback onTap;

  const _NotifCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isUnread
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.03),
          border: Border.all(
            color: isUnread
                ? iconColor.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: iconColor.withOpacity(isUnread ? 0.15 : 0.07),
              ),
              child: Icon(icon,
                  color: isUnread ? iconColor : iconColor.withOpacity(0.4),
                  size: 20),
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
                          title,
                          style: TextStyle(
                            color: isUnread ? Colors.white : Colors.white54,
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(body,
                      style: TextStyle(
                          color: isUnread
                              ? Colors.white54
                              : Colors.white30,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
