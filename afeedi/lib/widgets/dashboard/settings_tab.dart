import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Content preferences
  bool _autoplay = true;
  int _videoQuality = 1; // 0=Low, 1=Auto, 2=High
  bool _downloadOnWifi = true;

  // Notifications
  bool _pushNotifications = true;
  bool _dailyDigest = true;
  bool _trendingAlerts = false;
  bool _emailNewsletter = false;

  // Privacy & Data (GDPR)
  bool _dataCollection = true;
  bool _personalizedAds = false;

  // Appearance
  bool _darkMode = true;
  int _textSize = 1; // 0=Small, 1=Medium, 2=Large

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: const Color(0xFF1A0A3E),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildAccountSection(),
            _buildDivider(),
            _buildSectionHeader('Content Preferences', icon: Icons.play_circle_outline, color: AppTheme.primaryPink),
            _buildSettingRow(
              title: 'Autoplay Videos',
              subtitle: 'Automatically play videos when scrolling',
              trailing: _buildSwitch(_autoplay, (v) => setState(() => _autoplay = v)),
            ),
            _buildSettingRow(
              title: 'Video Quality',
              subtitle: 'Select playback quality',
              trailing: _buildSegmentedControl(
                segments: ['Low', 'Auto', 'High'],
                selected: _videoQuality,
                onChanged: (i) => setState(() => _videoQuality = i),
              ),
            ),
            _buildSettingRow(
              title: 'Download on WiFi Only',
              subtitle: 'Save mobile data by downloading on WiFi',
              trailing: _buildSwitch(_downloadOnWifi, (v) => setState(() => _downloadOnWifi = v)),
            ),
            _buildSettingRow(
              title: 'Content Language',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'English (US)',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            _buildDivider(),
            _buildSectionHeader('Notifications', icon: Icons.notifications_outlined, color: const Color(0xFFFFE66D)),
            _buildSettingRow(
              title: 'Push Notifications',
              subtitle: 'Receive alerts directly on your device',
              trailing: _buildSwitch(_pushNotifications, (v) => setState(() => _pushNotifications = v)),
            ),
            if (_pushNotifications) ...[
              _buildSubSettingRow(
                title: 'Daily Digest',
                trailing: _buildSwitch(_dailyDigest, (v) => setState(() => _dailyDigest = v)),
              ),
              _buildSubSettingRow(
                title: 'Trending Alerts',
                trailing: _buildSwitch(_trendingAlerts, (v) => setState(() => _trendingAlerts = v)),
              ),
            ],
            _buildSettingRow(
              title: 'Email Newsletter',
              subtitle: 'Weekly curated content to your inbox',
              trailing: _buildSwitch(_emailNewsletter, (v) => setState(() => _emailNewsletter = v)),
            ),
            _buildDivider(),
            _buildSectionHeader('Privacy & Data', icon: Icons.shield_outlined, color: AppTheme.primaryCyan),
            _buildSettingRow(
              title: 'Data Collection Consent',
              subtitle: 'Help us improve your recommendations',
              trailing: _buildSwitch(_dataCollection, (v) => setState(() => _dataCollection = v)),
            ),
            _buildSettingRow(
              title: 'Personalized Ads',
              subtitle: 'Show ads tailored to your interests',
              trailing: _buildSwitch(_personalizedAds, (v) => setState(() => _personalizedAds = v)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: OutlinedButton.icon(
                onPressed: _onDownloadMyData,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download My Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryCyan,
                  side: BorderSide(color: AppTheme.primaryCyan.withOpacity(0.6)),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: OutlinedButton.icon(
                onPressed: _showDeleteAccountDialog,
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('Delete My Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.6)),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildDivider(),
            _buildSectionHeader('Appearance', icon: Icons.palette_outlined, color: const Color(0xFFB47AFF)),
            _buildSettingRow(
              title: 'Dark Mode',
              subtitle: 'Use dark theme throughout the app',
              trailing: _buildSwitch(_darkMode, (v) => setState(() => _darkMode = v)),
            ),
            _buildSettingRow(
              title: 'Text Size',
              subtitle: 'Adjust reading font size',
              trailing: _buildSegmentedControl(
                segments: ['S', 'M', 'L'],
                selected: _textSize,
                onChanged: (i) => setState(() => _textSize = i),
              ),
            ),
            _buildDivider(),
            _buildSectionHeader('About', icon: Icons.info_outline, color: Colors.grey),
            _buildSettingRow(
              title: 'App Version',
              subtitle: '1.0.0 (Build 1)',
              trailing: const SizedBox.shrink(),
            ),
            _buildSettingRow(
              title: 'Privacy Policy',
              trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4), size: 20),
              onTap: () => _showSnackBar('Opening Privacy Policy…'),
            ),
            _buildSettingRow(
              title: 'Terms of Service',
              trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4), size: 20),
              onTap: () => _showSnackBar('Opening Terms of Service…'),
            ),
            _buildSettingRow(
              title: 'Rate the App',
              trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4), size: 20),
              onTap: () => _showSnackBar('Thank you! Redirecting to app store…'),
            ),
            _buildSettingRow(
              title: 'Contact Support',
              trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4), size: 20),
              onTap: () => _showSnackBar('Email us at support@afeedi.com'),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Account card at the top
  // ---------------------------------------------------------------------------
  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'AJ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alex Johnson',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'alex@email.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () => _showSnackBar('Edit Profile coming soon'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryCyan,
                      side: const BorderSide(color: AppTheme.primaryCyan),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section header
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader(String title, {IconData? icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryCyan).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color ?? AppTheme.primaryCyan),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Standard setting row
  // ---------------------------------------------------------------------------
  Widget _buildSettingRow({
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minVerticalPadding: 0,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  // ---------------------------------------------------------------------------
  // Indented sub-setting row (shown when parent toggle is ON)
  // ---------------------------------------------------------------------------
  Widget _buildSubSettingRow({required String title, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        minVerticalPadding: 0,
        title: Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        trailing: trailing,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Subtle section divider
  // ---------------------------------------------------------------------------
  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.08),
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable Switch widget
  // ---------------------------------------------------------------------------
  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF00E5FF),
      activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
      inactiveThumbColor: Colors.white.withOpacity(0.5),
      inactiveTrackColor: Colors.white.withOpacity(0.15),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact segmented control
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedControl({
    required List<String> segments,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(segments.length, (i) {
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                segments[i],
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1A0A3E) : Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  void _onDownloadMyData() {
    _showSnackBar('Your data export will be ready in 24 hours');
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion requested. You will receive a confirmation email.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2D1B69),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
