import 'package:flutter/material.dart';

class CreateContentScreen extends StatelessWidget {
  const CreateContentScreen({super.key});

  static const _platforms = [
    _PlatformInfo(
      name: 'YouTube',
      icon: Icons.play_circle_outline,
      color: Color(0xFFFF0000),
    ),
    _PlatformInfo(
      name: 'Instagram',
      icon: Icons.camera_alt,
      color: Color(0xFFE4405F),
    ),
    _PlatformInfo(
      name: 'TikTok',
      icon: Icons.music_note,
      color: Color(0xFF69C9D0),
    ),
    _PlatformInfo(
      name: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
    ),
  ];

  void _showConnectDialog(BuildContext context, String platformName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Connect $platformName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '$platformName connection coming soon. '
          'Your feed will automatically personalize when connected.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Connect Your Platforms',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Connect Your Platforms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Link your accounts to personalize your feed',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _platforms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final platform = _platforms[index];
                  return _PlatformCard(
                    platform: platform,
                    onConnect: () => _showConnectDialog(context, platform.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformInfo {
  final String name;
  final IconData icon;
  final Color color;

  const _PlatformInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _PlatformCard extends StatelessWidget {
  final _PlatformInfo platform;
  final VoidCallback onConnect;

  const _PlatformCard({required this.platform, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: platform.color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: platform.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(platform.icon, color: platform.color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Not connected',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: platform.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
            ),
            child: const Text(
              'Connect',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
