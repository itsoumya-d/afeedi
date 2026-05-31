import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/navigation_service.dart';

class CalendarCustomizationScreen extends StatefulWidget {
  const CalendarCustomizationScreen({super.key});

  @override
  State<CalendarCustomizationScreen> createState() =>
      _CalendarCustomizationScreenState();
}

class _CalendarCustomizationScreenState
    extends State<CalendarCustomizationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Schedule preferences
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  Set<int> _activeDays = {1, 2, 3, 4, 5}; // Monday to Friday

  // Content preferences
  Map<String, bool> _contentTypes = {
    'educational': true,
    'entertainment': true,
    'news': false,
    'fitness': true,
    'cooking': false,
    'music': true,
  };

  // Reminder settings
  bool _enableReminders = true;
  int _reminderMinutes = 15;
  bool _smartScheduling = true;
  bool _adaptiveContent = true;
  String _schedulingStyle = 'balanced';

  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final List<Map<String, dynamic>> _contentTypeOptions = [
    {
      'id': 'educational',
      'name': 'Educational',
      'icon': Icons.school,
      'color': Color(0xFF4CAF50),
      'description': 'Tutorials, courses, documentaries',
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': Color(0xFFFF9800),
      'description': 'Movies, shows, comedy',
    },
    {
      'id': 'news',
      'name': 'News',
      'icon': Icons.newspaper,
      'color': Color(0xFF2196F3),
      'description': 'Current events, politics, world news',
    },
    {
      'id': 'fitness',
      'name': 'Fitness',
      'icon': Icons.fitness_center,
      'color': Color(0xFFE91E63),
      'description': 'Workouts, yoga, health tips',
    },
    {
      'id': 'cooking',
      'name': 'Cooking',
      'icon': Icons.restaurant,
      'color': Color(0xFFFF5722),
      'description': 'Recipes, cooking tutorials',
    },
    {
      'id': 'music',
      'name': 'Music',
      'icon': Icons.music_note,
      'color': Color(0xFF9C27B0),
      'description': 'Music videos, concerts, playlists',
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
    // Save calendar preferences and navigate to main app
    NavigationService.pushNamed('/dashboard');
  }

  Future<void> _selectTime(BuildContext context, bool isWakeUp) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isWakeUp ? _wakeUpTime : _sleepTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryCyan,
              onPrimary: Colors.white,
              surface: Color(0xFF2D1B69),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isWakeUp) {
          _wakeUpTime = picked;
        } else {
          _sleepTime = picked;
        }
      });
    }
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
                        _buildScheduleSection(),
                        const SizedBox(height: 32),
                        _buildContentTypesSection(),
                        const SizedBox(height: 32),
                        _buildReminderSection(),
                        const SizedBox(height: 32),
                        _buildAISection(),
                        const SizedBox(height: 40),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Step 4 of 4',
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 1.0, // 100% progress
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
            'Smart Calendar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your personalized viewing schedule',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'When do you typically watch content?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                'Wake Up',
                _wakeUpTime,
                Icons.wb_sunny,
                () => _selectTime(context, true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeSelector(
                'Sleep',
                _sleepTime,
                Icons.bedtime,
                () => _selectTime(context, false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Active Days',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final dayIndex = index + 1;
            final isActive = _activeDays.contains(dayIndex);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isActive) {
                    _activeDays.remove(dayIndex);
                  } else {
                    _activeDays.add(dayIndex);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryCyan
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primaryCyan
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _weekDays[index],
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay time,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryCyan, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What type of content do you want scheduled?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _contentTypeOptions.length,
          itemBuilder: (context, index) {
            final option = _contentTypeOptions[index];
            final isSelected = _contentTypes[option['id']] ?? false;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _contentTypes[option['id']] = !isSelected;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? option['color'].withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? option['color']
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option['icon'],
                      color: isSelected
                          ? option['color']
                          : Colors.white.withValues(alpha: 0.7),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? option['color'] : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option['description'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get notified about your scheduled content',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _buildToggleOption(
          'Enable Reminders',
          'Get notifications for scheduled content',
          _enableReminders,
          (value) => setState(() => _enableReminders = value),
        ),
        if (_enableReminders) ...[
          const SizedBox(height: 16),
          const Text(
            'Reminder Time',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...[5, 15, 30, 60].map((minutes) {
                final isSelected = _reminderMinutes == minutes;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _reminderMinutes = minutes),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryCyan.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryCyan
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${minutes}m',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryCyan
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Features',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let AI optimize your viewing experience',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _buildToggleOption(
          'Smart Scheduling',
          'AI suggests optimal viewing times based on your habits',
          _smartScheduling,
          (value) => setState(() => _smartScheduling = value),
        ),
        const SizedBox(height: 12),
        _buildToggleOption(
          'Adaptive Content',
          'Content recommendations adapt to your mood and time',
          _adaptiveContent,
          (value) => setState(() => _adaptiveContent = value),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scheduling Style',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSchedulingStyleOption('focused', 'Focused'),
            const SizedBox(width: 8),
            _buildSchedulingStyleOption('balanced', 'Balanced'),
            const SizedBox(width: 8),
            _buildSchedulingStyleOption('relaxed', 'Relaxed'),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleOption(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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
            activeTrackColor: AppTheme.primaryCyan.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingStyleOption(String value, String label) {
    final isSelected = _schedulingStyle == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _schedulingStyle = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryCyan.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryCyan
                  : Colors.white.withValues(alpha: 0.3),
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
                'Complete Setup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Skip customization and use defaults
              NavigationService.pushNamed('/dashboard');
            },
            child: Text(
              'Skip customization',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
