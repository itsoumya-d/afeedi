import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/navigation_service.dart';
import '../widgets/dashboard/home_tab.dart';
import '../widgets/dashboard/discover_tab.dart';
import '../screens/tabs/shorts_tab.dart';
import '../widgets/dashboard/calendar_tab.dart';
import '../screens/profile_screen.dart';
import '../widgets/common/shared_bottom_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _hasUnreadNotifications = false;

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Home',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'widget': const HomeTab(),
    },
    {
      'title': 'Discover',
      'icon': Icons.explore_outlined,
      'activeIcon': Icons.explore,
      'widget': const DiscoverTab(),
    },
    {
      'title': 'Calendar',
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_today,
      'widget': const CalendarTab(),
    },
    {
      'title': 'Shorts',
      'icon': Icons.video_library_outlined,
      'activeIcon': Icons.video_library,
      'widget': const ShortsTab(),
    },
    {
      'title': 'Profile',
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'widget': const ProfileScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUnreadState();

    // Handle initial tab from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['initialTab'] != null) {
        final initialTab = args['initialTab'] as int;
        _onTabTapped(initialTab);
      }
    });
  }

  Future<void> _loadUnreadState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasUnread = prefs.getBool('has_unread_notifications') ?? true;
    if (mounted) setState(() => _hasUnreadNotifications = hasUnread);
  }

  Future<void> _clearUnreadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_unread_notifications', false);
    if (mounted) setState(() => _hasUnreadNotifications = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0B1E), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: _tabs
                      .map((tab) => tab['widget'] as Widget)
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SharedBottomNavigation(
        currentIndex: _currentIndex,
        onTabChanged: _onTabTapped,
        showFloatingActionButton: true,
      ),
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo/Brand
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 16,
                  ),
                ),
                const Center(
                  child: Text(
                    'Af',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Afeedi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getGreeting(l10n),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Semantics(
            label: 'Search',
            button: true,
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.search);
              },
              tooltip: 'Search',
              icon: const Icon(Icons.search, color: Colors.white, size: 22),
            ),
          ),
          Semantics(
            label: _hasUnreadNotifications
                ? 'Notifications, unread'
                : 'Notifications',
            button: true,
            child: IconButton(
              onPressed: () {
                _clearUnreadState();
                Navigator.pushNamed(context, AppRoutes.notifications);
              },
              tooltip: 'Notifications',
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  if (_hasUnreadNotifications)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryPink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(AppLocalizations? l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n?.goodMorning ?? 'Good morning!';
    } else if (hour < 17) {
      return l10n?.goodAfternoon ?? 'Good afternoon!';
    } else {
      return l10n?.goodEvening ?? 'Good evening!';
    }
  }
}
