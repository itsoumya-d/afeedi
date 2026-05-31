import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../utils/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Animation<double>? animation;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.animation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          left: message.isBot ? 16 : 60,
          right: message.isBot ? 60 : 16,
          bottom: 12,
        ),
        child: Row(
          mainAxisAlignment: message.isBot
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isBot) _buildAvatar(),
            if (message.isBot) const SizedBox(width: 12),
            Flexible(child: _buildMessageContent(context)),
            if (!message.isBot) const SizedBox(width: 12),
            if (!message.isBot) _buildAvatar(),
          ],
        ),
      ),
    );

    if (animation != null) {
      return SlideTransition(
        position: animation!.drive(
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero),
        ),
        child: FadeTransition(opacity: animation!, child: widget),
      );
    }

    return widget;
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: message.isBot
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [AppColors.accent, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Icon(
        message.isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isBot
            ? AppColors.surface.withValues(alpha: 0.8)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(message.isBot ? 4 : 20),
          topRight: Radius.circular(message.isBot ? 20 : 4),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
        ),
        border: Border.all(
          color: message.isBot
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: message.isBot ? AppColors.textPrimary : AppColors.primary,
              fontSize: 16,
              fontWeight: message.isBot ? FontWeight.w400 : FontWeight.w500,
              height: 1.4,
            ),
          ),
          ...[
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

class TypingIndicator extends StatefulWidget {
  final Animation<double>? animation;

  const TypingIndicator({super.key, this.animation});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotController,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.4,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _dotController.repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indicator = Container(
      margin: const EdgeInsets.only(left: 16, right: 60, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _dotAnimations[index],
                  builder: (context, child) {
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: _dotAnimations[index].value,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );

    if (widget.animation != null) {
      return SlideTransition(
        position: widget.animation!.drive(
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero),
        ),
        child: FadeTransition(opacity: widget.animation!, child: indicator),
      );
    }

    return indicator;
  }
}
