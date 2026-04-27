import 'package:flutter/foundation.dart';
import '../core/config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/platform_connection_model.dart';
import '../models/analytics_model.dart';
import 'auth_service.dart';
import 'analytics_service.dart';

class UserManagementService {
  static UserManagementService? _instance;
  static UserManagementService get instance =>
      _instance ??= UserManagementService._();

  UserManagementService._();

  final _supabase = SupabaseConfig.client;

  // Get user profile
  Future<SupabaseResponse<UserProfile>> getUserProfile([String? userId]) async {
    try {
      final targetUserId = userId ?? AuthService.instance.currentUser?.id;
      if (targetUserId == null) {
        return SupabaseResponse.error('User not authenticated');
      }

      final response = await _supabase
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (response == null) {
        return SupabaseResponse.error('User profile not found');
      }

      final profile = UserProfile.fromJson(response);
      return SupabaseResponse.success(profile);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'user_profile',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Update user profile
  Future<SupabaseResponse<UserProfile>> updateUserProfile({
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
        return SupabaseResponse.error('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (dateOfBirth != null)
        updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (timezone != null) updateData['timezone'] = timezone;
      if (language != null) updateData['language'] = language;
      if (country != null) updateData['country'] = country;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      final response = await _supabase
          .from(SupabaseConfig.userProfilesTable)
          .update(updateData)
          .eq('user_id', user.id)
          .select()
          .single();

      final updatedProfile = UserProfile.fromJson(response);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'profile_updated',
        screen: 'profile_settings',
        additionalData: {'fields_updated': updateData.keys.toList()},
      );

      return SupabaseResponse.success(updatedProfile);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'profile_settings',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Get user preferences
  Future<SupabaseResponse<UserPreferences>> getUserPreferences([
    String? userId,
  ]) async {
    try {
      final targetUserId = userId ?? AuthService.instance.currentUser?.id;
      if (targetUserId == null) {
        return SupabaseResponse.error('User not authenticated');
      }

      final response = await _supabase
          .from(SupabaseConfig.userPreferencesTable)
          .select()
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        return await _createDefaultPreferences(targetUserId);
      }

      final preferences = UserPreferences.fromJson(response);
      return SupabaseResponse.success(preferences);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'user_preferences',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Update user preferences
  Future<SupabaseResponse<UserPreferences>> updateUserPreferences({
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
        return SupabaseResponse.error('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (contentCategories != null) {
        updateData['content_categories'] = contentCategories;
      }
      if (platformPriorities != null) {
        updateData['platform_priorities'] = platformPriorities;
      }
      if (notificationSettings != null) {
        updateData['notification_settings'] = notificationSettings.toJson();
      }
      if (privacySettings != null) {
        updateData['privacy_settings'] = privacySettings.toJson();
      }
      if (aiRecommendationsEnabled != null) {
        updateData['ai_recommendations_enabled'] = aiRecommendationsEnabled;
      }
      if (matureContentEnabled != null) {
        updateData['mature_content_enabled'] = matureContentEnabled;
      }

      final response = await _supabase
          .from(SupabaseConfig.userPreferencesTable)
          .update(updateData)
          .eq('user_id', user.id)
          .select()
          .single();

      final updatedPreferences = UserPreferences.fromJson(response);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'preferences_updated',
        screen: 'preferences_settings',
        additionalData: {'fields_updated': updateData.keys.toList()},
      );

      return SupabaseResponse.success(updatedPreferences);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'preferences_settings',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Update onboarding progress
  Future<SupabaseResponse<UserProfile>> updateOnboardingProgress({
    required int step,
    bool? completed,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return SupabaseResponse.error('User not authenticated');
      }

      final updateData = {
        'onboarding_step': step,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (completed != null) {
        updateData['onboarding_completed'] = completed;
      }

      final response = await _supabase
          .from(SupabaseConfig.userProfilesTable)
          .update(updateData)
          .eq('user_id', user.id)
          .select()
          .single();

      final updatedProfile = UserProfile.fromJson(response);

      await AnalyticsService.instance.trackOnboardingEvent(
        eventName: completed == true
            ? 'onboarding_completed'
            : 'onboarding_step_completed',
        stepNumber: step,
        stepName: _getOnboardingStepName(step),
      );

      return SupabaseResponse.success(updatedProfile);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'onboarding',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics([String? userId]) async {
    try {
      final targetUserId = userId ?? AuthService.instance.currentUser?.id;
      if (targetUserId == null) {
        return {};
      }

      // Get content interactions count
      final interactionsResponse = await _supabase
          .from(SupabaseConfig.contentInteractionsTable)
          .select('interaction_type')
          .eq('user_id', targetUserId);

      final interactions = interactionsResponse as List;
      final interactionCounts = <String, int>{};

      for (final interaction in interactions) {
        final type = interaction['interaction_type'] as String;
        interactionCounts[type] = (interactionCounts[type] ?? 0) + 1;
      }

      // Get platform connections count
      final connectionsResponse = await _supabase
          .from(SupabaseConfig.platformConnectionsTable)
          .select('platform')
          .eq('user_id', targetUserId)
          .eq('is_active', true);

      final connections = connectionsResponse as List;
      final connectedPlatforms = connections.map((c) => c['platform']).toList();

      // Get scheduled content count
      final scheduledResponse = await _supabase
          .from(SupabaseConfig.scheduledContentTable)
          .select('id')
          .eq('user_id', targetUserId)
          .gt('scheduled_for', DateTime.now().toIso8601String());

      final upcomingScheduled = (scheduledResponse as List).length;

      // Get recommendations metrics
      final recommendationsResponse = await _supabase
          .from(SupabaseConfig.recommendationsTable)
          .select('is_shown, is_clicked')
          .eq('user_id', targetUserId);

      final recommendations = recommendationsResponse as List;
      final totalRecommendations = recommendations.length;
      final clickedRecommendations = recommendations
          .where((r) => r['is_clicked'] == true)
          .length;

      return {
        'total_interactions': interactions.length,
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

  // Export user data (GDPR compliance)
  Future<SupabaseResponse<Map<String, dynamic>>> exportUserData() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return SupabaseResponse.error('User not authenticated');
      }

      final exportData = <String, dynamic>{
        'export_timestamp': DateTime.now().toIso8601String(),
        'user_id': user.id,
      };

      // Get user profile
      final profileResponse = await getUserProfile();
      if (profileResponse.hasData) {
        exportData['profile'] = profileResponse.data!.toJson();
      }

      // Get user preferences
      final preferencesResponse = await getUserPreferences();
      if (preferencesResponse.hasData) {
        exportData['preferences'] = preferencesResponse.data!.toJson();
      }

      // Get platform connections (without sensitive tokens)
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

      // Get content interactions
      final interactionsResponse = await _supabase
          .from(SupabaseConfig.contentInteractionsTable)
          .select('interaction_type, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      exportData['content_interactions'] = interactionsResponse;

      // Get scheduled content
      final scheduledResponse = await _supabase
          .from(SupabaseConfig.scheduledContentTable)
          .select('scheduled_for, notes, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      exportData['scheduled_content'] = scheduledResponse;

      // Get analytics events (last 30 days)
      final analyticsResponse = await _supabase
          .from(SupabaseConfig.analyticsEventsTable)
          .select('event_type, event_name, created_at')
          .eq('user_id', user.id)
          .gt(
            'created_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .order('created_at', ascending: false);

      exportData['recent_analytics'] = analyticsResponse;

      await AnalyticsService.instance.trackUserInteraction(
        action: 'data_export_requested',
        screen: 'privacy_settings',
      );

      return SupabaseResponse.success(exportData);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'privacy_settings',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Delete user data (GDPR compliance)
  Future<SupabaseResponse<bool>> deleteUserData() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        return SupabaseResponse.error('User not authenticated');
      }

      // Delete user data (database CASCADE will handle related records)
      await _supabase
          .from(SupabaseConfig.usersTable)
          .delete()
          .eq('id', user.id);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'data_deletion_completed',
        screen: 'privacy_settings',
        additionalData: {'user_id': user.id},
      );

      // Sign out the user
      await AuthService.instance.signOut();

      return SupabaseResponse.success(true);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'privacy_settings',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Search users (for admin purposes)
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

      var queryBuilder = _supabase.from(SupabaseConfig.usersTable).select();

      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('email', '%$query%');
      }

      if (role != null) {
        queryBuilder = queryBuilder.eq('role', role.name);
      }

      if (isActive != null) {
        queryBuilder = queryBuilder.eq('is_active', isActive);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => User.fromJson(json)).toList();
    } catch (error) {
      debugPrint('Error searching users: $error');
      return [];
    }
  }

  // Update user role (admin only)
  Future<SupabaseResponse<User>> updateUserRole(
    String userId,
    UserRole newRole,
  ) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null || !currentUser.isAdmin) {
        return SupabaseResponse.error('Insufficient permissions');
      }

      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .update({
            'role': newRole.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      final updatedUser = User.fromJson(response);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'user_role_updated',
        screen: 'admin_panel',
        additionalData: {
          'target_user_id': userId,
          'new_role': newRole.name,
          'admin_user_id': currentUser.id,
        },
      );

      return SupabaseResponse.success(updatedUser);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'admin_panel',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Deactivate user account (admin only)
  Future<SupabaseResponse<bool>> deactivateUser(String userId) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null || !currentUser.isAdmin) {
        return SupabaseResponse.error('Insufficient permissions');
      }

      await _supabase
          .from(SupabaseConfig.usersTable)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await AnalyticsService.instance.trackUserInteraction(
        action: 'user_deactivated',
        screen: 'admin_panel',
        additionalData: {
          'target_user_id': userId,
          'admin_user_id': currentUser.id,
        },
      );

      return SupabaseResponse.success(true);
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'user_management_error',
        errorMessage: error.toString(),
        screen: 'admin_panel',
      );
      return SupabaseResponse.error(error.toString());
    }
  }

  // Private helper methods

  Future<SupabaseResponse<UserPreferences>> _createDefaultPreferences(
    String userId,
  ) async {
    try {
      final defaultPreferences = {
        'user_id': userId,
        'content_categories': <String>[],
        'platform_priorities': {
          'youtube': 1,
          'instagram': 2,
          'tiktok': 3,
          'facebook': 4,
        },
        'notification_settings': const NotificationSettings().toJson(),
        'privacy_settings': const PrivacySettings().toJson(),
        'ai_recommendations_enabled': true,
        'mature_content_enabled': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseConfig.userPreferencesTable)
          .insert(defaultPreferences)
          .select()
          .single();

      final preferences = UserPreferences.fromJson(response);
      return SupabaseResponse.success(preferences);
    } catch (error) {
      return SupabaseResponse.error(error.toString());
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
