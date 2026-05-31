import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF3F51B5); // Indigo
  static const Color primaryLight = Color(0xFF757DE8);
  static const Color primaryDark = Color(0xFF002984);

  // Secondary brand colors
  static const Color secondary = Color(0xFFFF4081); // Pink
  static const Color secondaryLight = Color(0xFFFF79B0);
  static const Color secondaryDark = Color(0xFFC60055);

  // Neutral colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // Platform-specific colors
  static const Map<String, Color> platformColors = {
    'netflix': Color(0xFFE50914),
    'hulu': Color(0xFF1CE783),
    'disney': Color(0xFF113CCF),
    'hbo': Color(0xFF5822B4),
    'amazon': Color(0xFF00A8E1),
    'apple': Color(0xFF000000),
    'youtube': Color(0xFFFF0000),
    'peacock': Color(0xFF110F5E),
    'paramount': Color(0xFF0064FF),
    'other': Color(0xFF607D8B),
  };

  // Get color for a specific platform
  static Color getPlatformColor(String platform) {
    return platformColors[platform.toLowerCase()] ?? platformColors['other']!;
  }

  // Genre colors
  static const Map<String, Color> genreColors = {
    'action': Color(0xFFF44336),
    'comedy': Color(0xFFFFEB3B),
    'drama': Color(0xFF9C27B0),
    'documentary': Color(0xFF4CAF50),
    'horror': Color(0xFF212121),
    'sci-fi': Color(0xFF00BCD4),
    'fantasy': Color(0xFF673AB7),
    'romance': Color(0xFFE91E63),
    'thriller': Color(0xFFFF9800),
    'animation': Color(0xFF8BC34A),
    'other': Color(0xFF607D8B),
  };

  // Get color for a specific genre
  static Color getGenreColor(String genre) {
    return genreColors[genre.toLowerCase()] ?? genreColors['other']!;
  }

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Common color aliases
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color cardBackground = Color(0xFF1A1A2E);
  static const Color shadow = Color(0x33000000);
  static const Color shimmerBase = Color(0xFF252545);
  static const Color shimmerHighlight = Color(0xFF353565);
}
