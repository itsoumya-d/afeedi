import 'package:flutter/material.dart';
import '../../services/navigation_service.dart';
import '../../core/theme/app_theme.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _QuickActionCard(
              icon: Icons.add_circle_outline,
              title: 'Create Content',
              subtitle: 'Share your thoughts',
              gradient: const LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => NavigationService.pushNamed(AppRoutes.createContent),
            ),
            _QuickActionCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Check updates',
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPink, AppTheme.accentOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => NavigationService.pushNamed(AppRoutes.notifications),
            ),
            _QuickActionCard(
              icon: Icons.calendar_today_outlined,
              title: 'Schedule',
              subtitle: 'Plan your day',
              gradient: const LinearGradient(
                colors: [AppTheme.accentOrange, AppTheme.accentPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => NavigationService.pushNamed(AppRoutes.calendar),
            ),
            _QuickActionCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Customize app',
              gradient: const LinearGradient(
                colors: [AppTheme.accentPurple, AppTheme.primaryCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => NavigationService.pushNamed(AppRoutes.settings),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
