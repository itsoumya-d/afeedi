import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../services/analytics_service.dart';
import '../models/analytics_events.dart';

class PersonalizationSettingsWidget extends StatefulWidget {
  final Map<String, dynamic>? initialSettings;
  final Function(Map<String, dynamic>)? onSettingsUpdated;
  
  const PersonalizationSettingsWidget({
    Key? key,
    this.initialSettings,
    this.onSettingsUpdated,
  }) : super(key: key);

  @override
  _PersonalizationSettingsWidgetState createState() => _PersonalizationSettingsWidgetState();
}

class _PersonalizationSettingsWidgetState extends State<PersonalizationSettingsWidget> {
  late Map<String, dynamic> _settings;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Default settings
  final Map<String, dynamic> _defaultSettings = {
    'contentPreferences': {
      'enablePersonalizedRecommendations': true,
      'enableContinueWatching': true,
      'enableNewReleaseNotifications': true,
      'enableSimilarContentSuggestions': true,
    },
    'privacySettings': {
      'shareWatchHistory': true,
      'shareRatings': true,
      'allowContentAnalysis': true,
      'allowThirdPartyRecommendations': false,
    },
    'displaySettings': {
      'showContentRatings': true,
      'showContentDescriptions': true,
      'showContentWarnings': true,
      'showSpoilerWarnings': true,
    },
    'filterSettings': {
      'excludedGenres': <String>[],
      'excludedContentTypes': <String>[],
      'maturityLevel': 'Adult', // 'Child', 'Teen', 'Adult'
      'languagePreferences': ['English'],
    },
  };
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // If initial settings are provided, use them
      if (widget.initialSettings != null) {
        _settings = Map.from(widget.initialSettings!);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Otherwise, load from service or use defaults
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      
      // In a real app, this would come from a service
      _settings = Map.from(_defaultSettings);
      
      // Track analytics event
      AnalyticsService.instance.trackEvent(
        eventName: 'personalization_settings_loaded',
        eventType: AnalyticsEvents.userInteraction,
        additionalData: {
          'settings_count': _settings.length,
        },
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load personalization settings: $e';
      });
    }
  }
  
  void _updateSetting(String category, String key, dynamic value) {
    setState(() {
      _settings[category][key] = value;
    });
    
    if (widget.onSettingsUpdated != null) {
      widget.onSettingsUpdated!(_settings);
    }
    
    // Track analytics event
    AnalyticsService.instance.trackEvent(
      eventName: 'personalization_setting_updated',
      eventType: AnalyticsEvents.userInteraction,
      additionalData: {
        'category': category,
        'key': key,
        'value': value.toString(),
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalization Settings',
              style: AppTextStyles.heading3,
            ),
            SizedBox(height: 8.0),
            Text(
              'Customize how content is recommended and displayed to you.',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 24.0),
            _buildSettingsSection(
              'Content Preferences',
              Icons.recommend,
              _settings['contentPreferences'],
              'contentPreferences',
            ),
            SizedBox(height: 16.0),
            _buildSettingsSection(
              'Privacy Settings',
              Icons.privacy_tip,
              _settings['privacySettings'],
              'privacySettings',
            ),
            SizedBox(height: 16.0),
            _buildSettingsSection(
              'Display Settings',
              Icons.display_settings,
              _settings['displaySettings'],
              'displaySettings',
            ),
            SizedBox(height: 16.0),
            _buildFilterSettingsSection(),
            SizedBox(height: 24.0),
            _buildResetButton(),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms, delay: 100.ms)
    .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad);
  }
  
  Widget _buildSettingsSection(String title, IconData icon, Map<String, dynamic> sectionSettings, String category) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                SizedBox(width: 8.0),
                Text(
                  title,
                  style: AppTextStyles.heading4,
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ...sectionSettings.entries.map((entry) => _buildSwitchSetting(
              entry.key,
              entry.value,
              (value) => _updateSetting(category, entry.key, value),
            )).toList(),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.easeOut);
  }
  
  Widget _buildSwitchSetting(String key, bool value, Function(bool) onChanged) {
    // Convert camelCase to Title Case with spaces
    String title = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    title = title[0].toUpperCase() + title.substring(1);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSettingsSection() {
    final filterSettings = _settings['filterSettings'];
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.primary),
                SizedBox(width: 8.0),
                Text(
                  'Filter Settings',
                  style: AppTextStyles.heading4,
                ),
              ],
            ),
            SizedBox(height: 16.0),
            _buildDropdownSetting(
              'Maturity Level',
              filterSettings['maturityLevel'],
              ['Child', 'Teen', 'Adult'],
              (value) => _updateSetting('filterSettings', 'maturityLevel', value),
            ),
            SizedBox(height: 16.0),
            _buildChipListSetting(
              'Excluded Genres',
              filterSettings['excludedGenres'],
              ['Horror', 'Violence', 'Romance', 'Politics', 'Reality'],
              (value) => _updateSetting('filterSettings', 'excludedGenres', value),
            ),
            SizedBox(height: 16.0),
            _buildChipListSetting(
              'Language Preferences',
              filterSettings['languagePreferences'],
              ['English', 'Spanish', 'French', 'German', 'Japanese', 'Korean', 'Chinese'],
              (value) => _updateSetting('filterSettings', 'languagePreferences', value),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms, delay: 100.ms)
    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.easeOut);
  }
  
  Widget _buildDropdownSetting(String title, String value, List<String> options, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.0),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          )).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildChipListSetting(String title, List<String> selectedValues, List<String> options, Function(List<String>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                List<String> newValues = List.from(selectedValues);
                if (selected) {
                  if (!newValues.contains(option)) {
                    newValues.add(option);
                  }
                } else {
                  newValues.remove(option);
                }
                onChanged(newValues);
              },
              selectedColor: AppColors.primaryLight,
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildResetButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _settings = Map.from(_defaultSettings);
          });
          
          if (widget.onSettingsUpdated != null) {
            widget.onSettingsUpdated!(_settings);
          }
          
          // Track analytics event
          AnalyticsService.instance.trackEvent(
            eventName: 'personalization_settings_reset',
            eventType: AnalyticsEvents.userInteraction,
            additionalData: null,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Settings reset to defaults')),
          );
        },
        icon: Icon(Icons.refresh),
        label: Text('Reset to Defaults'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        ),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16.0),
          Text(
            'Loading personalization settings...',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48.0),
          SizedBox(height: 16.0),
          Text(
            'Error',
            style: AppTextStyles.heading4.copyWith(color: AppColors.error),
          ),
          SizedBox(height: 8.0),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: _loadSettings,
            child: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}