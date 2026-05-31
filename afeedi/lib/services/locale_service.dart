import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._();
  LocaleService._();

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  static const _prefKey = 'app_locale';

  static const List<Map<String, dynamic>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇺🇸'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español', 'flag': '🇪🇸'},
    {
      'code': 'pt',
      'name': 'Portuguese',
      'nativeName': 'Português',
      'flag': '🇧🇷',
    },
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية', 'flag': '🇸🇦'},
    {
      'code': 'id',
      'name': 'Indonesian',
      'nativeName': 'Bahasa Indonesia',
      'flag': '🇮🇩',
    },
    {'code': 'ja', 'name': 'Japanese', 'nativeName': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': 'Korean', 'nativeName': '한국어', 'flag': '🇰🇷'},
    {
      'code': 'zh',
      'name': 'Chinese (Simplified)',
      'nativeName': '简体中文',
      'flag': '🇨🇳',
    },
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский', 'flag': '🇷🇺'},
  ];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
    notifyListeners();
  }
}
