import 'package:flutter/material.dart';

class PlatformConnection extends StatelessWidget {
  final Map<String, bool> platformConnections;
  final Function(String) onPlatformConnect;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const PlatformConnection({
    super.key,
    required this.platformConnections,
    required this.onPlatformConnect,
    required this.onSkip,
    required this.onContinue,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlatformList(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformList() {
    final platforms = [
      {'name': 'YouTube', 'icon': Icons.play_circle_fill, 'color': const Color(0xFFFF0000)},
      {'name': 'Instagram', 'icon': Icons.camera_alt, 'color': const Color(0xFFE4405F)},
      {'name': 'TikTok', 'icon': Icons.music_note, 'color': const Color(0xFF000000)},
      {'name': 'Facebook', 'icon': Icons.facebook, 'color': const Color(0xFF1877F2)},
      {'name': 'Twitter', 'icon': Icons.alternate_email, 'color': const Color(0xFF1DA1F2)},
    ];

    return Column(
      children: platforms.map((platform) => _buildPlatformTile(platform)).toList(),
    );
  }

  Widget _buildPlatformTile(Map<String, dynamic> platform) {
    final String name = platform['name'];
    final IconData icon = platform['icon'];
    final Color color = platform['color'];
    final bool isConnected = platformConnections[name] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPlatformConnect(name),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isConnected 
                  ? color.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected 
                    ? color.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isConnected ? 'Connected' : 'Connect to sync your content',
                        style: TextStyle(
                          color: isConnected 
                              ? color
                              : Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isConnected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConnected ? color : Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: isConnected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasConnections = platformConnections.values.any((connected) => connected);
    
    return Column(
      children: [
        if (hasConnections)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue with connected platforms ✨',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Skip for now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}