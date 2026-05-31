import 'package:flutter/material.dart';

/// Breakpoints following Material Design guidelines.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 905;
  static const double desktop = 1240;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.mobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.mobile &&
      MediaQuery.of(context).size.width < Breakpoints.tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet;
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= Breakpoints.desktop) return 4;
    if (w >= Breakpoints.tablet) return 3;
    if (w >= Breakpoints.mobile) return 2;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.tablet && desktop != null) return desktop!;
    if (width >= Breakpoints.mobile && tablet != null) return tablet!;
    return mobile;
  }
}
