import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../core/storage/local_storage_service.dart';
import 'analytics_service.dart';

class LocalAuthService {
  static LocalAuthService? _instance;
  static LocalAuthService get instance => _instance ??= LocalAuthService._();

  LocalAuthService._();

  final LocalStorageService _storage = LocalStorageService.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
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

      // Save credentials with hashed password
      await _secureStorage.write(
        key: 'user_credentials_${user.id}',
        value: jsonEncode({
          'email': email,
          'password': _hashPassword(password),
        }),
      );

      // Set as current user
      await _setCurrentUser(user);

      // Track analytics
      await AnalyticsService.instance.trackUserInteraction(
        action: 'user_signup',
        screen: 'auth',
        additionalData: {'user_id': user.id, 'email': email},
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
      // Find user by email
      final users = await _storage.getAllUsers();
      final user = users.firstWhere(
        (u) => u.email == email,
        orElse: () => throw Exception('User not found'),
      );

      // Verify hashed password
      final credentialsJson = await _secureStorage.read(
        key: 'user_credentials_${user.id}',
      );

      if (credentialsJson != null) {
        final credentials = jsonDecode(credentialsJson);
        final hashedPassword = _hashPassword(password);
        if (credentials['password'] == hashedPassword) {
          // Set as current user
          await _setCurrentUser(user);

          // Track analytics
          await AnalyticsService.instance.trackUserInteraction(
            action: 'user_signin',
            screen: 'auth',
            additionalData: {'user_id': user.id, 'email': email},
          );

          return user;
        }
      }

      throw Exception('Invalid credentials');
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
          additionalData: {'user_id': _currentUser!.id},
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

      final updatedUser = _currentUser!.copyWith(updatedAt: DateTime.now());

      // Save updated user
      await _storage.saveUser(updatedUser);
      _currentUser = updatedUser;

      return updatedUser;
    } catch (error) {
      debugPrint('Error updating profile: $error');
      return null;
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
        additionalData: {'user_id': userId},
      );

      // Delete user data
      await _storage.deleteUser(userId);

      // Clear credentials
      final prefs = await SharedPreferences.getInstance();
      await _secureStorage.delete(key: 'user_credentials_$userId');
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

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
