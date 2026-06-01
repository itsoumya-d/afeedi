import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and retrieving the user's preferred locale.
///
/// Uses SharedPreferences to store the selected locale language code under
/// the key [_prefsKey]. Falls back to the device default locale when no
/// preference has been saved.
class LocaleService {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const String _prefsKey = 'selected_locale';

  /// All locales supported by Afeedi.
  List<Locale> get supportedLocales => const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('es'), // Spanish
        Locale('pt'), // Portuguese
        Locale('fr'), // French
        Locale('de'), // German
        Locale('ar'), // Arabic (RTL)
        Locale('id'), // Indonesian
        Locale('ja'), // Japanese
        Locale('ko'), // Korean
        Locale('zh'), // Chinese Simplified
        Locale('ru'), // Russian
      ];

  /// Locales that use a right-to-left script.
  List<Locale> get rtlLocales => const [
        Locale('ar'),
      ];

  /// Returns `true` when [locale] uses a right-to-left script.
  bool isRtl(Locale locale) =>
      rtlLocales.any((l) => l.languageCode == locale.languageCode);

  /// Returns the saved locale, or the device default if none has been saved.
  ///
  /// If the saved language code does not match any supported locale the device
  /// default is returned instead.
  Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      final match = supportedLocales.where((l) => l.languageCode == saved);
      if (match.isNotEmpty) return match.first;
    }
    // Fall back to the first locale that overlaps with device settings, or en.
    return const Locale('en');
  }

  /// Persists [locale] so it is restored on the next app launch.
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
