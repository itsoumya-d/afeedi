import 'package:flutter/material.dart';
import '../../models/content_model.dart';

class PlatformBrandingWidget extends StatelessWidget {
  final PlatformType platform;
  final double size;
  final bool showLabel;
  final Color? backgroundColor;
  
  const PlatformBrandingWidget({
    super.key,
    required this.platform,
    this.size = 32,
    this.showLabel = false,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final platformData = _getPlatformData(platform);
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor ?? platformData['color'].withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            platformData['icon'],
            size: size,
            color: Colors.white,
          ),
          if (showLabel) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              platformData['name'],
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Map<String, dynamic> _getPlatformData(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return {
          'name': 'YouTube',
          'icon': Icons.play_circle_filled,
          'color': const Color(0xFFFF0000),
        };
      case PlatformType.instagram:
        return {
          'name': 'Instagram',
          'icon': Icons.camera_alt,
          'color': const Color(0xFFE4405F),
        };
      case PlatformType.tiktok:
        return {
          'name': 'TikTok',
          'icon': Icons.music_note,
          'color': const Color(0xFF000000),
        };
      case PlatformType.facebook:
        return {
          'name': 'Facebook',
          'icon': Icons.facebook,
          'color': const Color(0xFF1877F2),
        };
    }
  }
}

// Platform logo widget with SVG support
class PlatformLogoWidget extends StatelessWidget {
  final PlatformType platform;
  final double size;
  final bool showBackground;
  
  const PlatformLogoWidget({
    super.key,
    required this.platform,
    this.size = 40,
    this.showBackground = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final platformData = _getPlatformData(platform);
    
    Widget logoWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: showBackground ? platformData['color'] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        platformData['icon'],
        size: size * 0.6,
        color: showBackground ? Colors.white : platformData['color'],
      ),
    );
    
    return logoWidget;
  }
  
  Map<String, dynamic> _getPlatformData(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return {
          'icon': Icons.play_circle_filled,
          'color': const Color(0xFFFF0000),
        };
      case PlatformType.instagram:
        return {
          'icon': Icons.camera_alt,
          'color': const Color(0xFFE4405F),
        };
      case PlatformType.tiktok:
        return {
          'icon': Icons.music_note,
          'color': const Color(0xFF000000),
        };
      case PlatformType.facebook:
        return {
          'icon': Icons.facebook,
          'color': const Color(0xFF1877F2),
        };
    }
  }
}

// Platform attribution widget for content
class PlatformAttributionWidget extends StatelessWidget {
  final PlatformType platform;
  final String? creatorName;
  final String? creatorAvatar;
  final VoidCallback? onCreatorTap;
  
  const PlatformAttributionWidget({
    super.key,
    required this.platform,
    this.creatorName,
    this.creatorAvatar,
    this.onCreatorTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformLogoWidget(
            platform: platform,
            size: 20,
            showBackground: false,
          ),
          const SizedBox(width: 8),
          if (creatorName != null) ...<Widget>[
            GestureDetector(
              onTap: onCreatorTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (creatorAvatar != null) ...<Widget>[
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(creatorAvatar!),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    creatorName!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...<Widget>[
            Text(
              _getPlatformName(platform),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _getPlatformName(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return 'YouTube';
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.tiktok:
        return 'TikTok';
      case PlatformType.facebook:
        return 'Facebook';
    }
  }
}