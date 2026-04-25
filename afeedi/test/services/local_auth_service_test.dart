// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:afeedi/services/local_auth_service.dart';
import 'package:afeedi/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'dart:convert';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockPathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }
}

void main() {
  late LocalAuthService authService;
  late Directory tempDir;

  setUpAll(() async {
    // Setup Hive for testing
    tempDir = await Directory.systemTemp.createTemp('afeedi_test');
    Hive.init(tempDir.path);
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  tearDownAll(() async {
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

      // Sign up
      final user = await authService.signUp(
        email: email,
        password: password,
      );

      expect(user, isNotNull);
      expect(user!.email, email);

      // Verify that password is NOT stored as plain text in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final credentialsJson = prefs.getString('user_credentials_${user.id}');
      expect(credentialsJson, isNotNull);

      final credentials = jsonDecode(credentialsJson!);
      expect(credentials['password'], isNot(password), reason: 'Password should be hashed, not plain text');
      expect(credentials['password'].length, 64, reason: 'SHA-256 hash should be 64 characters long');
      expect(credentials['salt'], isNotNull, reason: 'Salt should be stored with credentials');
    });

    test('signIn works with correct password and fails with incorrect password', () async {
      const email = 'auth@test.com';
      const password = 'CorrectPassword';
      const wrongPassword = 'WrongPassword';

      // Sign up first
      await authService.signUp(
        email: email,
        password: password,
      );

      // Sign in with correct password
      final signedInUser = await authService.signIn(
        email: email,
        password: password,
      );
      expect(signedInUser, isNotNull);
      expect(signedInUser!.email, email);

      // Sign in with incorrect password
      final failedUser = await authService.signIn(
        email: email,
        password: wrongPassword,
      );
      expect(failedUser, isNull);
    });

    test('different users with same password have different hashes due to salt', () async {
      const sharedPassword = 'sharedPassword123';

      final user1 = await authService.signUp(email: 'user1@test.com', password: sharedPassword);
      final user2 = await authService.signUp(email: 'user2@test.com', password: sharedPassword);

      final prefs = await SharedPreferences.getInstance();
      final creds1 = jsonDecode(prefs.getString('user_credentials_${user1!.id}')!);
      final creds2 = jsonDecode(prefs.getString('user_credentials_${user2!.id}')!);

      expect(creds1['salt'], isNot(creds2['salt']));
      expect(creds1['password'], isNot(creds2['password']));
    });
  });
}
