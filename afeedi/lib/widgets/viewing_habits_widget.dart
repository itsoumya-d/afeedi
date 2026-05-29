import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../services/analytics_service.dart';
import '../models/analytics_events.dart';
import '../models/viewing_habit.dart';

class ViewingHabitsWidget extends StatefulWidget {
  final List<ViewingHabit>? initialHabits;
  final Function(List<ViewingHabit> habits)? onHabitsUpdated;
  
  const ViewingHabitsWidget({
    super.key,
    this.initialHabits,
    this.onHabitsUpdated,
  });

  @override
  State<ViewingHabitsWidget> createState() => _ViewingHabitsWidgetState();
}

class _ViewingHabitsWidgetState extends State<ViewingHabitsWidget> with TickerProviderStateMixin {
  late List<ViewingHabit> _habits;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadViewingHabits();
  }
  
  Future<void> _loadViewingHabits() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // If initial habits are provided, use them
      if (widget.initialHabits != null) {
        _habits = List.from(widget.initialHabits!);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Otherwise, load from service or use defaults
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      
      // Sample data - in a real app, this would come from a service
      _habits = [
        ViewingHabit(
          id: '1',
          title: 'Evening Viewing',
          description: 'You typically watch content between 8PM and 11PM',
          timeOfDay: 'Evening',
          daysOfWeek: ['Monday', 'Wednesday', 'Friday', 'Sunday'],
          averageDuration: 120,
          preferredGenres: ['Drama', 'Sci-Fi'],
          preferredPlatforms: ['Netflix', 'HBO'],
        ),
        ViewingHabit(
          id: '2',
          title: 'Weekend Binge',
          description: 'You watch multiple episodes in a row on weekends',
          timeOfDay: 'Afternoon',
          daysOfWeek: ['Saturday', 'Sunday'],
          averageDuration: 240,
          preferredGenres: ['Comedy', 'Action'],
          preferredPlatforms: ['Netflix', 'Hulu'],
        ),
      ];
      
      // Track analytics event
      AnalyticsService.instance.trackEvent(
        eventName: 'viewing_habits_loaded',
        eventType: AnalyticsEvents.screenView,
        additionalData: {
          'habit_count': _habits.length,
        },
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load viewing habits: $e';
      });
    }
  }
  
  // This method is intentionally commented out as it's not currently used
  // but may be needed in future implementations
  /*
  void _updateHabit(ViewingHabit updatedHabit) {
    final index = _habits.indexWhere((h) => h.id == updatedHabit.id);
    if (index >= 0) {
      setState(() {
        _habits[index] = updatedHabit;
      });
      
      if (widget.onHabitsUpdated != null) {
        widget.onHabitsUpdated!(_habits);
      }
      
      // Track analytics event
      AnalyticsService.instance.trackEvent(
        eventName: 'viewing_habit_updated',
        eventType: AnalyticsEvents.buttonTap,
        additionalData: {
          'habit_id': updatedHabit.id,
        },
      );
    }
  }
  */
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }
    
    if (_habits.isEmpty) {
      return _buildEmptyStateWidget();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Your Viewing Habits',
            style: AppTextStyles.heading3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            'Based on your watching patterns, we\'ve identified these habits:',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        SizedBox(height: 16),
        ..._habits.map((habit) => _buildHabitCard(habit)),
      ],
    )
    .animate()
    .fadeIn(duration: 500.ms, delay: 100.ms)
    .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad);
  }
  
  Widget _buildHabitCard(ViewingHabit habit) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  habit.title,
                  style: AppTextStyles.heading4,
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => _showEditHabitDialog(habit, context),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              habit.description,
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 16.0),
            _buildHabitDetails(habit),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.easeOut);
  }
  
  Widget _buildHabitDetails(ViewingHabit habit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          Icons.access_time,
          'Time of Day:',
          habit.timeOfDay,
        ),
        SizedBox(height: 8.0),
        _buildDetailRow(
          Icons.calendar_today,
          'Days:',
          habit.daysOfWeek.join(', '),
        ),
        SizedBox(height: 8.0),
        _buildDetailRow(
          Icons.timer,
          'Average Duration:',
          '${habit.averageDuration} minutes',
        ),
        SizedBox(height: 12.0),
        Text(
          'Preferred Genres:',
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: habit.preferredGenres.map((genre) => _buildGenreChip(genre)).toList(),
        ),
        SizedBox(height: 12.0),
        Text(
          'Preferred Platforms:',
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: habit.preferredPlatforms.map((platform) => _buildPlatformChip(platform)).toList(),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: AppColors.textSecondary),
        SizedBox(width: 8.0),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 4.0),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGenreChip(String genre) {
    return Chip(
      label: Text(
        genre,
        style: AppTextStyles.genreLabel,
      ),
      backgroundColor: AppColors.getGenreColor(genre),
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  Widget _buildPlatformChip(String platform) {
    return Chip(
      label: Text(
        platform,
        style: AppTextStyles.platformLabel,
      ),
      backgroundColor: AppColors.getPlatformColor(platform),
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  void _showEditHabitDialog(ViewingHabit habit, BuildContext context) {
    // In a real app, this would open a dialog to edit the habit
    // For simplicity, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit habit dialog not implemented')),
    );
    
    // Track analytics event
    AnalyticsService.instance.trackEvent(
      eventName: 'edit_habit_dialog_opened',
      eventType: AnalyticsEvents.buttonTap,
      additionalData: {
        'habit_id': habit.id,
      },
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
            'Loading your viewing habits...',
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
            'An unknown error occurred',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () {
              _loadViewingHabits();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility_off, color: AppColors.textSecondary, size: 48.0),
          SizedBox(height: 16.0),
          Text(
            'No Viewing Habits Yet',
            style: AppTextStyles.heading4,
          ),
          SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'We\'ll analyze your watching patterns to identify your viewing habits over time.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}