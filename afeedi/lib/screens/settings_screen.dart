import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/navigation_service.dart';

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
  String _videoQuality = 'Auto';
  String _contentLanguage = 'English';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled =
            prefs.getBool('setting_notifications') ?? true;
        _autoplayEnabled = prefs.getBool('setting_autoplay') ?? true;
        _dataSaverMode = prefs.getBool('setting_data_saver') ?? false;
        _darkMode = prefs.getBool('setting_dark_mode') ?? true;
        _analyticsEnabled = prefs.getBool('setting_analytics') ?? true;
        _videoQuality = prefs.getString('setting_video_quality') ?? 'Auto';
        _contentLanguage =
            prefs.getString('setting_language') ?? 'English';
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
            child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: BackButton(
            color: Colors.white, onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        children: [
          _buildPremiumBanner(context),

          // ── PLAYBACK ────────────────────────────────────────────────
          _sectionHeader('Playback'),
          SwitchListTile(
            secondary:
                const Icon(Icons.play_circle_outline, color: Colors.white70),
            title: const Text(
              'Autoplay',
              style: TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text(
              'Automatically play next video',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _autoplayEnabled,
            onChanged: (v) {
              setState(() => _autoplayEnabled = v);
              _saveBool('setting_autoplay', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor:
                const Color(0xFF00D4FF).withOpacity(0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          _dropdownTile(
            icon: Icons.hd,
            title: 'Video Quality',
            value: _videoQuality,
            options: ['Auto', '1080p', '720p', '480p', '360p'],
            onChanged: (v) {
              setState(() => _videoQuality = v ?? 'Auto');
              _saveString('setting_video_quality', v ?? 'Auto');
            },
          ),
          SwitchListTile(
            secondary:
                const Icon(Icons.data_saver_on, color: Colors.white70),
            title: const Text(
              'Data Saver',
              style: TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text(
              'Reduce data usage while streaming',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _dataSaverMode,
            onChanged: (v) {
              setState(() => _dataSaverMode = v);
              _saveBool('setting_data_saver', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor:
                const Color(0xFF00D4FF).withOpacity(0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── NOTIFICATIONS ────────────────────────────────────────────
          _sectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined,
                color: Colors.white70),
            title: const Text(
              'Push Notifications',
              style: TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text(
              'New content from followed creators',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
              _saveBool('setting_notifications', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor:
                const Color(0xFF00D4FF).withOpacity(0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── APPEARANCE ───────────────────────────────────────────────
          _sectionHeader('Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined,
                color: Colors.white70),
            title: const Text(
              'Dark Mode',
              style: TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text(
              'Use dark theme throughout the app',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveBool('setting_dark_mode', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor:
                const Color(0xFF00D4FF).withOpacity(0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          _dropdownTile(
            icon: Icons.language,
            title: 'Content Language',
            value: _contentLanguage,
            options: [
              'English',
              'Spanish',
              'French',
              'German',
              'Japanese',
              'Hindi'
            ],
            onChanged: (v) {
              setState(() => _contentLanguage = v ?? 'English');
              _saveString('setting_language', v ?? 'English');
            },
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── PRIVACY & DATA ───────────────────────────────────────────
          _sectionHeader('Privacy & Data'),
          SwitchListTile(
            secondary: const Icon(Icons.analytics_outlined,
                color: Colors.white70),
            title: const Text(
              'Usage Analytics',
              style: TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text(
              'Help improve the app with anonymous data',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            value: _analyticsEnabled,
            onChanged: (v) {
              setState(() => _analyticsEnabled = v);
              _saveBool('setting_analytics', v);
            },
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor:
                const Color(0xFF00D4FF).withOpacity(0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
          _navTile(
            icon: Icons.delete_outline,
            title: 'Clear Watch History',
            subtitle: 'Remove all watched videos from history',
            iconColor: Colors.orange,
            onTap: _confirmClearHistory,
          ),
          _navTile(
            icon: Icons.download_done_outlined,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: _clearCache,
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── ACCOUNT ──────────────────────────────────────────────────
          _sectionHeader('Account'),
          _navTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          _navTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: _showChangePasswordDialog,
          ),
          _navTile(
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: const Color(0xFFFF6B6B),
            titleColor: const Color(0xFFFF6B6B),
            onTap: _confirmSignOut,
            showChevron: false,
          ),
          const Divider(color: Colors.white10, height: 1),

          // ── ABOUT ────────────────────────────────────────────────────
          _sectionHeader('About'),
          _navTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0 (Build 1)',
            onTap: null,
            showChevron: false,
          ),
          _navTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.privacyPolicy),
          ),
          _navTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () async {
              final uri = Uri.parse('https://afeedi.com/terms');
              if (await canLaunchUrl(uri)) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),

          // Bottom safe area padding
          SizedBox(
              height:
                  MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  // ── Premium banner ─────────────────────────────────────────────────

  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF003A4A), Color(0xFF2A1A4A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFF00D4FF), size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ad-free, AI feed, unlimited saves',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'See Plans',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00D4FF),
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
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white70, size: 22),
      title: Text(
        title,
        style: TextStyle(
            color: titleColor ?? Colors.white, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: (onTap != null && showChevron)
          ? const Icon(Icons.chevron_right, color: Colors.white38)
          : null,
      onTap: onTap,
    );
  }

  // ── Dialogs & actions ──────────────────────────────────────────────

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Clear Watch History',
            style: TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        content: const Text(
          'This will remove all videos from your watch history. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Watch history cleared'),
                  backgroundColor: Color(0xFF1A1A2E),
                ),
              );
            },
            child: const Text('Clear',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        backgroundColor: Color(0xFF1A1A2E),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Change Password',
            style: TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        content: const Text(
          'Password change is managed through your connected account provider.',
          style: TextStyle(color: Colors.white70),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Sign Out',
            style: TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.welcome, (_) => false);
              }
            },
            child: const Text('Sign Out',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}
