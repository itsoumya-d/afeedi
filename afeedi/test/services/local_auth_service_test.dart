import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afeedi/services/local_auth_service.dart';
import 'package:afeedi/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  late LocalAuthService authService;
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_test');

    // Mock path_provider so Hive.initFlutter() works in tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async => tempDir.path,
        );

    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.initialize();
    await LocalStorageService.instance.clearAllData();
    authService = LocalAuthService.instance;
  });

  group('LocalAuthService Security Tests', () {
    test('signUp stores PBKDF2 hash, not plain text password', () async {
      const email = 'test@example.com';
      const password = 'SecretPassword123';

      final user = await authService.signUp(email: email, password: password);

      expect(user, isNotNull);
      expect(user!.email, email);

      final prefs = await SharedPreferences.getInstance();
      final credentialsJson = prefs.getString('user_credentials_${user.id}');
      expect(credentialsJson, isNotNull);

      final credentials = jsonDecode(credentialsJson!) as Map<String, dynamic>;
      // Verify PBKDF2 format: kdf field, salt, hash — no plain-text password
      expect(
        credentials['kdf'],
        'pbkdf2-sha256',
        reason: 'Should use PBKDF2-SHA256 KDF',
      );
      expect(
        credentials['salt'],
        isNotNull,
        reason: 'Should store a random salt',
      );
      expect(
        credentials['hash'],
        isNotNull,
        reason: 'Should store the PBKDF2 hash',
      );
      expect(
        credentials.containsKey('password'),
        isFalse,
        reason: 'Old plain-text password field must not be present',
      );
      expect(
        credentials['hash'],
        isNot(password),
        reason: 'Hash must not be the plain-text password',
      );
    });

    test(
      'signIn works with correct password and fails with incorrect password',
      () async {
        const email = 'auth@test.com';
        const password = 'CorrectPassword';
        const wrongPassword = 'WrongPassword';

        await authService.signUp(email: email, password: password);

        final signedInUser = await authService.signIn(
          email: email,
          password: password,
        );
        expect(signedInUser, isNotNull);
        expect(signedInUser!.email, email);

        final failedUser = await authService.signIn(
          email: email,
          password: wrongPassword,
        );
        expect(failedUser, isNull);
      },
    );

    test('different passwords produce different PBKDF2 hashes', () async {
      const password1 = 'password123';
      const password2 = 'password456';

      final user1 = await authService.signUp(
        email: 'user1@test.com',
        password: password1,
      );
      final user2 = await authService.signUp(
        email: 'user2@test.com',
        password: password2,
      );

      final prefs = await SharedPreferences.getInstance();
      final creds1 =
          jsonDecode(prefs.getString('user_credentials_${user1!.id}')!)
              as Map<String, dynamic>;
      final creds2 =
          jsonDecode(prefs.getString('user_credentials_${user2!.id}')!)
              as Map<String, dynamic>;

      // Hashes must differ (different passwords + different salts)
      expect(creds1['hash'], isNot(creds2['hash']));
      // Salts must differ (each signup generates a fresh random salt)
      expect(creds1['salt'], isNot(creds2['salt']));
    });

    test(
      'same password with different salts produces different hashes',
      () async {
        const email1 = 'same1@test.com';
        const email2 = 'same2@test.com';
        const samePassword = 'identical_password';

        final user1 = await authService.signUp(
          email: email1,
          password: samePassword,
        );
        final user2 = await authService.signUp(
          email: email2,
          password: samePassword,
        );

        final prefs = await SharedPreferences.getInstance();
        final creds1 =
            jsonDecode(prefs.getString('user_credentials_${user1!.id}')!)
                as Map<String, dynamic>;
        final creds2 =
            jsonDecode(prefs.getString('user_credentials_${user2!.id}')!)
                as Map<String, dynamic>;

        // Same password + different salts → different hashes (prevents rainbow tables)
        expect(creds1['hash'], isNot(creds2['hash']));
      },
    );
  });
}
