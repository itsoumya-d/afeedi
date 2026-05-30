import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingStepWidget extends StatefulWidget {
  final Map<String, dynamic> step;
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const OnboardingStepWidget({
    super.key,
    required this.step,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<OnboardingStepWidget> createState() => _OnboardingStepWidgetState();
}

class _OnboardingStepWidgetState extends State<OnboardingStepWidget>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentAnimation;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
  }

  void _initializeAnimations() {
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _contentController.forward();
  }

  void _initializeControllers() {
    final fields = widget.step['fields'] as List<String>? ?? [];
    for (final field in fields) {
      _textControllers[field] = TextEditingController(
        text: widget.data[field]?.toString() ?? '',
      );
      _focusNodes[field] = FocusNode();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _contentAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Expanded(child: _buildStepContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.step['title'] ?? '',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.step['description'] ?? '',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    final stepType = widget.step['type'] ?? 'form';

    switch (stepType) {
      case 'intro':
        return _buildIntroContent();
      case 'form':
        return _buildFormContent();
      case 'multi_select':
        return _buildMultiSelectContent();
      case 'single_select':
        return _buildSingleSelectContent();
      case 'priority_ranking':
        return _buildPriorityRankingContent();
      case 'completion':
        return _buildCompletionContent();
      default:
        return _buildFormContent();
    }
  }

  Widget _buildIntroContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 60,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Let\'s create your perfect content experience',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We\'ll ask you a few questions to personalize your feed and recommendations.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    final fields = widget.step['fields'] as List<String>? ?? [];

    return SingleChildScrollView(
      child: Column(
        children: fields.map((field) => _buildFormField(field)).toList(),
      ),
    );
  }

  Widget _buildFormField(String field) {
    switch (field) {
      case 'name':
        return _buildTextFormField(
          field: 'name',
          label: 'Your name',
          hint: 'What should we call you?',
          icon: Icons.person_outline,
        );
      case 'age':
        return _buildNumberFormField(
          field: 'age',
          label: 'Age',
          hint: 'How old are you?',
          icon: Icons.cake_outlined,
        );
      case 'language':
        return _buildDropdownField(
          field: 'language',
          label: 'Preferred language',
          options: [
            'English',
            'Spanish',
            'French',
            'German',
            'Chinese',
            'Japanese',
          ],
          icon: Icons.language_outlined,
        );
      case 'timezone':
        return _buildDropdownField(
          field: 'timezone',
          label: 'Timezone',
          options: [
            'UTC-8 (PST)',
            'UTC-5 (EST)',
            'UTC+0 (GMT)',
            'UTC+1 (CET)',
            'UTC+8 (CST)',
            'UTC+9 (JST)',
          ],
          icon: Icons.schedule_outlined,
        );
      case 'preferredViewingTimes':
        return _buildTimePreferencesField();
      case 'averageSessionDuration':
        return _buildSliderField(
          field: 'averageSessionDuration',
          label: 'Average viewing session',
          min: 5,
          max: 120,
          divisions: 23,
          unit: 'minutes',
        );
      case 'contentLengthPreferences':
        return _buildContentLengthField();
      default:
        return _buildGenericField(field);
    }
  }

  Widget _buildTextFormField({
    required String field,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: _textControllers[field],
        focusNode: _focusNodes[field],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          widget.onDataChanged({field: value});
        },
      ),
    );
  }

  Widget _buildNumberFormField({
    required String field,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: _textControllers[field],
        focusNode: _focusNodes[field],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          final intValue = int.tryParse(value);
          widget.onDataChanged({field: intValue});
        },
      ),
    );
  }

  Widget _buildDropdownField({
    required String field,
    required String label,
    required List<String> options,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: DropdownButtonFormField<String>(
        value: widget.data[field],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: options.map((option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
        onChanged: (value) {
          widget.onDataChanged({field: value});
        },
      ),
    );
  }

  Widget _buildSliderField({
    required String field,
    required String label,
    required double min,
    required double max,
    required int divisions,
    required String unit,
  }) {
    final value = (widget.data[field] ?? min).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${min.toInt()} $unit'),
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: '${value.toInt()} $unit',
                  onChanged: (newValue) {
                    widget.onDataChanged({field: newValue.toInt()});
                  },
                ),
              ),
              Text('${max.toInt()} $unit'),
            ],
          ),
          Center(
            child: Text(
              '${value.toInt()} $unit',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePreferencesField() {
    final timeSlots = [
      'Early Morning (6-9 AM)',
      'Morning (9-12 PM)',
      'Afternoon (12-5 PM)',
      'Evening (5-8 PM)',
      'Night (8-11 PM)',
      'Late Night (11 PM-2 AM)',
    ];

    final selectedTimes = List<String>.from(
      widget.data['preferredViewingTimes'] ?? [],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When do you usually watch content?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...timeSlots.map((timeSlot) {
            final isSelected = selectedTimes.contains(timeSlot);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: CheckboxListTile(
                title: Text(timeSlot),
                value: isSelected,
                onChanged: (value) {
                  if (value == true) {
                    selectedTimes.add(timeSlot);
                  } else {
                    selectedTimes.remove(timeSlot);
                  }
                  widget.onDataChanged({
                    'preferredViewingTimes': selectedTimes,
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContentLengthField() {
    final preferences = Map<String, int>.from(
      widget.data['contentLengthPreferences'] ??
          {'short': 70, 'medium': 25, 'long': 5},
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content length preferences (%)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildLengthSlider('Short videos (< 5 min)', 'short', preferences),
          _buildLengthSlider('Medium videos (5-20 min)', 'medium', preferences),
          _buildLengthSlider('Long videos (> 20 min)', 'long', preferences),
        ],
      ),
    );
  }

  Widget _buildLengthSlider(
    String label,
    String key,
    Map<String, int> preferences,
  ) {
    final value = preferences[key]?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text('${value.toInt()}%')],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (newValue) {
              preferences[key] = newValue.toInt();
              widget.onDataChanged({'contentLengthPreferences': preferences});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenericField(String field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: _textControllers[field],
        decoration: InputDecoration(
          labelText: field.replaceAll('_', ' ').toUpperCase(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          widget.onDataChanged({field: value});
        },
      ),
    );
  }

  Widget _buildMultiSelectContent() {
    final options = widget.step['options'] as List? ?? [];
    final selectedOptions = List<String>.from(
      widget.data[widget.step['id']] ?? [],
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map<Widget>((option) {
              final optionText = option.toString();
              final isSelected = selectedOptions.contains(optionText);

              return FilterChip(
                label: Text(optionText),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    selectedOptions.add(optionText);
                  } else {
                    selectedOptions.remove(optionText);
                  }
                  widget.onDataChanged({widget.step['id']: selectedOptions});
                },
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSelectContent() {
    final options = widget.step['options'] as List? ?? [];
    final selectedOption = widget.data[widget.step['id']];

    return SingleChildScrollView(
      child: Column(
        children: options.map<Widget>((option) {
          final optionData = option is Map
              ? option
              : {'id': option, 'title': option, 'description': ''};
          final isSelected = selectedOption == optionData['id'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Card(
              elevation: isSelected ? 4 : 1,
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
              child: ListTile(
                title: Text(
                  optionData['title'] ?? '',
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: optionData['description']?.isNotEmpty == true
                    ? Text(optionData['description'])
                    : null,
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  widget.onDataChanged({widget.step['id']: optionData['id']});
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityRankingContent() {
    final options = List<String>.from(widget.step['options'] ?? []);
    final priorities = Map<String, double>.from(
      widget.data['platformPriorities'] ?? {},
    );

    // Initialize priorities if empty
    if (priorities.isEmpty) {
      for (int i = 0; i < options.length; i++) {
        priorities[options[i]] = (options.length - i) / options.length;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Drag to reorder by preference (top = most preferred)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: options.map((option) {
              final priority = priorities[option] ?? 0.5;
              return Card(
                key: ValueKey(option),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getPlatformIcon(option),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(option),
                  subtitle: Text('Priority: ${(priority * 100).toInt()}%'),
                  trailing: const Icon(Icons.drag_handle),
                ),
              );
            }).toList(),
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;

              final item = options.removeAt(oldIndex);
              options.insert(newIndex, item);

              // Recalculate priorities
              for (int i = 0; i < options.length; i++) {
                priorities[options[i]] = (options.length - i) / options.length;
              }

              widget.onDataChanged({'platformPriorities': priorities});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You\'re all set!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Your personalized content experience is ready. Let\'s start discovering amazing content!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_outline;
      case 'tiktok':
        return Icons.music_note;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'twitter':
        return Icons.alternate_email;
      case 'twitch':
        return Icons.videogame_asset_outlined;
      default:
        return Icons.play_arrow;
    }
  }
}
