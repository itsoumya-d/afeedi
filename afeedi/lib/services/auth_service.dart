import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/platform_connection_model.dart';
import 'oauth_service.dart';
import 'analytics_service.dart';
import 'local_auth_service.dart';

// NOTE: user_id and user_email are stored in SharedPreferences (unencrypted).
// In production, migrate these to flutter_secure_storage to prevent
// exposure on non-encrypted or rooted devices.

// Simple auth result class
class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  
  AuthResult({required this.success, this.error, this.user});
}

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  // Rate limiting constants for email/password login
  static const int _maxLoginAttempts = 5;
  static const int _lockoutMinutes = 15;

  User? _currentUser;
  
  // Get current user
  User? get currentUser => _currentUser;
  
  // Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;
  
  // Initialize and restore user session from local storage
  Future<void> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email');

      if (userId != null && userEmail != null) {
        _currentUser = User(
          id: userId,
          email: userEmail,
          role: UserRole.registered,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }
  }
  
  // Initialize auth service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final email = prefs.getString('user_email');

      if (userId != null && email != null) {
         _currentUser = User(
           id: userId,
           email: email,
           role: UserRole.registered,
           isActive: true,
           createdAt: DateTime.now(),
           updatedAt: DateTime.now(),
         );
       }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }
  }
  
  // Rate limiting helpers — keyed per email address
  Future<bool> _isAccountLocked(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutTime = prefs.getInt('login_lockout_time_${email.toLowerCase()}');
    if (lockoutTime == null) return false;
    final lockoutEnd = DateTime.fromMillisecondsSinceEpoch(lockoutTime);
    if (DateTime.now().isBefore(lockoutEnd)) return true;
    // Lockout expired — clear it
    await prefs.remove('login_lockout_time_${email.toLowerCase()}');
    await prefs.remove('login_failed_attempts_${email.toLowerCase()}');
    return false;
  }

  Future<void> _recordFailedAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'login_failed_attempts_${email.toLowerCase()}';
    final attempts = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, attempts);
    if (attempts >= _maxLoginAttempts) {
      final lockoutEnd = DateTime.now()
          .add(Duration(minutes: _lockoutMinutes));
      await prefs.setInt(
        'login_lockout_time_${email.toLowerCase()}',
        lockoutEnd.millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _clearFailedAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_failed_attempts_${email.toLowerCase()}');
    await prefs.remove('login_lockout_time_${email.toLowerCase()}');
  }

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      // Simulate sign up - in real app, this would call backend
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final user = User(
         id: userId,
         email: email,
         role: UserRole.registered,
         isActive: true,
         createdAt: DateTime.now(),
         updatedAt: DateTime.now(),
       );
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name ?? 'User');
      
      _currentUser = user;
      
      // Track analytics
       AnalyticsService.instance.trackUserInteraction(
         action: 'signup_success',
         screen: 'auth',
         additionalData: {
           'method': 'email',
           'user_id': userId,
         },
       );
      
      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Per-email rate limiting: check lockout before attempting auth
      if (await _isAccountLocked(email)) {
        final prefs = await SharedPreferences.getInstance();
        final lockoutTime =
            prefs.getInt('login_lockout_time_${email.toLowerCase()}') ?? 0;
        final remaining =
            (lockoutTime - DateTime.now().millisecondsSinceEpoch) ~/ 60000;
        return AuthResult(
          success: false,
          error:
              'Account temporarily locked. Try again in ${remaining + 1} minute(s).',
        );
      }

      final user = await LocalAuthService.instance.signIn(
        email: email,
        password: password,
      );
      if (user != null) {
        // Successful login — clear per-email failed attempt counter
        await _clearFailedAttempts(email);
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.id);
        await prefs.setString('user_email', user.email);
        AnalyticsService.instance.trackUserInteraction(
          action: 'signin_success',
          screen: 'auth',
          additionalData: {'method': 'email', 'user_id': user.id},
        );
        return AuthResult(success: true, user: user);
      }
      // Record the failed attempt for per-email rate limiting
      await _recordFailedAttempt(email);
      return AuthResult(
          success: false, error: 'Authentication failed. Please try again.');
    } catch (e) {
      // Do not expose internal error details to the caller
      debugPrint('SignIn error: $e');
      return AuthResult(
          success: false, error: 'Authentication failed. Please try again.');
    }
  }
  
  // Sign out
  Future<AuthResult> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      
      _currentUser = null;
      
      // Track analytics
       AnalyticsService.instance.trackUserInteraction(
         action: 'signout',
         screen: 'app',
       );
      
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // OAuth sign in with actual OAuth data
  Future<AuthResult> signInWithOAuth(String provider, [Map<String, dynamic>? oauthData]) async {
    try {
      // Use OAuth data if provided, otherwise get from OAuthService
      Map<String, dynamic>? authData = oauthData;
      if (authData == null) {
        // Get OAuth data from the service
        switch (provider.toLowerCase()) {
          case 'google':
            authData = await OAuthService.connectGoogle();
            break;
          case 'apple':
            authData = await OAuthService.connectApple();
            break;
          default:
            return AuthResult(success: false, error: 'Unsupported OAuth provider: $provider');
        }
      }
      
      if (authData == null) {
        return AuthResult(success: false, error: 'OAuth authentication failed');
      }
      
      // Extract user information from OAuth data
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final email = authData['email'] ?? 'user@$provider.com';
      final displayName = authData['displayName'] ?? authData['givenName'] ?? 'User';
      
      final user = User(
         id: userId,
         email: email,
         role: UserRole.registered,
         isActive: true,
         createdAt: DateTime.now(),
         updatedAt: DateTime.now(),
       );
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', displayName);
      
      // OAuth tokens are intentionally NOT stored here.
      // Each OAuth package (google_sign_in, sign_in_with_apple) manages its own
      // token lifecycle and secure storage. Storing tokens in SharedPreferences
      // would expose them in plaintext on non-rooted devices' app data.
      
      _currentUser = user;
      
      // Track analytics
       AnalyticsService.instance.trackUserInteraction(
         action: 'oauth_signin_success',
         screen: 'auth',
         additionalData: {
           'provider': provider,
           'user_id': userId,
         },
       );
      
      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // Update user profile
  Future<AuthResult> updateProfile({
    String? email,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult(success: false, error: 'User not authenticated');
      }
      
      final updatedUser = _currentUser!.copyWith(
        email: email ?? _currentUser!.email,
        updatedAt: DateTime.now(),
      );
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      if (email != null) await prefs.setString('user_email', email);
      
      _currentUser = updatedUser;
      
      return AuthResult(success: true, user: updatedUser);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // Change password (simplified)
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Simulate password change
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // Reset password (simplified)
  Future<AuthResult> resetPassword(String email) async {
    try {
      // Simulate password reset
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // Delete account (simplified)
  Future<AuthResult> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentUser = null;
      
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // Get platform connections for the current user
  Future<List<PlatformConnection>> getPlatformConnections() async {
    try {
      if (_currentUser == null) return [];
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = prefs.getStringList('platform_connections_${_currentUser!.id}') ?? [];
      return connectionsJson
          .map((jsonStr) {
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              return PlatformConnection.fromJson(data);
            } catch (_) {
              return null;
            }
          })
          .whereType<PlatformConnection>()
          .toList();
    } catch (e) {
      debugPrint('Error getting platform connections: $e');
      return [];
    }
  }
}