import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SharedBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final bool showFloatingActionButton;
  
  const SharedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    this.showFloatingActionButton = true,
  });

  @override
  State<SharedBottomNavigation> createState() => _SharedBottomNavigationState();
}

class _SharedBottomNavigationState extends State<SharedBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  
  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Home',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
    },
    {
      'title': 'Videos',
      'icon': Icons.play_circle_outline,
      'activeIcon': Icons.play_circle,
    },
    {
      'title': 'Calendar',
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_today,
    },
    {
      'title': 'Shorts',
      'icon': Icons.video_library_outlined,
      'activeIcon': Icons.video_library,
    },
    {
      'title': 'Profile',
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Home and Videos
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0), // Home
                        _buildNavItem(1), // Videos
                      ],
                    ),
                  ),
                  // Center: Calendar with FAB
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: widget.showFloatingActionButton 
                          ? const SizedBox(width: 48) // Space for FAB
                          : _buildNavItem(2), // Calendar without FAB
                    ),
                  ),
                  // Right side: Shorts and Profile
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(3), // Shorts
                        _buildNavItem(4), // Profile
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Floating Action Button for Calendar
        if (widget.showFloatingActionButton)
          Positioned(
            top: -24,
            left: MediaQuery.of(context).size.width / 2 - 24,
            child: ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: () => widget.onTabChanged(2), // Calendar tab (now at index 2)
                backgroundColor: AppTheme.primaryPink,
                elevation: 8,
                mini: true,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.currentIndex == 2 
                        ? Icons.calendar_today
                        : Icons.calendar_today_outlined,
                    key: ValueKey(widget.currentIndex == 2),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(int index) {
    if (index >= _tabs.length) return const SizedBox.shrink();
    
    final tab = _tabs[index];
    final isActive = widget.currentIndex == index;
    
    return GestureDetector(
      onTap: () => widget.onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.primaryCyan.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? tab['activeIcon'] : tab['icon'],
                key: ValueKey(isActive),
                color: isActive 
                    ? AppTheme.primaryCyan
                    : Colors.white.withValues(alpha: 0.6),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab['title'],
              style: TextStyle(
                color: isActive 
                    ? AppTheme.primaryCyan
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// Navigation helper class
class NavigationHelper {
  static void navigateToTab(BuildContext context, int tabIndex) {
    // If we're already on the dashboard, just switch tabs
    if (ModalRoute.of(context)?.settings.name == '/dashboard') {
      // This will be handled by the parent widget
      return;
    }
    
    // Otherwise, navigate to dashboard with specific tab
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
      (route) => false,
      arguments: {'initialTab': tabIndex},
    );
  }

  static Widget buildStandardAppBar({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBackButton
          ? Builder(
              builder: (context) => GestureDetector(
                onTap: onBackPressed ?? () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            )
          : null,
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
      ),
    );
  }
}