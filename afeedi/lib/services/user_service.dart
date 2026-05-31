import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// Service for managing user-related operations
class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  
  /// Singleton instance
  static UserService get instance => _instance;
  
  UserService._internal();
  
  UserProfile? _currentUser;
  bool _isAuthenticated = false;
  
  /// Current user profile
  UserProfile? get currentUser => _currentUser;
  
  /// Whether the user is authenticated
  bool get isAuthenticated => _isAuthenticated;
  
  /// Initialize the user service
  Future<void> initialize() async {
    // In a real app, this would load user data from storage or API
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For demo purposes, we'll create a sample user
    _currentUser = UserProfile(
      id: 'user123',
      username: 'demo_user',
      email: 'demo@example.com',
      displayName: 'Demo User',
      avatarUrl: 'https://example.com/avatar.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    
    _isAuthenticated = true;
    notifyListeners();
  }
  
  /// Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      // In a real app, this would call an authentication API
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, we'll accept any input
      _currentUser = UserProfile(
        id: 'user123',
        username: email.split('@')[0],
        email: email,
        displayName: email.split('@')[0],
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
      );
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return false;
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    // In a real app, this would call an authentication API
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
  
  /// Update user profile
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    try {
      // In a real app, this would call an API
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }
  
  /// Update user preferences
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      // In a real app, this would call an API
      await Future.delayed(const Duration(seconds: 1));
      
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(
          preferences: preferences,
        );
        
        _currentUser = updatedUser;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating preferences: $e');
      return false;
    }
  }
  
  /// Get user viewing history
  Future<List<String>> getViewingHistory() async {
    // In a real app, this would call an API
    await Future.delayed(const Duration(seconds: 1));
    
    // Return sample viewing history
    return [
      'content123',
      'content456',
      'content789',
    ];
  }
}