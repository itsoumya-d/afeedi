import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;
  final Animation<double>? animation;
  final bool isVisible;
  final EdgeInsets? padding;

  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.animation,
    this.isVisible = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final widget = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick replies:',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              return _buildSuggestionChip(
                suggestion,
                index,
                context,
              );
            }).toList(),
          ),
        ],
      ),
    );

    if (animation != null) {
      return SlideTransition(
        position: animation!.drive(
          Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ),
        ),
        child: FadeTransition(
          opacity: animation!,
          child: widget,
        ),
      );
    }

    return widget;
  }

  Widget _buildSuggestionChip(
    String suggestion,
    int index,
    BuildContext context,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: _SuggestionChip(
              text: suggestion,
              onTap: () => onSuggestionTap(suggestion),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.text,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: _isPressed
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.secondary.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.secondary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isPressed
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: _isPressed
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: _isPressed
                        ? AppColors.primary
                        : AppColors.textSecondary.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class QuickReplyChips extends StatelessWidget {
  final List<String> quickReplies;
  final Function(String) onQuickReplyTap;
  final Animation<double>? animation;
  final bool isVisible;

  const QuickReplyChips({
    super.key,
    required this.quickReplies,
    required this.onQuickReplyTap,
    this.animation,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || quickReplies.isEmpty) {
      return const SizedBox.shrink();
    }

    final widget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickReplies.asMap().entries.map((entry) {
            final index = entry.key;
            final reply = entry.value;
            return Container(
              margin: EdgeInsets.only(
                right: index < quickReplies.length - 1 ? 8 : 0,
              ),
              child: _QuickReplyChip(
                text: reply,
                onTap: () => onQuickReplyTap(reply),
                delay: Duration(milliseconds: index * 100),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (animation != null) {
      return SlideTransition(
        position: animation!.drive(
          Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ),
        ),
        child: FadeTransition(
          opacity: animation!,
          child: widget,
        ),
      );
    }

    return widget;
  }
}

class _QuickReplyChip extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Duration delay;

  const _QuickReplyChip({
    required this.text,
    required this.onTap,
    this.delay = Duration.zero,
  });

  @override
  State<_QuickReplyChip> createState() => _QuickReplyChipState();
}

class _QuickReplyChipState extends State<_QuickReplyChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}