import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/platform_connection_model.dart';
import 'oauth_service.dart';
import 'analytics_service.dart';

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
  
  User? _currentUser;
  final _secureStorage = const FlutterSecureStorage();

  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }
  
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
      // Simulate sign in - in real app, this would validate credentials
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
      await prefs.setString('user_name', 'User');
      
      _currentUser = user;
      
      // Track analytics
       AnalyticsService.instance.trackUserInteraction(
         action: 'signin_success',
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
  
  // Sign out
  Future<AuthResult> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      
      await _secureStorage.deleteAll();

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
      
      // Store OAuth tokens securely
      if (authData['accessToken'] != null) {
        await _secureStorage.write(key: 'oauth_access_token_$provider', value: authData['accessToken']);
      }
      if (authData['idToken'] != null) {
        await _secureStorage.write(key: 'oauth_id_token_$provider', value: authData['idToken']);
      }
      
      _currentUser = user;
      
      // Track analytics
       AnalyticsService.instance.trackUserInteraction(
         action: 'oauth_signin_success',
         screen: 'auth',
         additionalData: {
           'provider': provider,
           'user_id': userId,
           'email': email,
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
      await _secureStorage.deleteAll();
      _currentUser = null;
      
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  Future<String?> getOAuthAccessToken(String provider) async {
    return await _secureStorage.read(key: 'oauth_access_token_$provider');
  }

  Future<String?> getOAuthIdToken(String provider) async {
    return await _secureStorage.read(key: 'oauth_id_token_$provider');
  }

  // Get platform connections for the current user
  Future<List<PlatformConnection>> getPlatformConnections() async {
    try {
      if (_currentUser == null) return [];
      
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = prefs.getStringList('platform_connections_${_currentUser!.id}') ?? [];
      
      return connectionsJson.map((json) {
        final data = Map<String, dynamic>.from({
          'id': 'conn_${DateTime.now().millisecondsSinceEpoch}',
          'user_id': _currentUser!.id,
          'platform': 'youtube',
          'platform_user_id': 'user123',
          'platform_username': 'testuser',
          'access_token': 'token123',
          'refresh_token': 'refresh123',
          'expires_at': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        return PlatformConnection.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting platform connections: $e');
      return [];
    }
  }
}