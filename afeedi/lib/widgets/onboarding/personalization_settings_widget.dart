import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class PersonalizationSettingsWidget extends StatefulWidget {
  final Map<String, dynamic> personalizationSettings;
  final Function(Map<String, dynamic>) onPersonalizationSettingsChanged;

  const PersonalizationSettingsWidget({
    Key? key,
    required this.personalizationSettings,
    required this.onPersonalizationSettingsChanged,
  }) : super(key: key);

  @override
  State<PersonalizationSettingsWidget> createState() => _PersonalizationSettingsWidgetState();
}

class _PersonalizationSettingsWidgetState extends State<PersonalizationSettingsWidget> {
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    // Initialize with default values if not provided
    _settings = Map.from(widget.personalizationSettings);
    _settings['contentDiscoveryMode'] ??= 'balanced';
    _settings['contentRefreshFrequency'] ??= 'medium';
    _settings['enableRecommendationReasoning'] ??= true;
    _settings['enableContentFiltering'] ??= true;
    _settings['enableCalendarContextualContent'] ??= false;
    _settings['enableTimeAwareRecommendations'] ??= true;
  }

  void _updateSettings(String key, dynamic value) {
    setState(() {
      _settings[key] = value;
      widget.onPersonalizationSettingsChanged(_settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content Discovery Mode
        _buildSectionTitle('Content Discovery Mode'),
        const SizedBox(height: 8),
        _buildDiscoveryModeSelector(),
        
        const SizedBox(height: 24),
        
        // Content Refresh Frequency
        _buildSectionTitle('Content Refresh Frequency'),
        const SizedBox(height: 8),
        _buildRefreshFrequencySlider(),
        
        const SizedBox(height: 24),
        
        // Toggle Settings
        _buildToggleSetting(
          title: 'Show Recommendation Reasoning',
          subtitle: 'Display why content was recommended to you',
          value: _settings['enableRecommendationReasoning'],
          onChanged: (value) => _updateSettings('enableRecommendationReasoning', value),
          icon: Icons.psychology_outlined,
        ),
        
        _buildToggleSetting(
          title: 'Content Filtering',
          subtitle: 'Filter out content you might not be interested in',
          value: _settings['enableContentFiltering'],
          onChanged: (value) => _updateSettings('enableContentFiltering', value),
          icon: Icons.filter_alt_outlined,
        ),
        
        _buildToggleSetting(
          title: 'Calendar-Contextual Content',
          subtitle: 'Recommend content based on your calendar events',
          value: _settings['enableCalendarContextualContent'],
          onChanged: (value) => _updateSettings('enableCalendarContextualContent', value),
          icon: Icons.event_outlined,
        ),
        
        _buildToggleSetting(
          title: 'Time-Aware Recommendations',
          subtitle: 'Adjust recommendations based on time of day',
          value: _settings['enableTimeAwareRecommendations'],
          onChanged: (value) => _updateSettings('enableTimeAwareRecommendations', value),
          icon: Icons.access_time_outlined,
        ),
        
        const SizedBox(height: 24),
        
        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: Colors.purple[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "These settings can be changed anytime in your profile settings. We'll continue to learn from your interactions to improve recommendations.",
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Colors.purple[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDiscoveryModeSelector() {
    final List<Map<String, dynamic>> discoveryModes = [
      {
        'value': 'exploratory',
        'label': 'Exploratory',
        'description': 'Discover more diverse and new content',
        'icon': Icons.explore_outlined,
      },
      {
        'value': 'balanced',
        'label': 'Balanced',
        'description': 'Mix of familiar and new content',
        'icon': Icons.balance_outlined,
      },
      {
        'value': 'focused',
        'label': 'Focused',
        'description': 'More content similar to what you already like',
        'icon': Icons.center_focus_strong_outlined,
      },
    ];
    
    return Column(
      children: discoveryModes.asMap().entries.map((entry) {
        final index = entry.key;
        final mode = entry.value;
        final isSelected = _settings['contentDiscoveryMode'] == mode['value'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _updateSettings('contentDiscoveryMode', mode['value']),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.secondary : Colors.grey.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      mode['icon'],
                      color: isSelected ? AppColors.secondary : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode['label'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? AppColors.secondary : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: mode['value'],
                    groupValue: _settings['contentDiscoveryMode'],
                    onChanged: (value) => _updateSettings('contentDiscoveryMode', value),
                    activeColor: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.05, end: 0);
      }).toList(),
    );
  }

  Widget _buildRefreshFrequencySlider() {
    final Map<String, String> frequencyLabels = {
      'low': 'Less Frequent',
      'medium': 'Medium',
      'high': 'More Frequent',
    };
    
    final Map<String, double> frequencyValues = {
      'low': 0.0,
      'medium': 1.0,
      'high': 2.0,
    };
    
    final currentValue = frequencyValues[_settings['contentRefreshFrequency']] ?? 1.0;
    
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.secondary,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
            thumbColor: AppColors.secondary,
            overlayColor: AppColors.secondary.withOpacity(0.2),
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
          ),
          child: Slider(
            value: currentValue,
            min: 0.0,
            max: 2.0,
            divisions: 2,
            onChanged: (value) {
              String frequency;
              if (value <= 0.5) {
                frequency = 'low';
              } else if (value <= 1.5) {
                frequency = 'medium';
              } else {
                frequency = 'high';
              }
              _updateSettings('contentRefreshFrequency', frequency);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                frequencyLabels['low']!,
                style: TextStyle(
                  color: _settings['contentRefreshFrequency'] == 'low' 
                      ? AppColors.secondary 
                      : Colors.grey[600],
                  fontWeight: _settings['contentRefreshFrequency'] == 'low' 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
              Text(
                frequencyLabels['medium']!,
                style: TextStyle(
                  color: _settings['contentRefreshFrequency'] == 'medium' 
                      ? AppColors.secondary 
                      : Colors.grey[600],
                  fontWeight: _settings['contentRefreshFrequency'] == 'medium' 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
              Text(
                frequencyLabels['high']!,
                style: TextStyle(
                  color: _settings['contentRefreshFrequency'] == 'high' 
                      ? AppColors.secondary 
                      : Colors.grey[600],
                  fontWeight: _settings['contentRefreshFrequency'] == 'high' 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Controls how often we refresh your content feed with new recommendations',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: value ? AppColors.secondary.withOpacity(0.05) :
          Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppColors.secondary.withOpacity(0.3) :
            Colors.grey.withOpacity(0.2),
          ),
        ),
        child: SwitchListTile(
          title: Row(
            children: [
              Icon(
                icon,
                color: value ? AppColors.secondary : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: value ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.secondary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}