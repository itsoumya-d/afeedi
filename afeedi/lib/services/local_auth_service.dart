import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../core/storage/local_storage_service.dart';
import 'analytics_service.dart';

class LocalAuthService {
  static LocalAuthService? _instance;
  static LocalAuthService get instance => _instance ??= LocalAuthService._();

  LocalAuthService._();

  static const int _maxFailedAttempts = 5;
  static const String _failedAttemptsKey = 'auth_failed_attempts';
  static const String _lockoutUntilKey = 'auth_lockout_until';

  final LocalStorageService _storage = LocalStorageService.instance;
  User? _currentUser;

  // Current user getter
  User? get currentUser => _currentUser;

  // Initialize auth service
  Future<void> initialize() async {
    await _loadCurrentUser();
  }

  // Load current user from storage
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('current_user_id');

      if (currentUserId != null) {
        _currentUser = await _storage.getUser(currentUserId);
      }
    } catch (error) {
      debugPrint('Error loading current user: $error');
    }
  }

  // Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      // Create new user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        role: UserRole.registered,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user to storage
      await _storage.saveUser(user);

      // Save credentials with PBKDF2-hashed password
      final prefs = await SharedPreferences.getInstance();
      final salt = _generateSalt();
      await prefs.setString('user_credentials_${user.id}', jsonEncode({
        'email': email,
        'kdf': 'pbkdf2-sha256',
        'iterations': _pbkdf2Iterations,
        'salt': salt,
        'hash': _pbkdf2Hash(password, salt),
      }));

      // Set as current user
      await _setCurrentUser(user);

      // Track analytics
      await AnalyticsService.instance.trackUserInteraction(
        action: 'user_signup',
        screen: 'auth',
      );

      return user;
    } catch (error) {
      debugPrint('Error during sign up: $error');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutUntilMs = prefs.getInt(_lockoutUntilKey) ?? 0;
      if (lockoutUntilMs > DateTime.now().millisecondsSinceEpoch) {
        final remaining = (lockoutUntilMs - DateTime.now().millisecondsSinceEpoch) ~/ 60000;
        throw Exception('Account temporarily locked. Try again in ${remaining + 1} minute(s).');
      }

      // Find user by email
      final users = await _storage.getAllUsers();
      final user = users.firstWhere(
        (u) => u.email == email,
        orElse: () => throw Exception('User not found'),
      );

      // Verify hashed password
      final credentialsJson = prefs.getString('user_credentials_${user.id}');

      if (credentialsJson != null) {
        final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
        bool passwordValid = false;
        if (credentials['kdf'] == 'pbkdf2-sha256') {
          // New PBKDF2 format
          final candidateHash = _pbkdf2Hash(password, credentials['salt'] as String);
          passwordValid = candidateHash == (credentials['hash'] as String);
        } else {
          // Legacy SHA-256: verify and upgrade on success
          passwordValid = credentials['password'] == _legacySha256(password);
          if (passwordValid) {
            // Upgrade stored credential to PBKDF2 silently
            final salt = _generateSalt();
            await prefs.setString('user_credentials_${user.id}', jsonEncode({
              'email': email,
              'kdf': 'pbkdf2-sha256',
              'iterations': _pbkdf2Iterations,
              'salt': salt,
              'hash': _pbkdf2Hash(password, salt),
            }));
          }
        }
        if (passwordValid) {
          // Clear failed attempts on success
          await prefs.setInt(_failedAttemptsKey, 0);
          await prefs.remove(_lockoutUntilKey);

          // Set as current user
          await _setCurrentUser(user);

          // Track analytics
          await AnalyticsService.instance.trackUserInteraction(
            action: 'user_signin',
            screen: 'auth',
          );

          return user;
        }
      }

      // Wrong password — increment failed attempts
      final attempts = (prefs.getInt(_failedAttemptsKey) ?? 0) + 1;
      await prefs.setInt(_failedAttemptsKey, attempts);
      if (attempts >= _maxFailedAttempts) {
        // Lock for 5 minutes (exponential: could be attempts*minutes but keep simple)
        final lockUntil = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
        await prefs.setInt(_lockoutUntilKey, lockUntil);
        await prefs.setInt(_failedAttemptsKey, 0);
        throw Exception('Too many failed attempts. Account locked for 5 minutes.');
      }
      throw Exception('Invalid password. ${_maxFailedAttempts - attempts} attempt(s) remaining.');
    } catch (error) {
      debugPrint('Error during sign in: $error');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (_currentUser != null) {
        // Track analytics
        await AnalyticsService.instance.trackUserInteraction(
          action: 'user_signout',
          screen: 'auth',
          additionalData: {
            'user_id': _currentUser!.id,
          },
        );
      }

      // Clear current user
      _currentUser = null;

      // Remove from storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
    } catch (error) {
      debugPrint('Error during sign out: $error');
    }
  }

  // Set current user
  Future<void> _setCurrentUser(User user) async {
    _currentUser = user;

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.id);
  }

  // Update user profile
  Future<User?> updateProfile({
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_currentUser == null) return null;

      final updatedUser = _currentUser!.copyWith(
        updatedAt: DateTime.now(),
      );

      // Save updated user
      await _storage.saveUser(updatedUser);
      _currentUser = updatedUser;

      return updatedUser;
    } catch (error) {
      debugPrint('Error updating profile: $error');
      return null;
    }
  }

  // Change password — verifies current password then saves new hash
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) return false;
      final prefs = await SharedPreferences.getInstance();
      final credJson = prefs.getString('user_credentials_${_currentUser!.id}');
      if (credJson == null) return false;
      final cred = jsonDecode(credJson) as Map<String, dynamic>;
      final candidateHash = _pbkdf2Hash(currentPassword, cred['salt'] as String);
      if (candidateHash != cred['hash']) return false;
      final newSalt = _generateSalt();
      await prefs.setString('user_credentials_${_currentUser!.id}', jsonEncode({
        'email': cred['email'],
        'kdf': 'pbkdf2-sha256',
        'iterations': _pbkdf2Iterations,
        'salt': newSalt,
        'hash': _pbkdf2Hash(newPassword, newSalt),
      }));
      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      if (_currentUser == null) return false;

      final userId = _currentUser!.id;

      // Track analytics before deletion
      await AnalyticsService.instance.trackUserInteraction(
        action: 'user_account_deleted',
        screen: 'auth',
        additionalData: {
          'user_id': userId,
        },
      );

      // Delete user data
      await _storage.deleteUser(userId);

      // Clear credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_credentials_$userId');
      await prefs.remove('current_user_id');

      _currentUser = null;

      return true;
    } catch (error) {
      debugPrint('Error deleting account: $error');
      return false;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 32;

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
    return base64Encode(saltBytes);
  }

  // PBKDF2-HMAC-SHA256 per RFC 2898 §5.2.
  // dkLen = 32 bytes (SHA-256 output) → one block is always sufficient, but the
  // implementation supports multiple blocks so it is formally complete.
  String _pbkdf2Hash(String password, String saltBase64, {int dkLen = 32}) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64Decode(saltBase64);
    final hLen = 32; // SHA-256 output length in bytes
    final numBlocks = (dkLen / hLen).ceil();
    final derived = <int>[];

    for (int blockIndex = 1; blockIndex <= numBlocks; blockIndex++) {
      final hmac = Hmac(sha256, passwordBytes);
      // U1 = PRF(password, salt || INT(blockIndex))
      final blockCounter = [
        (blockIndex >> 24) & 0xFF,
        (blockIndex >> 16) & 0xFF,
        (blockIndex >> 8) & 0xFF,
        blockIndex & 0xFF,
      ];
      List<int> u = hmac.convert([...saltBytes, ...blockCounter]).bytes;
      final block = List<int>.from(u);
      for (int iter = 1; iter < _pbkdf2Iterations; iter++) {
        u = Hmac(sha256, passwordBytes).convert(u).bytes;
        for (int j = 0; j < block.length; j++) {
          block[j] ^= u[j];
        }
      }
      derived.addAll(block);
    }

    return base64Encode(derived.take(dkLen).toList());
  }

  // Legacy SHA-256 hash — used only to verify and upgrade old credentials
  String _legacySha256(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Get user preferences
  Future<UserPreferences?> getUserPreferences() async {
    if (_currentUser == null) return null;
    return await _storage.getUserPreferences(_currentUser!.id);
  }

  // Update user preferences
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    if (_currentUser == null) return;
    await _storage.saveUserPreferences(preferences);
  }
}
