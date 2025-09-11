import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/navigation_service.dart';

class SourcePreferenceScreen extends StatefulWidget {
  const SourcePreferenceScreen({super.key});

  @override
  State<SourcePreferenceScreen> createState() => _SourcePreferenceScreenState();
}

class _SourcePreferenceScreenState extends State<SourcePreferenceScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  Map<String, double> _platformPriorities = {
    'youtube': 80.0,
    'instagram': 60.0,
    'tiktok': 40.0,
    'facebook': 30.0,
  };
  
  bool _showAttribution = true;
  bool _showCreatorInfo = true;
  String _attributionStyle = 'overlay';
  
  final List<Map<String, dynamic>> _platforms = [
    {
      'id': 'youtube',
      'name': 'YouTube',
      'icon': Icons.play_circle_fill,
      'color': Color(0xFFFF0000),
      'description': 'Long-form videos, tutorials, entertainment',
    },
    {
      'id': 'instagram',
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Color(0xFFE4405F),
      'description': 'Stories, reels, lifestyle content',
    },
    {
      'id': 'tiktok',
      'name': 'TikTok',
      'icon': Icons.music_video,
      'color': Color(0xFF000000),
      'description': 'Short videos, trends, entertainment',
    },
    {
      'id': 'facebook',
      'name': 'Facebook',
      'icon': Icons.facebook,
      'color': Color(0xFF1877F2),
      'description': 'News, community content, videos',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  void _continue() {
    // Save platform preferences
    NavigationService.pushNamed('/calendar-customization');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0B1E), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlatformPrioritiesSection(),
                        const SizedBox(height: 32),
                        _buildAttributionSection(),
                        const SizedBox(height: 32),
                        _buildPreviewSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Step 3 of 4',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress indicator
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.75, // 75% progress
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Content Sources',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your content mix from different platforms',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlatformPrioritiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform Priorities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Adjust how much content you want from each platform',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        ..._platforms.map((platform) => _buildPlatformSlider(platform)),
      ],
    );
  }
  
  Widget _buildPlatformSlider(Map<String, dynamic> platform) {
    final priority = _platformPriorities[platform['id']] ?? 50.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: platform['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  platform['icon'],
                  color: platform['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      platform['description'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: platform['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${priority.round()}%',
                  style: TextStyle(
                    color: platform['color'],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: platform['color'],
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: platform['color'],
              overlayColor: platform['color'].withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: priority,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _platformPriorities[platform['id']] = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttributionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attribution Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure how creator information is displayed',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _buildAttributionToggle(
          'Show Attribution',
          'Display platform and creator information',
          _showAttribution,
          (value) => setState(() => _showAttribution = value),
        ),
        const SizedBox(height: 12),
        _buildAttributionToggle(
          'Show Creator Info',
          'Display creator name and profile',
          _showCreatorInfo,
          (value) => setState(() => _showCreatorInfo = value),
        ),
        const SizedBox(height: 16),
        const Text(
          'Attribution Style',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAttributionStyleOption('overlay', 'Overlay'),
            const SizedBox(width: 12),
            _buildAttributionStyleOption('bottom', 'Bottom'),
            const SizedBox(width: 12),
            _buildAttributionStyleOption('corner', 'Corner'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAttributionToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
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
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttributionStyleOption(String value, String label) {
    final isSelected = _attributionStyle == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _attributionStyle = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryCyan.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryCyan
                  : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryCyan : Colors.white,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'See how content will appear with your settings',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              // Mock video content
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.purple.withOpacity(0.3),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              // Attribution overlay based on settings
              if (_showAttribution) _buildAttributionPreview(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAttributionPreview() {
    Widget attributionWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_fill, color: Colors.red, size: 16),
          const SizedBox(width: 6),
          const Text(
            'YouTube',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (_showCreatorInfo) ...[
            const Text(' • ', style: TextStyle(color: Colors.white, fontSize: 12)),
            const Text(
              '@creator',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
      ),
    );
    
    switch (_attributionStyle) {
      case 'overlay':
        return Positioned(
          top: 12,
          left: 12,
          child: attributionWidget,
        );
      case 'bottom':
        return Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: attributionWidget,
        );
      case 'corner':
        return Positioned(
          top: 12,
          right: 12,
          child: attributionWidget,
        );
      default:
        return Positioned(
          top: 12,
          left: 12,
          child: attributionWidget,
        );
    }
  }
  
  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Use default settings
              NavigationService.pushNamed('/calendar-customization');
            },
            child: Text(
              'Use default settings',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}