import 'package:flutter/material.dart';

/// Utility class for responsive UI scaling across different device sizes
class UIScaling {
  /// Returns a scaled padding value based on screen size
  static double padding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12.0;
    if (width < 600) return 16.0;
    if (width < 900) return 20.0;
    return 24.0;
  }

  /// Returns a scaled spacing value based on screen size and multiplier
  static double spacing(BuildContext context, [double multiplier = 1.0]) {
    final width = MediaQuery.of(context).size.width;
    double baseSpacing = 8.0;
    if (width < 360) baseSpacing = 6.0;
    if (width > 900) baseSpacing = 10.0;
    return baseSpacing * multiplier;
  }

  /// Returns a scaled card height based on screen size
  static double cardHeight(BuildContext context, {bool isLarge = false}) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Adjust card height based on device size
    if (width > 900) return isLarge ? 320.0 : 280.0; // Larger tablets/desktop
    if (width > 600) return isLarge ? 280.0 : 240.0; // Tablets
    if (height < 700) return isLarge ? 220.0 : 180.0; // Small phones
    return isLarge ? 260.0 : 220.0; // Default for phones
  }

  /// Returns a scaled card width based on screen size
  static double cardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Adjust card width based on device size
    if (width > 900) return 220.0; // Larger tablets/desktop
    if (width > 600) return 180.0; // Tablets
    if (width < 360) return 140.0; // Small phones
    return 160.0; // Default for phones
  }

  /// Returns a scaled font size based on screen size and base size
  static double fontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    double scaleFactor = 1.0;

    if (width < 360) scaleFactor = 0.85;
    if (width > 900) scaleFactor = 1.15;

    return baseSize * scaleFactor;
  }

  /// Returns a scaled icon size based on screen size
  static double iconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 20.0;
    if (width > 900) return 28.0;
    return 24.0;
  }

  /// Returns a responsive grid column count based on screen width
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2; // Phones
    if (width < 900) return 3; // Small tablets
    if (width < 1200) return 4; // Tablets
    if (width < 1800) return 5; // Small desktops
    return 6; // Large desktops
  }

  static double radius(BuildContext context, [double base = 12.0]) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return base * 0.85;
    if (width > 900) return base * 1.25;
    return base;
  }
}
