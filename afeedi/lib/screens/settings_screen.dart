import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_auth_service.dart';
import '../services/navigation_service.dart';
import '../main.dart' show themeModeNotifier;

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
        _notificationsEnabled = prefs.getBool('setting_notifications') ?? true;
        _autoplayEnabled = prefs.getBool('setting_autoplay') ?? true;
        _dataSaverMode = prefs.getBool('setting_data_saver') ?? false;
        _darkMode = prefs.getBool('setting_dark_mode') ?? true;
        _analyticsEnabled = prefs.getBool('setting_analytics') ?? true;
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        children: [
          _sectionHeader('Playback'),
          _switchTile(
            icon: Icons.play_circle_outline,
            title: 'Autoplay',
            subtitle: 'Automatically play next video',
            value: _autoplayEnabled,
            onChanged: (v) { setState(() => _autoplayEnabled = v); _saveBool('setting_autoplay', v); },
          ),
          _dropdownTile(
            icon: Icons.hd,
            title: 'Video Quality',
            value: _videoQuality,
            options: ['Auto', '1080p', '720p', '480p', '360p'],
            onChanged: (v) { setState(() => _videoQuality = v ?? 'Auto'); _saveString('setting_video_quality', v ?? 'Auto'); },
          ),
          _switchTile(
            icon: Icons.data_saver_on,
            title: 'Data Saver',
            subtitle: 'Reduce data usage while streaming',
            value: _dataSaverMode,
            onChanged: (v) { setState(() => _dataSaverMode = v); _saveBool('setting_data_saver', v); },
          ),
          const Divider(color: Colors.white10, height: 1),

          _sectionHeader('Notifications'),
          _switchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'New content from followed creators',
            value: _notificationsEnabled,
            onChanged: (v) { setState(() => _notificationsEnabled = v); _saveBool('setting_notifications', v); },
          ),
          const Divider(color: Colors.white10, height: 1),

          _sectionHeader('Appearance'),
          _switchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Use dark theme throughout the app',
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveBool('setting_dark_mode', v);
              themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          _dropdownTile(
            icon: Icons.language,
            title: 'Content Language',
            value: _contentLanguage,
            options: ['English', 'Spanish', 'French', 'German', 'Japanese', 'Hindi'],
            onChanged: (v) { setState(() => _contentLanguage = v ?? 'English'); _saveString('setting_language', v ?? 'English'); },
          ),
          const Divider(color: Colors.white10, height: 1),

          _sectionHeader('Privacy & Data'),
          _switchTile(
            icon: Icons.analytics_outlined,
            title: 'Usage Analytics',
            subtitle: 'Help improve the app with anonymous data',
            value: _analyticsEnabled,
            onChanged: (v) { setState(() => _analyticsEnabled = v); _saveBool('setting_analytics', v); },
          ),
          _tappableTile(
            icon: Icons.delete_outline,
            title: 'Clear Watch History',
            subtitle: 'Remove all watched videos from history',
            iconColor: Colors.orange,
            onTap: _confirmClearHistory,
          ),
          _tappableTile(
            icon: Icons.download_done_outlined,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: _clearCache,
          ),
          const Divider(color: Colors.white10, height: 1),

          _sectionHeader('Account'),
          _tappableTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          _tappableTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _showChangePasswordDialog(),
          ),
          _tappableTile(
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: const Color(0xFFFF6B6B),
            titleColor: const Color(0xFFFF6B6B),
            onTap: _confirmSignOut,
          ),
          const Divider(color: Colors.white10, height: 1),

          _sectionHeader('About'),
          _tappableTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0 (Build 1)',
            onTap: null,
          ),
          _tappableTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _tappableTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00D4FF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00D4FF),
        activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
        inactiveTrackColor: Colors.white12,
        inactiveThumbColor: Colors.white38,
      ),
    );
  }

  Widget _dropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF1A1A2E),
        style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 14),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _tappableTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white70, size: 22),
      title: Text(title, style: TextStyle(color: titleColor ?? Colors.white, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: Colors.white24) : null,
      onTap: onTap,
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Clear Watch History', style: TextStyle(color: Colors.white)),
        content: const Text('This will remove all videos from your watch history. This action cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Watch history cleared'), backgroundColor: Color(0xFF1A1A2E)),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Color(0xFFFF6B6B))),
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
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: const Text('Password change is managed through your connected account provider.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00D4FF))),
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
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalAuthService.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}
