import 'package:flutter/material.dart';
import '../../core/responsive/responsive_layout.dart';

class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final List<Map<String, dynamic>> tabs; // {title, icon, activeIcon, widget}
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.tabs,
    this.floatingActionButton,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return _buildWideLayout(context, extended: true);
    }
    if (ResponsiveLayout.isTablet(context)) {
      return _buildWideLayout(context, extended: false);
    }
    // Mobile: just return the current tab content (bottom nav handled externally)
    return tabs[currentIndex]['widget'] as Widget;
  }

  Widget _buildWideLayout(BuildContext context, {required bool extended}) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF1A1A2E),
            selectedIndex: currentIndex,
            extended: extended,
            onDestinationSelected: onTabChanged,
            selectedIconTheme: const IconThemeData(color: Color(0xFF00D4FF)),
            unselectedIconTheme: const IconThemeData(color: Colors.white38),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF00D4FF),
              fontSize: 12,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
            destinations: tabs
                .map(
                  (tab) => NavigationRailDestination(
                    icon: Icon(tab['icon'] as IconData),
                    selectedIcon: Icon(tab['activeIcon'] as IconData),
                    label: Text(tab['title'] as String),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),
          Expanded(child: tabs[currentIndex]['widget'] as Widget),
        ],
      ),
    );
  }
}
