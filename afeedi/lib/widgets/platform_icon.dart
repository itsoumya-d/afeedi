import 'package:flutter/material.dart';

/// A widget that displays the appropriate icon for a content platform
class PlatformIcon extends StatelessWidget {
  final String platform;
  final double size;
  final Color? color;
  
  const PlatformIcon({
    Key? key,
    required this.platform,
    this.size = 24.0,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.8);
    
    // Return the appropriate icon based on platform
    switch (platform.toLowerCase()) {
      case 'youtube':
        return _buildPlatformIcon(Icons.play_circle_filled, Colors.red);
      case 'netflix':
        return _buildPlatformIcon(Icons.movie, Color(0xFFE50914));
      case 'spotify':
        return _buildPlatformIcon(Icons.headset, Color(0xFF1DB954));
      case 'tiktok':
        return _buildPlatformIcon(Icons.music_video, Colors.black);
      case 'instagram':
        return _buildPlatformIcon(Icons.camera_alt, Color(0xFFE1306C));
      case 'twitter':
      case 'x':
        return _buildPlatformIcon(Icons.chat_bubble_outline, Color(0xFF1DA1F2));
      case 'facebook':
        return _buildPlatformIcon(Icons.facebook, Color(0xFF1877F2));
      case 'twitch':
        return _buildPlatformIcon(Icons.videogame_asset, Color(0xFF9146FF));
      case 'medium':
        return _buildPlatformIcon(Icons.article, Colors.black);
      case 'linkedin':
        return _buildPlatformIcon(Icons.work, Color(0xFF0A66C2));
      case 'pinterest':
        return _buildPlatformIcon(Icons.push_pin, Color(0xFFE60023));
      case 'reddit':
        return _buildPlatformIcon(Icons.forum, Color(0xFFFF4500));
      case 'discord':
        return _buildPlatformIcon(Icons.headset_mic, Color(0xFF5865F2));
      case 'apple':
      case 'apple music':
      case 'apple podcasts':
        return _buildPlatformIcon(Icons.music_note, Colors.pink);
      case 'amazon':
      case 'amazon prime':
        return _buildPlatformIcon(Icons.video_library, Color(0xFF00A8E1));
      case 'hulu':
        return _buildPlatformIcon(Icons.live_tv, Color(0xFF3DBB3D));
      case 'disney+':
      case 'disney plus':
        return _buildPlatformIcon(Icons.movie_filter, Color(0xFF113CCF));
      case 'hbo':
      case 'hbo max':
        return _buildPlatformIcon(Icons.movie, Color(0xFF5822B4));
      case 'vimeo':
        return _buildPlatformIcon(Icons.videocam, Color(0xFF1AB7EA));
      case 'soundcloud':
        return _buildPlatformIcon(Icons.cloud, Color(0xFFFF7700));
      case 'udemy':
      case 'coursera':
      case 'edx':
        return _buildPlatformIcon(Icons.school, Color(0xFF02B3E4));
      default:
        return _buildPlatformIcon(Icons.public, defaultColor);
    }
  }
  
  Widget _buildPlatformIcon(IconData icon, Color iconColor) {
    return Icon(
      icon,
      size: size,
      color: color ?? iconColor,
    );
  }
}