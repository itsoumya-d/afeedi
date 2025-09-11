import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ViewingHabitsWidget extends StatefulWidget {
  final Map<String, dynamic> viewingHabits;
  final Function(Map<String, dynamic>) onViewingHabitsChanged;

  const ViewingHabitsWidget({
    Key? key,
    required this.viewingHabits,
    required this.onViewingHabitsChanged,
  }) : super(key: key);

  @override
  State<ViewingHabitsWidget> createState() => _ViewingHabitsWidgetState();
}

class _ViewingHabitsWidgetState extends State<ViewingHabitsWidget> {
  late Map<String, dynamic> _viewingHabits;
  
  // Time of day options
  final List<String> _timeOfDayOptions = [
    'Morning',
    'Afternoon',
    'Evening',
    'Late Night',
  ];
  
  // Session duration options
  final List<Map<String, dynamic>> _sessionDurationOptions = [
    {'label': 'Short (< 15 min)', 'value': 'short'},
    {'label': 'Medium (15-30 min)', 'value': 'medium'},
    {'label': 'Long (30-60 min)', 'value': 'long'},
    {'label': 'Extended (> 60 min)', 'value': 'extended'},
  ];
  
  // Viewing frequency options
  final List<Map<String, dynamic>> _viewingFrequencyOptions = [
    {'label': 'Multiple times daily', 'value': 'multiple_daily'},
    {'label': 'Once daily', 'value': 'daily'},
    {'label': 'A few times a week', 'value': 'weekly'},
    {'label': 'Occasionally', 'value': 'occasionally'},
  ];
  
  // Content consumption options
  final List<Map<String, dynamic>> _contentConsumptionOptions = [
    {
      'value': 'focused',
      'label': 'Focused Viewing',
      'description': 'I give content my full attention',
      'icon': Icons.visibility,
    },
    {
      'value': 'background',
      'label': 'Background Viewing',
      'description': 'I often multitask while watching',
      'icon': Icons.picture_in_picture_alt,
    },
    {
      'value': 'binge',
      'label': 'Binge Watching',
      'description': 'I watch multiple videos in one session',
      'icon': Icons.playlist_play,
    },
    {
      'value': 'selective',
      'label': 'Selective Viewing',
      'description': 'I carefully choose what to watch',
      'icon': Icons.filter_list,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with default values if not provided
    _viewingHabits = Map.from(widget.viewingHabits);
    _viewingHabits['preferredTimeOfDay'] ??= [];
    _viewingHabits['preferredSessionDuration'] ??= 'medium';
    _viewingHabits['viewingFrequency'] ??= 'daily';
    _viewingHabits['contentConsumptionStyle'] ??= 'focused';
  }

  void _updateViewingHabits(String key, dynamic value) {
    setState(() {
      _viewingHabits[key] = value;
      widget.onViewingHabitsChanged(_viewingHabits);
    });
  }

  void _toggleTimeOfDay(String timeOfDay) {
    final List<String> updatedTimes = List.from(_viewingHabits['preferredTimeOfDay'] as List);
    
    if (updatedTimes.contains(timeOfDay)) {
      updatedTimes.remove(timeOfDay);
    } else {
      updatedTimes.add(timeOfDay);
    }
    
    _updateViewingHabits('preferredTimeOfDay', updatedTimes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preferred time of day
        _buildSectionTitle('When do you usually watch videos?'),
        const SizedBox(height: 12),
        _buildTimeOfDaySelector(),
        
        const SizedBox(height: 24),
        
        // Session duration
        _buildSectionTitle('How long are your typical viewing sessions?'),
        const SizedBox(height: 12),
        _buildSessionDurationSelector(),
        
        const SizedBox(height: 24),
        
        // Viewing frequency
        _buildSectionTitle('How often do you watch videos?'),
        const SizedBox(height: 12),
        _buildViewingFrequencySelector(),
        
        const SizedBox(height: 24),
        
        // Content consumption style
        _buildSectionTitle("What's your content consumption style?"),
        const SizedBox(height: 12),
        _buildContentConsumptionStyleSelector(),
        
        const SizedBox(height: 24),
        
        // Tip box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your viewing habits help us optimize content delivery and notifications to match your schedule.',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildTimeOfDaySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _timeOfDayOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final timeOfDay = entry.value;
        final isSelected = (_viewingHabits['preferredTimeOfDay'] as List).contains(timeOfDay);
        
        return InkWell(
          onTap: () => _toggleTimeOfDay(timeOfDay),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              timeOfDay,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.05, end: 0);
      }).toList(),
    );
  }

  Widget _buildSessionDurationSelector() {
    return Column(
      children: _sessionDurationOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _viewingHabits['preferredSessionDuration'] == option['value'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            title: Text(option['label']),
            value: option['value'],
            groupValue: _viewingHabits['preferredSessionDuration'],
            onChanged: (value) => _updateViewingHabits('preferredSessionDuration', value),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            tileColor: isSelected ? AppColors.primary.withOpacity(0.05) : null,
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.05, end: 0);
      }).toList(),
    );
  }

  Widget _buildViewingFrequencySelector() {
    return Column(
      children: _viewingFrequencyOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _viewingHabits['viewingFrequency'] == option['value'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            title: Text(option['label']),
            value: option['value'],
            groupValue: _viewingHabits['viewingFrequency'],
            onChanged: (value) => _updateViewingHabits('viewingFrequency', value),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            tileColor: isSelected ? AppColors.primary.withOpacity(0.05) : null,
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.05, end: 0);
      }).toList(),
    );
  }

  Widget _buildContentConsumptionStyleSelector() {
    return Column(
      children: _contentConsumptionOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _viewingHabits['contentConsumptionStyle'] == option['value'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _updateViewingHabits('contentConsumptionStyle', option['value']),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      option['icon'],
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['label'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: option['value'],
                    groupValue: _viewingHabits['contentConsumptionStyle'],
                    onChanged: (value) => _updateViewingHabits('contentConsumptionStyle', value),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.05, end: 0);
      }).toList(),
    );
  }
}