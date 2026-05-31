import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/att_service.dart';
import '../services/local_auth_service.dart';
import '../services/navigation_service.dart';
import '../services/notification_service.dart';
import '../services/locale_service.dart';
import '../services/subscription_service.dart';
import '../widgets/common/language_selector_sheet.dart';
import '../main.dart' show themeModeNotifier;

/// Settings screen — grouped sections with SwitchListTile, dropdown tiles,
/// and navigation tiles (chevron_right).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoplayEnabled = true;
  bool _dataSaverMode = false;
  bool _darkMode = true;
  bool _analyticsEnabled = true;
  bool _personalizedAdsEnabled = true;
  String _videoQuality = 'Auto';
  String _contentLanguage = 'English';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    AnalyticsService.instance.trackUserInteraction(
      action: 'screen_view',
      screen: 'settings',
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('setting_notifications') ?? true;
        _autoplayEnabled = prefs.getBool('setting_autoplay') ?? true;
        _dataSaverMode = prefs.getBool('setting_data_saver') ?? false;
        _darkMode = prefs.getBool('setting_dark_mode') ?? true;
        _analyticsEnabled = prefs.getBool('setting_analytics') ?? true;
        _personalizedAdsEnabled =
            prefs.getBool('setting_personalized_ads') ?? true;
        _videoQuality = prefs.getString('setting_video_quality') ?? 'Auto';
        _contentLanguage = prefs.getString('setting_language') ?? 'English';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0B1E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildPremiumBanner(context),

          // ── PLAYBACK ────────────────────────────────────────────────
          _sectionHeader(AppLocalizations.of(context)?.playback ?? 'Playback'),
          SwitchListTile(
            secondary: const Icon(
              Icons.play_circle_outline,
              color: Colors.white70,
            ),
            title: Text(
              AppLocalizations.of(context)?.autoplay ?? 'Autoplay',
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.autoplayHint ??
                  'Automatically play next video',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _autoplayEnabled,
            onChanged: (v) {
              setState(() => _autoplayEnabled = v);
              _saveBool('setting_autoplay', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          _dropdownTile(
            icon: Icons.hd,
            title:
                AppLocalizations.of(context)?.videoQuality ?? 'Video Quality',
            value: _videoQuality,
            options: ['Auto', '1080p', '720p', '480p', '360p'],
            onChanged: (v) {
              setState(() => _videoQuality = v ?? 'Auto');
              _saveString('setting_video_quality', v ?? 'Auto');
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.data_saver_on, color: Colors.white70),
            title: Text(
              AppLocalizations.of(context)?.dataSaver ?? 'Data Saver',
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.dataSaverHint ??
                  'Reduce data usage while streaming',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _dataSaverMode,
            onChanged: (v) {
              setState(() => _dataSaverMode = v);
              _saveBool('setting_data_saver', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── NOTIFICATIONS ────────────────────────────────────────────
          _sectionHeader(AppLocalizations.of(context)!.notifications_setting),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_outlined,
              color: Colors.white70,
            ),
            title: Text(
              AppLocalizations.of(context)?.pushNotifications ??
                  'Push Notifications',
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.pushNotificationsHint ??
                  'New content from followed creators',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _notificationsEnabled,
            onChanged: (v) async {
              setState(() => _notificationsEnabled = v);
              await _saveBool('setting_notifications', v);
              if (v) {
                await NotificationService.instance
                    .schedulePersonalizedNotifications();
              }
              // cancelAllNotifications not yet exposed; preference saved above is enough to suppress future scheduling
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── APPEARANCE ───────────────────────────────────────────────
          _sectionHeader(
            AppLocalizations.of(context)?.appearance ?? 'Appearance',
          ),
          SwitchListTile(
            secondary: const Icon(
              Icons.dark_mode_outlined,
              color: Colors.white70,
            ),
            title: Text(
              AppLocalizations.of(context)!.darkMode,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.darkModeHint ??
                  'Use dark theme throughout the app',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveBool('setting_dark_mode', v);
              themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          ListenableBuilder(
            listenable: LocaleService.instance,
            builder: (context, _) {
              final currentCode = LocaleService.instance.locale.languageCode;
              final lang = LocaleService.supportedLanguages.firstWhere(
                (l) => l['code'] == currentCode,
                orElse: () => LocaleService.supportedLanguages.first,
              );
              return _navTile(
                icon: Icons.translate,
                title:
                    AppLocalizations.of(context)?.appLanguage ?? 'App Language',
                subtitle: '${lang["flag"]} ${lang["nativeName"]}',
                onTap: () => LanguageSelectorSheet.show(context),
              );
            },
          ),
          _dropdownTile(
            icon: Icons.language,
            title:
                AppLocalizations.of(context)?.contentLanguage ??
                'Content Language',
            value: _contentLanguage,
            options: [
              'English',
              'Hindi',
              'Spanish',
              'Portuguese',
              'French',
              'German',
              'Arabic',
              'Indonesian',
              'Japanese',
              'Korean',
              'Chinese (Simplified)',
              'Russian',
            ],
            onChanged: (v) {
              setState(() => _contentLanguage = v ?? 'English');
              _saveString('setting_language', v ?? 'English');
            },
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── LIBRARY ──────────────────────────────────────────────────
          _sectionHeader(AppLocalizations.of(context)?.library ?? 'Library'),
          _navTile(
            icon: Icons.bookmark_outline,
            title: AppLocalizations.of(context)?.bookmarks ?? 'Bookmarks',
            subtitle:
                AppLocalizations.of(context)?.savedVideos ?? 'Saved videos',
            onTap: () => Navigator.pushNamed(context, AppRoutes.bookmarks),
          ),
          _navTile(
            icon: Icons.history,
            title:
                AppLocalizations.of(context)?.watchHistory ?? 'Watch History',
            subtitle:
                AppLocalizations.of(context)?.previouslyWatchedVideos ??
                'Previously watched videos',
            onTap: () => Navigator.pushNamed(context, AppRoutes.history),
          ),
          _navTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Invite Friends',
            subtitle: 'Get 7 days Pro free for every friend who joins',
            onTap: () => Navigator.pushNamed(context, AppRoutes.referral),
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── PRIVACY & DATA ───────────────────────────────────────────
          _sectionHeader(
            AppLocalizations.of(context)?.privacyAndData ?? 'Privacy & Data',
          ),
          SwitchListTile(
            secondary: const Icon(
              Icons.analytics_outlined,
              color: Colors.white70,
            ),
            title: Text(
              AppLocalizations.of(context)?.usageAnalytics ?? 'Usage Analytics',
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.usageAnalyticsHint ??
                  'Help improve the app with anonymous data',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            value: _analyticsEnabled,
            onChanged: (v) {
              setState(() => _analyticsEnabled = v);
              _saveBool('setting_analytics', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          SwitchListTile(
            secondary: const Icon(
              Icons.ads_click_outlined,
              color: Colors.white70,
            ),
            title: const Text(
              'Personalized Ads',
              style: TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text(
              'Show ads relevant to your interests (GDPR/CCPA)',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            value: _personalizedAdsEnabled,
            onChanged: (v) {
              setState(() => _personalizedAdsEnabled = v);
              _saveBool('setting_personalized_ads', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          if (Platform.isIOS)
            _navTile(
              icon: Icons.track_changes_outlined,
              title: 'Ad Tracking Permission',
              subtitle: 'Manage iOS App Tracking Transparency',
              onTap: () async {
                await AttService.requestTrackingIfNeeded();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tracking permission updated'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          _navTile(
            icon: Icons.delete_outline,
            title:
                AppLocalizations.of(context)?.clearWatchHistory ??
                'Clear Watch History',
            subtitle:
                AppLocalizations.of(context)?.clearWatchHistoryHint ??
                'Remove all watched videos from history',
            iconColor: Colors.orange,
            onTap: _confirmClearHistory,
          ),
          _navTile(
            icon: Icons.download_done_outlined,
            title: AppLocalizations.of(context)?.clearCache ?? 'Clear Cache',
            subtitle:
                AppLocalizations.of(context)?.clearCacheHint ??
                'Free up storage space',
            onTap: _clearCache,
          ),
          _navTile(
            icon: Icons.tune_outlined,
            title: 'Reset Personalization',
            subtitle:
                'Clear genre preferences and restart feed personalization',
            iconColor: Colors.orange,
            onTap: _confirmResetPersonalization,
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── ACCOUNT ──────────────────────────────────────────────────
          _sectionHeader(AppLocalizations.of(context)?.account ?? 'Account'),
          _navTile(
            icon: Icons.person_outline,
            title: AppLocalizations.of(context)?.editProfile ?? 'Edit Profile',
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          _navTile(
            icon: Icons.lock_outline,
            title:
                AppLocalizations.of(context)?.changePassword ??
                'Change Password',
            onTap: _showChangePasswordDialog,
          ),
          _navTile(
            icon: Icons.logout,
            title: AppLocalizations.of(context)?.signOut ?? 'Sign Out',
            iconColor: const Color(0xFFFF6B6B),
            titleColor: const Color(0xFFFF6B6B),
            onTap: _confirmSignOut,
            showChevron: false,
          ),
          _navTile(
            icon: Icons.delete_forever,
            title:
                AppLocalizations.of(context)?.deleteAccount ?? 'Delete Account',
            iconColor: Colors.red,
            titleColor: Colors.red,
            onTap: _confirmDeleteAccount,
            showChevron: false,
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── ABOUT ────────────────────────────────────────────────────
          _sectionHeader(AppLocalizations.of(context)?.about ?? 'About'),
          _navTile(
            icon: Icons.info_outline,
            title: AppLocalizations.of(context)?.appVersion ?? 'App Version',
            subtitle: '1.0.0 (Build 1)',
            onTap: null,
            showChevron: false,
          ),
          _navTile(
            icon: Icons.privacy_tip_outlined,
            title: AppLocalizations.of(context)!.privacyPolicy,
            onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
          ),
          _navTile(
            icon: Icons.description_outlined,
            title:
                AppLocalizations.of(context)?.termsOfService ??
                'Terms of Service',
            onTap: () => Navigator.pushNamed(context, AppRoutes.termsOfService),
          ),

          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  // ── Premium banner ─────────────────────────────────────────────────

  Widget _buildPremiumBanner(BuildContext context) {
    return ListenableBuilder(
      listenable: SubscriptionService.instance,
      builder: (context, _) {
        final isPremium = SubscriptionService.instance.isPremium;
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPremium
                    ? [const Color(0xFF003A2A), const Color(0xFF0A2A1A)]
                    : [const Color(0xFF003A4A), const Color(0xFF2A1A4A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isPremium ? Colors.green : const Color(0xFF00D4FF))
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPremium ? Icons.verified : Icons.bolt,
                  color: isPremium ? Colors.green : const Color(0xFF00D4FF),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium
                            ? (AppLocalizations.of(context)?.afeediProActive ??
                                  'Afeedi Pro — Active')
                            : (AppLocalizations.of(context)?.upgradeToPro ??
                                  'Upgrade to Pro'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPremium
                            ? (AppLocalizations.of(context)?.proFeatures ??
                                  'Ad-free · Unlimited saves · AI feed')
                            : (AppLocalizations.of(context)?.freeFeatures ??
                                  'Ad-free, AI feed, unlimited saves'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPremium ? Colors.green : const Color(0xFF00D4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPremium
                        ? (AppLocalizations.of(context)?.manage ?? 'Manage')
                        : (AppLocalizations.of(context)?.seePlans ??
                              'See Plans'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Section header ─────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Dropdown tile ──────────────────────────────────────────────────

  Widget _dropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF1A1A2E),
        style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 14),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ── Navigation tile ────────────────────────────────────────────────

  Widget _navTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    final isDangerous =
        titleColor == const Color(0xFFFF6B6B) || titleColor == Colors.red;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor ?? Colors.white70, size: 22),
      title: isDangerous
          ? TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : Text(
              title,
              style: TextStyle(color: titleColor ?? Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: (onTap != null && showChevron && !isDangerous)
          ? const Icon(Icons.chevron_right, color: Colors.white38)
          : null,
      onTap: isDangerous ? null : onTap,
    );
  }

  // ── Dialogs & actions ──────────────────────────────────────────────

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          AppLocalizations.of(context)?.clearWatchHistory ??
              'Clear Watch History',
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          AppLocalizations.of(context)?.clearHistoryConfirm ??
              'This will remove all videos from your watch history. This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              final keys = prefs
                  .getKeys()
                  .where(
                    (k) =>
                        k.startsWith('watch_progress_') ||
                        k.startsWith('watched_at_') ||
                        k == 'watched_ids',
                  )
                  .toList();
              for (final key in keys) await prefs.remove(key);
              await prefs.remove('watched_ids');
              await prefs.setInt('stat_videos_watched', 0);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                            context,
                          )?.watchHistoryClearedSnackbar ??
                          'Watch history cleared',
                    ),
                    backgroundColor: const Color(0xFF1A1A2E),
                  ),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)?.clear ?? 'Clear',
              style: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    PaintingBinding.instance.imageCache.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.cacheClearedSnackbar ??
                'Cache cleared successfully',
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmResetPersonalization() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Reset Personalization?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This clears your saved genre preferences and watch history so Afeedi can re-learn your tastes from scratch.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_genres');
      await prefs.remove('onboarding_selected_genres');
      await prefs.remove('onboarding_completed');
      await prefs.remove('watched_ids');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Personalization reset. Restart the app to redo onboarding.',
            ),
            backgroundColor: Color(0xFF1A1A2E),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _showChangePasswordDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLocalizations.of(context)?.changePassword ?? 'Change Password',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _pwField(
                  currentPwController,
                  AppLocalizations.of(context)?.currentPassword ??
                      'Current Password',
                ),
                const SizedBox(height: 12),
                _pwField(
                  newPwController,
                  AppLocalizations.of(context)?.newPassword ?? 'New Password',
                  validator: (v) {
                    if (v == null || v.length < 8)
                      return AppLocalizations.of(context)?.minEightChars ??
                          'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _pwField(
                  confirmPwController,
                  AppLocalizations.of(context)?.confirmNewPassword ??
                      'Confirm New Password',
                  validator: (v) {
                    if (v != newPwController.text)
                      return AppLocalizations.of(
                            context,
                          )?.passwordsDoNotMatch ??
                          'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(context)?.cancel ?? 'Cancel',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await LocalAuthService.instance.changePassword(
                  currentPassword: currentPwController.text,
                  newPassword: newPwController.text,
                );
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                              context,
                            )?.passwordChangedSuccessfully ??
                            'Password changed successfully',
                      ),
                    ),
                  );
                } else {
                  setDialogState(
                    () => errorText =
                        AppLocalizations.of(
                          context,
                        )?.currentPasswordIncorrect ??
                        'Current password is incorrect',
                  );
                }
              },
              child: Text(
                AppLocalizations.of(context)?.update ?? 'Update',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00D4FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator:
          validator ??
          (v) {
            if (v == null || v.isEmpty)
              return AppLocalizations.of(context)?.required ?? 'Required';
            return null;
          },
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          AppLocalizations.of(context)?.signOut ?? 'Sign Out',
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          AppLocalizations.of(context)?.signOutConfirm ??
              'Are you sure you want to sign out?',
          style: const TextStyle(color: Colors.white70),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalAuthService.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.welcome,
                  (_) => false,
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)?.signOut ?? 'Sign Out',
              style: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          AppLocalizations.of(context)?.deleteAccount ?? 'Delete Account',
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          AppLocalizations.of(context)?.deleteAccountConfirm ??
              'Are you sure? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalAuthService.instance.deleteAccount();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.welcome,
                  (route) => false,
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)?.delete ?? 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
