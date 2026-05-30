import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../services/local_auth_service.dart';
import '../../services/navigation_service.dart';
import '../../services/user_management_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dataCollection = prefs.getBool('setting_data_collection') ?? true;
      _personalizedAds = prefs.getBool('setting_personalized_ads') ?? false;
      _analyticsSharing = prefs.getBool('setting_analytics_sharing') ?? true;
      _locationTracking = prefs.getBool('setting_location_tracking') ?? false;
      _autoplay = prefs.getBool('setting_autoplay') ?? true;
      _downloadOnWifi = prefs.getBool('setting_download_on_wifi') ?? true;
      _highQuality = prefs.getBool('setting_high_quality') ?? false;
      _pushNotifications = prefs.getBool('setting_push_notifications') ?? true;
      _emailNotifications = prefs.getBool('setting_email_notifications') ?? false;
      _weeklyDigest = prefs.getBool('setting_weekly_digest') ?? true;
      _trendingAlerts = prefs.getBool('setting_trending_alerts') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Privacy settings
  bool _dataCollection = true;
  bool _personalizedAds = false;
  bool _analyticsSharing = true;
  bool _locationTracking = false;
  
  // Content settings
  bool _autoplay = true;
  bool _downloadOnWifi = true;
  bool _highQuality = false;
  bool _darkMode = true;
  
  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _weeklyDigest = true;
  bool _trendingAlerts = true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Container(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildPrivacySection(),
            _buildContentSection(),
            _buildNotificationSection(),
            _buildAccountSection(),
            _buildAboutSection(),
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Customize your Afeedi experience',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildQuickSettingsStats(),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsStats() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_active,
            color: AppTheme.primaryCyan,
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            'Active',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrivacySection() {
    return _buildSection(
      title: 'Privacy & Data',
      icon: Icons.security,
      iconColor: AppTheme.primaryCyan,
      children: [
        _buildToggleItem(
          title: 'Data Collection',
          subtitle: 'Allow Afeedi to collect usage data for improvements',
          value: _dataCollection,
          onChanged: (value) {
            setState(() => _dataCollection = value);
            _saveSetting('setting_data_collection', value);
          },
        ),
        _buildToggleItem(
          title: 'Personalized Ads',
          subtitle: 'Show ads based on your interests and activity',
          value: _personalizedAds,
          onChanged: (value) {
            setState(() => _personalizedAds = value);
            _saveSetting('setting_personalized_ads', value);
          },
        ),
        _buildToggleItem(
          title: 'Analytics Sharing',
          subtitle: 'Share anonymous analytics to improve the platform',
          value: _analyticsSharing,
          onChanged: (value) {
            setState(() => _analyticsSharing = value);
            _saveSetting('setting_analytics_sharing', value);
          },
        ),
        _buildToggleItem(
          title: 'Location Tracking',
          subtitle: 'Use location for content recommendations',
          value: _locationTracking,
          onChanged: (value) {
            setState(() => _locationTracking = value);
            _saveSetting('setting_location_tracking', value);
          },
        ),
        Divider(color: Colors.white.withValues(alpha: 0.06), indent: 16, endIndent: 16),
        _buildActionItem(
          title: 'Download My Data',
          subtitle: 'Get a copy of your personal data',
          icon: Icons.download,
          onTap: () => _showDataDownloadDialog(),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.06), indent: 16, endIndent: 16),
        _buildActionItem(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account and data',
          icon: Icons.delete_forever,
          iconColor: Colors.redAccent,
          isDangerous: true,
          onTap: () => _showDeleteAccountDialog(),
        ),
      ],
    );
  }
  
  Widget _buildContentSection() {
    return _buildSection(
      title: 'Content & Playback',
      icon: Icons.play_circle,
      iconColor: AppTheme.primaryPink,
      children: [
        _buildToggleItem(
          title: 'Autoplay Videos',
          subtitle: 'Automatically play videos when scrolling',
          value: _autoplay,
          onChanged: (value) => setState(() => _autoplay = value),
        ),
        _buildToggleItem(
          title: 'Download on WiFi Only',
          subtitle: 'Only download content when connected to WiFi',
          value: _downloadOnWifi,
          onChanged: (value) => setState(() => _downloadOnWifi = value),
        ),
        _buildToggleItem(
          title: 'High Quality Playback',
          subtitle: 'Use higher quality video when available',
          value: _highQuality,
          onChanged: (value) => setState(() => _highQuality = value),
        ),
        _buildToggleItem(
          title: 'Dark Mode',
          subtitle: 'Use dark theme throughout the app',
          value: _darkMode,
          onChanged: (value) => setState(() => _darkMode = value),
        ),
        _buildActionItem(
          title: 'Clear Cache',
          subtitle: 'Free up storage space by clearing cached data',
          icon: Icons.cleaning_services,
          onTap: () => _showClearCacheDialog(),
        ),
      ],
    );
  }
  
  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      iconColor: const Color(0xFFFFE66D),
      children: [
        _buildToggleItem(
          title: 'Push Notifications',
          subtitle: 'Receive notifications on your device',
          value: _pushNotifications,
          onChanged: (value) => setState(() => _pushNotifications = value),
        ),
        _buildToggleItem(
          title: 'Email Notifications',
          subtitle: 'Receive updates via email',
          value: _emailNotifications,
          onChanged: (value) => setState(() => _emailNotifications = value),
        ),
        _buildToggleItem(
          title: 'Weekly Digest',
          subtitle: 'Get a summary of your week every Sunday',
          value: _weeklyDigest,
          onChanged: (value) => setState(() => _weeklyDigest = value),
        ),
        _buildToggleItem(
          title: 'Trending Alerts',
          subtitle: 'Get notified about trending content',
          value: _trendingAlerts,
          onChanged: (value) => setState(() => _trendingAlerts = value),
        ),
      ],
    );
  }
  
  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Account',
      icon: Icons.account_circle,
      iconColor: const Color(0xFF4ECDC4),
      children: [
        _buildActionItem(
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          icon: Icons.edit,
          onTap: () => _navigateToProfile(),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.06), indent: 16, endIndent: 16),
        _buildActionItem(
          title: 'Change Password',
          subtitle: 'Update your account password',
          icon: Icons.lock,
          onTap: () => _showChangePasswordDialog(),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.06), indent: 16, endIndent: 16),
        _buildActionItem(
          title: 'Subscription',
          subtitle: 'Manage your premium subscription',
          icon: Icons.star,
          onTap: () => _navigateToSubscription(),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.06), indent: 16, endIndent: 16),
        _buildActionItem(
          title: 'Connected Accounts',
          subtitle: 'Manage linked social media accounts',
          icon: Icons.link,
          onTap: () => _showConnectedAccountsDialog(),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.06), indent: 16, endIndent: 16),
        _buildActionItem(
          title: 'Sign Out',
          subtitle: 'Sign out of your Afeedi account',
          icon: Icons.logout,
          iconColor: Colors.redAccent,
          isDangerous: true,
          onTap: () => _showSignOutDialog(),
        ),
      ],
    );
  }
  
  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: Icons.info,
      iconColor: Colors.grey,
      children: [
        _buildActionItem(
          title: 'Help & Support',
          subtitle: 'Get help or contact support',
          icon: Icons.help,
          onTap: () => _showHelpDialog(),
        ),
        _buildActionItem(
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          icon: Icons.description,
          onTap: () => _showTermsDialog(),
        ),
        _buildActionItem(
          title: 'Privacy Policy',
          subtitle: 'Learn how we protect your privacy',
          icon: Icons.privacy_tip,
          onTap: () => _showPrivacyDialog(),
        ),
        _buildActionItem(
          title: 'App Version',
          subtitle: 'v1.0.0 (Build 1)',
          icon: Icons.info_outline,
          onTap: null,
        ),
      ],
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00D4FF),
        activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
        inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
  
  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
    bool isDangerous = false,
  }) {
    final effectiveColor = iconColor ?? Colors.white.withValues(alpha: 0.7);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: effectiveColor, size: 20),
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
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      trailing: (onTap != null && !isDangerous)
          ? Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
              size: 20,
            )
          : null,
      onTap: isDangerous ? null : onTap,
    );
  }
  
  // Dialog methods
  void _showDataDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text('Download My Data', style: TextStyle(color: Colors.white)),
        content: Text(
          'Your data export includes your profile, preferences, watch history, and connected accounts. Tap Export to view and copy your data.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final response = await UserManagementService.instance.exportUserData();
              if (!mounted) return;
              if (response.success && response.data != null) {
                final jsonStr = response.data.toString();
                await Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your data has been copied to clipboard.'),
                    duration: Duration(seconds: 4),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sign in to export your data.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Export', style: TextStyle(color: AppTheme.primaryCyan)),
          ),
        ],
      ),
    );
  }
  
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await LocalAuthService.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.welcome,
                  (_) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'This action cannot be undone. All your data, history, and preferences will be permanently deleted.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await LocalAuthService.instance.deleteAccount();
              if (mounted) {
                if (success) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.welcome,
                    (_) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete account. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Clear Cache',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will free up storage space but may slow down the app temporarily.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cache clearing
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You will be redirected to change your password securely.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to password change
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showConnectedAccountsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Connected Accounts',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConnectedAccount('Google', true),
            _buildConnectedAccount('Facebook', false),
            _buildConnectedAccount('Apple', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectedAccount(String platform, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            platform,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            isConnected ? 'Connected' : 'Not Connected',
            style: TextStyle(
              color: isConnected ? AppTheme.primaryCyan : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'For support, please email us at support@afeedi.com or visit our help center.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You will be redirected to our website to view the complete terms of service.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.termsOfService);
            },
            child: const Text(
              'Open',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You will be redirected to our website to view the complete privacy policy.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.privacyPolicy);
            },
            child: const Text(
              'Open',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToProfile() {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  void _navigateToSubscription() {
    Navigator.pushNamed(context, AppRoutes.premium);
  }
}