import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read',
                style:
                    TextStyle(color: AppTheme.primaryCyan, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: const [
          _NotifSection(title: 'TODAY'),
          _NotifCard(
            icon: Icons.trending_up_rounded,
            iconColor: Color(0xFFFF3C7E),
            title: 'Trending in Technology',
            body: 'New content is trending in your interests',
            time: '2h ago',
            isUnread: true,
          ),
          _NotifCard(
            icon: Icons.smart_display_rounded,
            iconColor: Color(0xFFFF0000),
            title: 'New videos available',
            body: 'Fresh content matched to your preferences',
            time: '5h ago',
            isUnread: true,
          ),
          SizedBox(height: 16),
          _NotifSection(title: 'YESTERDAY'),
          _NotifCard(
            icon: Icons.star_rounded,
            iconColor: Color(0xFFFFD700),
            title: 'Weekly digest ready',
            body: 'Your top picks from this week',
            time: '1d ago',
            isUnread: false,
          ),
          _NotifCard(
            icon: Icons.person_add_rounded,
            iconColor: Color(0xFF00D4FF),
            title: 'Discover new creators',
            body: 'Check out rising stars in gaming',
            time: '1d ago',
            isUnread: false,
          ),
        ],
      ),
    );
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

  const _NotifCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: iconColor.withOpacity(0.15),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                          color:
                              isUnread ? Colors.white : Colors.white70,
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
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(time,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
