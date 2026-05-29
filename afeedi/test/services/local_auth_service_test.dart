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
    test('signUp hashes password and it is not stored in plain text', () async {
      const email = 'test@example.com';
      const password = 'SecretPassword123';

      final user = await authService.signUp(email: email, password: password);

      expect(user, isNotNull);
      expect(user!.email, email);

      final prefs = await SharedPreferences.getInstance();
      final credentialsJson = prefs.getString('user_credentials_${user.id}');
      expect(credentialsJson, isNotNull);

      final credentials = jsonDecode(credentialsJson!) as Map<String, dynamic>;
      expect(credentials['password'], isNot(password),
          reason: 'Password should be hashed, not plain text');
      expect(credentials['password'].toString().length, 64,
          reason: 'SHA-256 hash should be 64 characters long');
    });

    test('signIn works with correct password and fails with incorrect password',
        () async {
      const email = 'auth@test.com';
      const password = 'CorrectPassword';
      const wrongPassword = 'WrongPassword';

      await authService.signUp(email: email, password: password);

      final signedInUser =
          await authService.signIn(email: email, password: password);
      expect(signedInUser, isNotNull);
      expect(signedInUser!.email, email);

      final failedUser =
          await authService.signIn(email: email, password: wrongPassword);
      expect(failedUser, isNull);
    });

    test('different passwords result in different hashes', () async {
      const password1 = 'password123';
      const password2 = 'password456';

      final user1 =
          await authService.signUp(email: 'user1@test.com', password: password1);
      final user2 =
          await authService.signUp(email: 'user2@test.com', password: password2);

      final prefs = await SharedPreferences.getInstance();
      final creds1 = jsonDecode(
              prefs.getString('user_credentials_${user1!.id}')!) as Map<String, dynamic>;
      final creds2 = jsonDecode(
              prefs.getString('user_credentials_${user2!.id}')!) as Map<String, dynamic>;

      expect(creds1['password'], isNot(creds2['password']));
    });
  });
}
