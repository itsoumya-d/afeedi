import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class PlatformSelectionWidget extends StatefulWidget {
  final Map<String, double> platformPriorities;
  final Function(Map<String, double>) onPlatformPrioritiesChanged;

  const PlatformSelectionWidget({
    Key? key,
    required this.platformPriorities,
    required this.onPlatformPrioritiesChanged,
  }) : super(key: key);

  @override
  State<PlatformSelectionWidget> createState() => _PlatformSelectionWidgetState();
}

class _PlatformSelectionWidgetState extends State<PlatformSelectionWidget> {
  late Map<String, double> _platformPriorities;
  
  // Platform information with icons and colors
  final List<Map<String, dynamic>> _platforms = [
    {
      'name': 'YouTube',
      'icon': Icons.play_circle_filled,
      'color': const Color(0xFFFF0000),
      'logo': 'assets/images/platforms/youtube_logo.png',
    },
    {
      'name': 'TikTok',
      'icon': Icons.music_note,
      'color': const Color(0xFF000000),
      'logo': 'assets/images/platforms/tiktok_logo.png',
    },
    {
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'color': const Color(0xFFE1306C),
      'logo': 'assets/images/platforms/instagram_logo.png',
    },
    {
      'name': 'Facebook',
      'icon': Icons.facebook,
      'color': const Color(0xFF1877F2),
      'logo': 'assets/images/platforms/facebook_logo.png',
    },
    {
      'name': 'Twitter',
      'icon': Icons.chat,
      'color': const Color(0xFF1DA1F2),
      'logo': 'assets/images/platforms/twitter_logo.png',
    },
    {
      'name': 'Twitch',
      'icon': Icons.videogame_asset,
      'color': const Color(0xFF6441A4),
      'logo': 'assets/images/platforms/twitch_logo.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _platformPriorities = Map.from(widget.platformPriorities);
    
    // Initialize any missing platforms with default value
    for (final platform in _platforms) {
      final name = platform['name'];
      if (!_platformPriorities.containsKey(name)) {
        _platformPriorities[name] = 0.5; // Default priority (50%)
      }
    }
  }

  void _updatePlatformPriority(String platform, double value) {
    setState(() {
      _platformPriorities[platform] = value;
      widget.onPlatformPrioritiesChanged(_platformPriorities);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioritize your favorite platforms',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Drag the sliders to set how often you want to see content from each platform',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Platform priority sliders
        ..._platforms.asMap().entries.map((entry) {
          final index = entry.key;
          final platform = entry.value;
          final name = platform['name'];
          final icon = platform['icon'];
          final color = platform['color'];
          
          return _buildPlatformPrioritySlider(
            name: name,
            icon: icon,
            color: color,
            value: _platformPriorities[name] ?? 0.5,
            index: index,
          );
        }).toList(),
        
        const SizedBox(height: 24),
        
        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your platform preferences help us balance content from different sources in your feed.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformPrioritySlider({
    required String name,
    required IconData icon,
    required Color color,
    required double value,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(value).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityLabel(value),
                  style: TextStyle(
                    color: _getPriorityColor(value),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              divisions: 10,
              onChanged: (newValue) {
                _updatePlatformPriority(name, newValue);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (100 * index).ms).slideX(begin: 0.05, end: 0);
  }

  String _getPriorityLabel(double value) {
    if (value < 0.2) return 'Rarely';
    if (value < 0.4) return 'Sometimes';
    if (value < 0.6) return 'Average';
    if (value < 0.8) return 'Often';
    return 'Frequently';
  }

  Color _getPriorityColor(double value) {
    if (value < 0.2) return Colors.grey;
    if (value < 0.4) return Colors.blue;
    if (value < 0.6) return Colors.green;
    if (value < 0.8) return Colors.orange;
    return Colors.red;
  }
}