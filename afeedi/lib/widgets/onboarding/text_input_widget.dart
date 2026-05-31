import 'package:flutter/material.dart';

class TextInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final Function(String) onSubmitted;
  final VoidCallback onSend;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final bool isEnabled;
  final List<String> suggestions;
  final Function(String)? onSuggestionTap;

  const TextInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSubmitted,
    required this.onSend,
    required this.slideAnimation,
    required this.fadeAnimation,
    this.isEnabled = true,
    this.suggestions = const [],
    this.onSuggestionTap,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SlideTransition(
      position: widget.slideAnimation,
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Suggestion chips shown above the input field
                if (widget.suggestions.isNotEmpty) ...[
                  _buildSuggestions(),
                  const SizedBox(height: 12),
                ],
                _buildInputRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick suggestions:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (int i = 0; i < widget.suggestions.length; i++) ...[
                _buildSuggestionChip(widget.suggestions[i]),
                if (i < widget.suggestions.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        widget.controller.text = suggestion;
        widget.onSuggestionTap?.call(suggestion);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Input field and circular send button in a single row.
  Widget _buildInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildInputField()),
        const SizedBox(width: 10),
        _buildCircularSendButton(),
      ],
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.isEnabled,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        maxLines: 4,
        minLines: 1,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.send,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularSendButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty && widget.isEnabled;

        return AnimatedOpacity(
          opacity: hasText ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: hasText
                  ? const Color(0xFF00D4FF)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: hasText ? widget.onSend : null,
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
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
