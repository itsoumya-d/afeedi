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
    // Setup Hive for testing
    tempDir = await Directory.systemTemp.createTemp('afeedi_test');
    Hive.init(tempDir.path);
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
    test(
      'signIn works with correct password and fails with incorrect password',
      () async {
        const email = 'auth@test.com';
        const password = 'CorrectPassword';
        const wrongPassword = 'WrongPassword';

        // Sign up first
        await authService.signUp(email: email, password: password);

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
      },
    );
  });
}
