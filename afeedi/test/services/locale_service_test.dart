import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afeedi/services/locale_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleService.instance.initialize();
  });

  group('LocaleService — initialization', () {
    test('defaults to English (en) locale', () {
      expect(LocaleService.instance.locale.languageCode, 'en');
    });

    test('has exactly 12 supported languages', () {
      expect(LocaleService.supportedLanguages.length, 12);
    });

    test('supports all required language codes', () {
      final codes = LocaleService.supportedLanguages
          .map((l) => l['code'] as String)
          .toSet();
      for (final code in [
        'en',
        'hi',
        'es',
        'pt',
        'fr',
        'de',
        'ar',
        'id',
        'ja',
        'ko',
        'zh',
        'ru',
      ]) {
        expect(codes, contains(code), reason: 'Missing language code: $code');
      }
    });
  });

  group('LocaleService — language switching', () {
    test('setLocale updates locale to Hindi', () async {
      await LocaleService.instance.setLocale('hi');
      expect(LocaleService.instance.locale.languageCode, 'hi');
    });

    test('setLocale updates locale to Arabic (RTL)', () async {
      await LocaleService.instance.setLocale('ar');
      expect(LocaleService.instance.locale.languageCode, 'ar');
    });

    test('setLocale updates locale to Chinese', () async {
      await LocaleService.instance.setLocale('zh');
      expect(LocaleService.instance.locale.languageCode, 'zh');
    });

    test('setLocale updates locale to Japanese', () async {
      await LocaleService.instance.setLocale('ja');
      expect(LocaleService.instance.locale.languageCode, 'ja');
    });

    test('switching between languages works correctly', () async {
      await LocaleService.instance.setLocale('es');
      expect(LocaleService.instance.locale.languageCode, 'es');
      await LocaleService.instance.setLocale('fr');
      expect(LocaleService.instance.locale.languageCode, 'fr');
      await LocaleService.instance.setLocale('en');
      expect(LocaleService.instance.locale.languageCode, 'en');
    });

    test('setLocale is a no-op when locale is unchanged', () async {
      await LocaleService.instance.setLocale('en');
      expect(LocaleService.instance.locale.languageCode, 'en');
    });
  });

  group('LocaleService — RTL detection', () {
    test('Arabic text direction is RTL', () {
      final isRtl = Bidi.isRtlLanguage('ar');
      expect(isRtl, true);
    });

    test('English text direction is not RTL', () {
      final isRtl = Bidi.isRtlLanguage('en');
      expect(isRtl, false);
    });

    test('Persian/Farsi text direction is RTL', () {
      // Intl Bidi recognizes common RTL language codes
      final isRtl = Bidi.isRtlLanguage('fa');
      expect(isRtl, true);
    });
  });

  group('LocaleService — persistence', () {
    test('locale is restored on re-initialization after setting', () async {
      await LocaleService.instance.setLocale('ko');
      await LocaleService.instance.initialize();
      expect(LocaleService.instance.locale.languageCode, 'ko');
    });

    test(
      'locale is valid after re-initialization with no saved value',
      () async {
        // Reset to English first (tests run against singleton)
        await LocaleService.instance.setLocale('en');
        SharedPreferences.setMockInitialValues({});
        await LocaleService.instance.initialize();
        // No saved value → initialize leaves locale unchanged (already 'en')
        expect(LocaleService.instance.locale.languageCode, 'en');
      },
    );
  });
}
