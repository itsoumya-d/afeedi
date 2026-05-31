import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/local_auth_service.dart';
import '../../services/navigation_service.dart';
import '../../services/privacy_consent_service.dart';
import '../../services/analytics_service.dart';

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
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final granted = await PrivacyConsentService.instance.hasAnalyticsConsent();
    if (mounted) setState(() => _analyticsSharing = granted);
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
                    color: Colors.white.withOpacity(0.7),
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
        color: Colors.white.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.7),
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
          onChanged: (value) => setState(() => _dataCollection = value),
        ),
        _buildToggleItem(
          title: 'Personalized Ads',
          subtitle: 'Show ads based on your interests and activity',
          value: _personalizedAds,
          onChanged: (value) => setState(() => _personalizedAds = value),
        ),
        _buildToggleItem(
          title: 'Analytics Sharing',
          subtitle: 'Share anonymous analytics to improve the platform',
          value: _analyticsSharing,
          onChanged: (value) {
            setState(() => _analyticsSharing = value);
            PrivacyConsentService.instance.setAnalyticsConsent(value);
            AnalyticsService.instance.setConsentGranted(value);
          },
        ),
        _buildToggleItem(
          title: 'Location Tracking',
          subtitle: 'Use location for content recommendations',
          value: _locationTracking,
          onChanged: (value) => setState(() => _locationTracking = value),
        ),
        _buildActionItem(
          title: 'Download My Data',
          subtitle: 'Get a copy of your personal data',
          icon: Icons.download,
          onTap: () => _showDataDownloadDialog(),
        ),
        _buildActionItem(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account and data',
          icon: Icons.delete_forever,
          iconColor: Colors.red,
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
        _buildActionItem(
          title: 'Change Password',
          subtitle: 'Update your account password',
          icon: Icons.lock,
          onTap: () => _showChangePasswordDialog(),
        ),
        _buildActionItem(
          title: 'Subscription',
          subtitle: 'Manage your premium subscription',
          icon: Icons.star,
          onTap: () => _navigateToSubscription(),
        ),
        _buildActionItem(
          title: 'Connected Accounts',
          subtitle: 'Manage linked social media accounts',
          icon: Icons.link,
          onTap: () => _showConnectedAccountsDialog(),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryCyan,
            activeTrackColor: AppTheme.primaryCyan.withOpacity(0.3),
            inactiveThumbColor: Colors.white.withOpacity(0.5),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.white.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  // Dialog methods
  void _showDataDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Download Data',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'We\'ll prepare your data and send a download link to your email within 24 hours.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
              // TODO: Implement data download
            },
            child: const Text(
              'Request',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
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
          'This action cannot be undone. All your data — including viewing history, '
          'preferences, and connected accounts — will be permanently deleted.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: const Text(
              'Delete Permanently',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final success = await LocalAuthService.instance.deleteAccount();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted. We\'re sorry to see you go.')),
      );
      // Navigate back to welcome screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcome,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete account. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
              color: isConnected ? AppTheme.primaryCyan : Colors.white.withOpacity(0.5),
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
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
            onPressed: () async {
              Navigator.pop(context);
              await launchUrl(
                Uri.parse('https://afeedi.com/terms'),
                mode: LaunchMode.externalApplication,
              );
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
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
            onPressed: () async {
              Navigator.pop(context);
              await launchUrl(
                Uri.parse('https://afeedi.com/privacy'),
                mode: LaunchMode.externalApplication,
              );
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
  
  // Navigation methods
  void _navigateToProfile() {
    // TODO: Navigate to profile screen
  }
  
  void _navigateToSubscription() {
    // TODO: Navigate to subscription screen
  }
}