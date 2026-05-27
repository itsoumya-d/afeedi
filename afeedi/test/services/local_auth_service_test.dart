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
  final Map<String, String> secureStorageData = {};

  setUpAll(() async {
    // Setup Hive for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('afeedi_test');
    Hive.init(tempDir.path);

    // Mock flutter_secure_storage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return secureStorageData[methodCall.arguments['key']];
        } else if (methodCall.method == 'write') {
          secureStorageData[methodCall.arguments['key']] =
              methodCall.arguments['value'];
          return null;
        } else if (methodCall.method == 'delete') {
          secureStorageData.remove(methodCall.arguments['key']);
          return null;
        } else if (methodCall.method == 'deleteAll') {
          secureStorageData.clear();
          return null;
        }
        return null;
      },
    );

    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    secureStorageData.clear();
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

      // Verify that password is NOT stored as plain text in SecureStorage
      final credentialsJson = secureStorageData['user_credentials_${user.id}'];
      expect(credentialsJson, isNotNull);

      final credentials = jsonDecode(credentialsJson!);
      expect(credentials['password'], isNot(password), reason: 'Password should be hashed, not plain text');
      expect(credentials['password'].length, 64, reason: 'SHA-256 hash should be 64 characters long');
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

    test('different passwords result in different hashes', () async {
      const password1 = 'password123';
      const password2 = 'password456';

      final user1 = await authService.signUp(email: 'user1@test.com', password: password1);
      final user2 = await authService.signUp(email: 'user2@test.com', password: password2);

      final creds1 = jsonDecode(secureStorageData['user_credentials_${user1!.id}']!);
      final creds2 = jsonDecode(secureStorageData['user_credentials_${user2!.id}']!);

      expect(creds1['password'], isNot(creds2['password']));
    });
  });
}
