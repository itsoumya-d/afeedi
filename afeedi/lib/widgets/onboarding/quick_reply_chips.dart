import 'package:flutter/material.dart';

class QuickReplyChips extends StatefulWidget {
  final List<String> quickReplies;
  final Function(String) onReplyTap;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const QuickReplyChips({
    super.key,
    required this.quickReplies,
    required this.onReplyTap,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  State<QuickReplyChips> createState() => _QuickReplyChipsState();
}

class _QuickReplyChipsState extends State<QuickReplyChips> {
  String? _pressedChip;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.slideAnimation,
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < widget.quickReplies.length; i++) ...[
                  _buildQuickReplyChip(widget.quickReplies[i]),
                  if (i < widget.quickReplies.length - 1)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(String text) {
    final isPressed = _pressedChip == text;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedChip = text),
      onTapCancel: () => setState(() => _pressedChip = null),
      onTap: () {
        setState(() => _pressedChip = null);
        widget.onReplyTap(text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isPressed ? const Color(0xFF00D4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPressed
                ? const Color(0xFF00D4FF)
                : Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isPressed
                ? Colors.white
                : Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
