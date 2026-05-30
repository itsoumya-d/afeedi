import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/storage/local_storage_service.dart';
import 'auth_service.dart';
import 'analytics_service.dart';

class UserManagementService {
  static UserManagementService? _instance;
  static UserManagementService get instance =>
      _instance ??= UserManagementService._();

  UserManagementService._();

  final _storage = LocalStorageService.instance;

  // -------------------------------------------------------------------------
  // User Profile  (stored in SharedPreferences as JSON)
  // -------------------------------------------------------------------------

  // Get user profile
  Future<LocalStorageResponse<UserProfile>> getUserProfile([
    String? userId,
  ]) async {
    try {
      final targetUserId = userId ?? AuthService.instance.currentUser?.id;
      if (targetUserId == null) {
        return LocalStorageResponse.error('User not authenticated');
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileKey(targetUserId));

      if (raw == null) {
        return LocalStorageResponse.error('User profile not found');
      }

      final profile = UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      return LocalStorageResponse.success(profile);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'user_profile',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // Update user profile
  Future<LocalStorageResponse<UserProfile>> updateUserProfile({
    String? displayName,
    String? bio,
    DateTime? dateOfBirth,
    String? timezone,
    String? language,
    String? country,
    String? avatarUrl,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return LocalStorageResponse.error('User not authenticated');
      }

      final existingResponse = await getUserProfile(user.id);
      final existing = existingResponse.success
          ? existingResponse.data!
          : _defaultProfile(user.id);

      final updated = existing.copyWith(
        displayName: displayName ?? existing.displayName,
        bio: bio ?? existing.bio,
        dateOfBirth: dateOfBirth ?? existing.dateOfBirth,
        timezone: timezone ?? existing.timezone,
        language: language ?? existing.language,
        country: country ?? existing.country,
        avatarUrl: avatarUrl ?? existing.avatarUrl,
        updatedAt: DateTime.now(),
      );

      await _saveProfile(updated);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'profile_updated',
        screen: 'profile_settings',
        additionalData: {
          'fields_updated': [
            if (displayName != null) 'display_name',
            if (bio != null) 'bio',
            if (dateOfBirth != null) 'date_of_birth',
            if (timezone != null) 'timezone',
            if (language != null) 'language',
            if (country != null) 'country',
            if (avatarUrl != null) 'avatar_url',
          ],
        },
      );

      return LocalStorageResponse.success(updated);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'profile_settings',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // -------------------------------------------------------------------------
  // User Preferences  (stored via LocalStorageService / Hive)
  // -------------------------------------------------------------------------

  // Get user preferences
  Future<LocalStorageResponse<UserPreferences>> getUserPreferences([
    String? userId,
  ]) async {
    try {
      final targetUserId = userId ?? AuthService.instance.currentUser?.id;
      if (targetUserId == null) {
        return LocalStorageResponse.error('User not authenticated');
      }

      final prefs = await _storage.getUserPreferences(targetUserId);

      if (prefs == null) {
        return await _createDefaultPreferences(targetUserId);
      }

      return LocalStorageResponse.success(prefs);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'user_preferences',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // Update user preferences
  Future<LocalStorageResponse<UserPreferences>> updateUserPreferences({
    List<String>? contentCategories,
    Map<String, int>? platformPriorities,
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
    bool? aiRecommendationsEnabled,
    bool? matureContentEnabled,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return LocalStorageResponse.error('User not authenticated');
      }

      final existing =
          await _storage.getUserPreferences(user.id) ??
          _defaultPreferences(user.id);

      final updated = existing.copyWith(
        contentCategories: contentCategories ?? existing.contentCategories,
        platformPriorities: platformPriorities ?? existing.platformPriorities,
        notificationSettings:
            notificationSettings ?? existing.notificationSettings,
        privacySettings: privacySettings ?? existing.privacySettings,
        aiRecommendationsEnabled:
            aiRecommendationsEnabled ?? existing.aiRecommendationsEnabled,
        matureContentEnabled:
            matureContentEnabled ?? existing.matureContentEnabled,
        updatedAt: DateTime.now(),
      );

      await _storage.saveUserPreferences(updated);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'preferences_updated',
        screen: 'preferences_settings',
        additionalData: {
          'fields_updated': [
            if (contentCategories != null) 'content_categories',
            if (platformPriorities != null) 'platform_priorities',
            if (notificationSettings != null) 'notification_settings',
            if (privacySettings != null) 'privacy_settings',
            if (aiRecommendationsEnabled != null) 'ai_recommendations_enabled',
            if (matureContentEnabled != null) 'mature_content_enabled',
          ],
        },
      );

      return LocalStorageResponse.success(updated);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'preferences_settings',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Onboarding
  // -------------------------------------------------------------------------

  // Update onboarding progress
  Future<LocalStorageResponse<UserProfile>> updateOnboardingProgress({
    required int step,
    bool? completed,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return LocalStorageResponse.error('User not authenticated');
      }

      final existingResponse = await getUserProfile(user.id);
      final existing = existingResponse.success
          ? existingResponse.data!
          : _defaultProfile(user.id);

      final updated = existing.copyWith(
        onboardingStep: step,
        onboardingCompleted: completed ?? existing.onboardingCompleted,
        updatedAt: DateTime.now(),
      );

      await _saveProfile(updated);

      await AnalyticsService.instance.trackOnboardingEvent(
        eventName: completed == true
            ? 'onboarding_completed'
            : 'onboarding_step_completed',
        stepNumber: step,
        stepName: _getOnboardingStepName(step),
      );

      return LocalStorageResponse.success(updated);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'onboarding',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // -------------------------------------------------------------------------
  // User Statistics
  // -------------------------------------------------------------------------

  // Get user statistics from local storage
  Future<Map<String, dynamic>> getUserStatistics([String? userId]) async {
    try {
      final targetUserId = userId ?? AuthService.instance.currentUser?.id;
      if (targetUserId == null) return {};

      // Content interactions
      final rawInteractions = await _storage.getContentInteractions(
        targetUserId,
      );
      final interactionCounts = <String, int>{};
      for (final interaction in rawInteractions) {
        final type = interaction['interaction_type'] as String? ?? 'unknown';
        interactionCounts[type] = (interactionCounts[type] ?? 0) + 1;
      }

      // Platform connections
      final connections = await _storage.getPlatformConnections(targetUserId);
      final connectedPlatforms = connections
          .where((c) => c.isActive)
          .map((c) => c.platform.name)
          .toList();

      // Scheduled content (upcoming only)
      final scheduled = await _storage.getScheduledContentForUser(targetUserId);
      final now = DateTime.now();
      final upcomingScheduled = scheduled.where((s) {
        final scheduledFor = s['scheduled_for'] as String?;
        if (scheduledFor == null) return false;
        try {
          return DateTime.parse(scheduledFor).isAfter(now);
        } catch (_) {
          return false;
        }
      }).length;

      // Recommendations
      final rawRecs = await _storage.getRecommendations(targetUserId);
      final totalRecommendations = rawRecs.length;
      final clickedRecommendations = rawRecs
          .where((r) => r['is_clicked'] == true)
          .length;

      return {
        'total_interactions': rawInteractions.length,
        'interaction_breakdown': interactionCounts,
        'connected_platforms': connectedPlatforms,
        'connected_platforms_count': connectedPlatforms.length,
        'upcoming_scheduled_content': upcomingScheduled,
        'total_recommendations': totalRecommendations,
        'clicked_recommendations': clickedRecommendations,
        'recommendation_click_rate': totalRecommendations > 0
            ? clickedRecommendations / totalRecommendations
            : 0.0,
      };
    } catch (error) {
      debugPrint('Error getting user statistics: $error');
      return {};
    }
  }

  // -------------------------------------------------------------------------
  // GDPR: Export / Delete
  // -------------------------------------------------------------------------

  // Export user data (GDPR compliance)
  Future<LocalStorageResponse<Map<String, dynamic>>> exportUserData() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return LocalStorageResponse.error('User not authenticated');
      }

      final exportData = <String, dynamic>{
        'export_timestamp': DateTime.now().toIso8601String(),
        'user_id': user.id,
      };

      // Profile
      final profileResponse = await getUserProfile();
      if (profileResponse.success) {
        exportData['profile'] = profileResponse.data!.toJson();
      }

      // Preferences
      final preferencesResponse = await getUserPreferences();
      if (preferencesResponse.success) {
        exportData['preferences'] = preferencesResponse.data!.toJson();
      }

      // Platform connections (without sensitive tokens)
      final connections = await AuthService.instance.getPlatformConnections();
      exportData['platform_connections'] = connections
          .map(
            (c) => {
              'platform': c.platform.name,
              'platform_username': c.platformUsername,
              'connected_at': c.createdAt.toIso8601String(),
              'is_active': c.isActive,
            },
          )
          .toList();

      // Content interactions
      exportData['content_interactions'] =
          (await _storage.getContentInteractions(user.id))
              .map(
                (i) => {
                  'interaction_type': i['interaction_type'],
                  'created_at': i['created_at'],
                },
              )
              .toList();

      // Scheduled content
      exportData['scheduled_content'] =
          (await _storage.getScheduledContentForUser(user.id))
              .map(
                (s) => {
                  'scheduled_for': s['scheduled_for'],
                  'notes': s['notes'],
                  'created_at': s['created_at'],
                },
              )
              .toList();

      // Analytics events (last 30 days)
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      exportData['recent_analytics'] =
          (await _storage.getAnalyticsEvents(user.id))
              .where((e) {
                final raw = e['created_at'] as String?;
                if (raw == null) return false;
                try {
                  return DateTime.parse(raw).isAfter(cutoff);
                } catch (_) {
                  return false;
                }
              })
              .map(
                (e) => {
                  'event_type': e['event_type'],
                  'event_name': e['event_name'],
                  'created_at': e['created_at'],
                },
              )
              .toList();

      await AnalyticsService.instance.trackUserInteraction(
        action: 'data_export_requested',
        screen: 'privacy_settings',
      );

      return LocalStorageResponse.success(exportData);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'privacy_settings',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // Delete user data (GDPR compliance)
  Future<LocalStorageResponse<bool>> deleteUserData() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return LocalStorageResponse.error('User not authenticated');
      }

      // Remove user record and profile from local storage
      await _storage.deleteUser(user.id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey(user.id));

      await AnalyticsService.instance.trackUserInteraction(
        action: 'data_deletion_completed',
        screen: 'privacy_settings',
        additionalData: {'user_id': user.id},
      );

      // Sign out the user
      await AuthService.instance.signOut();

      return LocalStorageResponse.success(true);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'privacy_settings',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Admin Operations
  // -------------------------------------------------------------------------

  // Search users (admin only)
  Future<List<User>> searchUsers({
    String? query,
    UserRole? role,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null || !currentUser.isAdmin) {
        return [];
      }

      var users = await _storage.getAllUsers();

      if (query != null && query.isNotEmpty) {
        final lq = query.toLowerCase();
        users = users.where((u) => u.email.toLowerCase().contains(lq)).toList();
      }

      if (role != null) {
        users = users.where((u) => u.role == role).toList();
      }

      if (isActive != null) {
        users = users.where((u) => u.isActive == isActive).toList();
      }

      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return users.skip(offset).take(limit).toList();
    } catch (error) {
      debugPrint('Error searching users: $error');
      return [];
    }
  }

  // Update user role (admin only)
  Future<LocalStorageResponse<User>> updateUserRole(
    String userId,
    UserRole newRole,
  ) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null || !currentUser.isAdmin) {
        return LocalStorageResponse.error('Insufficient permissions');
      }

      final target = await _storage.getUser(userId);
      if (target == null) {
        return LocalStorageResponse.error('User not found');
      }

      final updated = target.copyWith(role: newRole, updatedAt: DateTime.now());

      await _storage.saveUser(updated);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'user_role_updated',
        screen: 'admin_panel',
        additionalData: {
          'target_user_id': userId,
          'new_role': newRole.name,
          'admin_user_id': currentUser.id,
        },
      );

      return LocalStorageResponse.success(updated);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'admin_panel',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // Deactivate user account (admin only)
  Future<LocalStorageResponse<bool>> deactivateUser(String userId) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null || !currentUser.isAdmin) {
        return LocalStorageResponse.error('Insufficient permissions');
      }

      final target = await _storage.getUser(userId);
      if (target == null) {
        return LocalStorageResponse.error('User not found');
      }

      final deactivated = target.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _storage.saveUser(deactivated);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'user_deactivated',
        screen: 'admin_panel',
        additionalData: {
          'target_user_id': userId,
          'admin_user_id': currentUser.id,
        },
      );

      return LocalStorageResponse.success(true);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'admin_panel',
      );
      return LocalStorageResponse.error(error.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  String _profileKey(String userId) => 'user_profile_$userId';

  Future<void> _saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(profile.userId),
      jsonEncode(profile.toJson()),
    );
  }

  UserProfile _defaultProfile(String userId) {
    final now = DateTime.now();
    return UserProfile(
      id: 'profile_$userId',
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  UserPreferences _defaultPreferences(String userId) {
    final now = DateTime.now();
    return UserPreferences(
      id: 'prefs_$userId',
      userId: userId,
      contentCategories: const [],
      platformPriorities: const {
        'youtube': 1,
        'instagram': 2,
        'tiktok': 3,
        'facebook': 4,
      },
      notificationSettings: const NotificationSettings(),
      privacySettings: const PrivacySettings(),
      aiRecommendationsEnabled: true,
      matureContentEnabled: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<LocalStorageResponse<UserPreferences>> _createDefaultPreferences(
    String userId,
  ) async {
    try {
      final defaults = _defaultPreferences(userId);
      await _storage.saveUserPreferences(defaults);
      return LocalStorageResponse.success(defaults);
    } catch (error) {
      return LocalStorageResponse.error(error.toString());
    }
  }

  String _getOnboardingStepName(int step) {
    switch (step) {
      case 0:
        return 'welcome';
      case 1:
        return 'authentication';
      case 2:
        return 'interests';
      case 3:
        return 'platform_preferences';
      case 4:
        return 'calendar_setup';
      case 5:
        return 'completed';
      default:
        return 'step_$step';
    }
  }
}
