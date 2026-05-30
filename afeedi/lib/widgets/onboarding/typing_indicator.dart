import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final Animation<double> typingAnimation;

  const TypingIndicator({super.key, required this.typingAnimation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar matching chat message style
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Af',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E3A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BouncingDot(
                  typingAnimation: typingAnimation,
                  delayFraction: 0.0,
                ),
                const SizedBox(width: 5),
                _BouncingDot(
                  typingAnimation: typingAnimation,
                  delayFraction: 0.2,
                ),
                const SizedBox(width: 5),
                _BouncingDot(
                  typingAnimation: typingAnimation,
                  delayFraction: 0.4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single dot that bounces up/down in a staggered sequence.
class _BouncingDot extends StatelessWidget {
  final Animation<double> typingAnimation;
  final double delayFraction;

  const _BouncingDot({
    required this.typingAnimation,
    required this.delayFraction,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: typingAnimation,
      builder: (context, child) {
        // Shift the animation phase by the delay fraction and wrap around [0, 1).
        final phase = (typingAnimation.value - delayFraction) % 1.0;
        // Map phase -> vertical offset: goes up (negative y) in first half, returns in second half.
        final bounceProgress = phase < 0.5 ? phase * 2.0 : (1.0 - phase) * 2.0;
        // Use a sine curve for a smooth bounce feel.
        final offset = -4.0 * bounceProgress;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4 + bounceProgress * 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
