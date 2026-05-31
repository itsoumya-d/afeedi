import 'package:flutter/material.dart';

// Re-export core AppColors with additional colors needed by chat widgets
export '../core/constants/app_colors.dart';

// Additional color constants used by chat/widget components
// These extend the core AppColors with colors not defined there
class AppColors {
  // Primary brand colors (duplicated from core for local use)
  static const Color primary = Color(0xFF3F51B5);
  static const Color secondary = Color(0xFFFF4081);

  // Accent color (alias for secondary)
  static const Color accent = Color(0xFFFF4081);

  // Neutral colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE0E0E0);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
}
