import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Text input widget for onboarding forms
class OnboardingTextInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final Function(String) onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isRequired;
  final IconData? prefixIcon;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  
  const OnboardingTextInput({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  });
  
  @override
  State<OnboardingTextInput> createState() => _OnboardingTextInputState();
}

class _OnboardingTextInputState extends State<OnboardingTextInput>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(),
              const SizedBox(height: 8),
              _buildTextField(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (widget.isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTextField() {
    return TextFormField(
      controller: _controller,
      onChanged: widget.onChanged,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      onTap: () {
        setState(() {
          _isFocused = true;
        });
        _animationController.forward();
      },
      onEditingComplete: () {
        setState(() {
          _isFocused = false;
        });
        _animationController.reverse();
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: _isFocused
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : null,
        filled: true,
        fillColor: _isFocused
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// Multi-select chip widget for preferences
class OnboardingMultiSelect extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onSelectionChanged;
  final bool isRequired;
  final int? maxSelections;
  final String? description;
  
  const OnboardingMultiSelect({
    super.key,
    required this.label,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.isRequired = false,
    this.maxSelections,
    this.description,
  });
  
  @override
  State<OnboardingMultiSelect> createState() => _OnboardingMultiSelectState();
}

class _OnboardingMultiSelectState extends State<OnboardingMultiSelect>
    with TickerProviderStateMixin {
  late List<AnimationController> _chipControllers;
  late List<Animation<double>> _chipAnimations;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _chipControllers = List.generate(
      widget.options.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );
    
    _chipAnimations = _chipControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();
    
    // Stagger the animations
    for (int i = 0; i < _chipControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _chipControllers[i].forward();
        }
      });
    }
  }
  
  @override
  void dispose() {
    for (final controller in _chipControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        if (widget.description != null) ...[
          const SizedBox(height: 4),
          _buildDescription(),
        ],
        const SizedBox(height: 16),
        _buildChips(),
        if (widget.maxSelections != null)
          _buildSelectionCounter(),
      ],
    );
  }
  
  Widget _buildHeader() {
    return RichText(
      text: TextSpan(
        text: widget.label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (widget.isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDescription() {
    return Text(
      widget.description!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
  
  Widget _buildChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = widget.selectedOptions.contains(option);
        
        return AnimatedBuilder(
          animation: _chipAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _chipAnimations[index].value,
              child: _buildChip(option, isSelected),
            );
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildChip(String option, bool isSelected) {
    final canSelect = widget.maxSelections == null ||
        widget.selectedOptions.length < widget.maxSelections! ||
        isSelected;
    
    return FilterChip(
      label: Text(option),
      selected: isSelected,
      onSelected: canSelect
          ? (selected) {
              final newSelection = List<String>.from(widget.selectedOptions);
              if (selected) {
                newSelection.add(option);
              } else {
                newSelection.remove(option);
              }
              widget.onSelectionChanged(newSelection);
            }
          : null,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }
  
  Widget _buildSelectionCounter() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${widget.selectedOptions.length}/${widget.maxSelections} selected',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: widget.selectedOptions.length == widget.maxSelections
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// Single select dropdown widget
class OnboardingSingleSelect extends StatefulWidget {
  final String label;
  final List<String> options;
  final String? selectedOption;
  final Function(String?) onSelectionChanged;
  final bool isRequired;
  final String? hint;
  final IconData? prefixIcon;
  
  const OnboardingSingleSelect({
    super.key,
    required this.label,
    required this.options,
    this.selectedOption,
    required this.onSelectionChanged,
    this.isRequired = false,
    this.hint,
    this.prefixIcon,
  });
  
  @override
  State<OnboardingSingleSelect> createState() => _OnboardingSingleSelectState();
}

class _OnboardingSingleSelectState extends State<OnboardingSingleSelect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 8),
        _buildDropdown(),
      ],
    );
  }
  
  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (widget.isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDropdown() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: DropdownButtonFormField<String>(
            value: widget.selectedOption,
            hint: Text(widget.hint ?? 'Select an option'),
            onChanged: widget.onSelectionChanged,
            onTap: () => _animationController.forward(),
            items: widget.options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            decoration: InputDecoration(
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Time picker widget for schedule preferences
class OnboardingTimePicker extends StatefulWidget {
  final String label;
  final TimeOfDay? selectedTime;
  final Function(TimeOfDay?) onTimeChanged;
  final bool isRequired;
  final IconData? prefixIcon;
  
  const OnboardingTimePicker({
    super.key,
    required this.label,
    this.selectedTime,
    required this.onTimeChanged,
    this.isRequired = false,
    this.prefixIcon,
  });
  
  @override
  State<OnboardingTimePicker> createState() => _OnboardingTimePickerState();
}

class _OnboardingTimePickerState extends State<OnboardingTimePicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 8),
        _buildTimePicker(),
      ],
    );
  }
  
  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (widget.isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTimePicker() {
    return InkWell(
      onTap: _showTimePicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(
                widget.prefixIcon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                widget.selectedTime != null
                    ? widget.selectedTime!.format(context)
                    : 'Select time',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: widget.selectedTime != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: widget.selectedTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      widget.onTimeChanged(time);
    }
  }
}