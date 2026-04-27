import 'package:flutter/material.dart';

class QuickReplyChips extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickReplies
                .map((reply) => _buildQuickReplyChip(reply))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(String text) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.9),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onReplyTap(text),
              borderRadius: BorderRadius.circular(24),
              splashColor: const Color(0xFF00D4FF).withOpacity(0.3),
              highlightColor: const Color(0xFF00D4FF).withOpacity(0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.24),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (text.contains(
                      RegExp(
                        r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
                        unicode: true,
                      ),
                    ))
                      Text(
                        text
                            .split(' ')
                            .firstWhere(
                              (part) => part.contains(
                                RegExp(
                                  r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
                                  unicode: true,
                                ),
                              ),
                              orElse: () => '',
                            ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    if (text.contains(
                      RegExp(
                        r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
                        unicode: true,
                      ),
                    ))
                      const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        text
                            .replaceAll(
                              RegExp(
                                r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
                                unicode: true,
                              ),
                              '',
                            )
                            .trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
