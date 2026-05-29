import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/smart_suggestions_service.dart';
import '../../models/chat_message.dart';
import '../../models/genre.dart';
import 'suggestion_chips.dart';

class EnhancedTextInput extends StatefulWidget {
  final Function(String) onSubmit;
  final List<String> suggestions;
  final String? hintText;
  final bool isEnabled;
  final VoidCallback? onFocusChanged;
  final int currentStep;
  final List<ChatMessage> chatHistory;
  final List<Genre>? selectedGenres;
  final Map<String, bool>? platformConnections;
  final bool showSmartSuggestions;

  const EnhancedTextInput({
    super.key,
    required this.onSubmit,
    this.suggestions = const [],
    this.hintText,
    this.isEnabled = true,
    this.onFocusChanged,
    required this.currentStep,
    required this.chatHistory,
    this.selectedGenres,
    this.platformConnections,
    this.showSmartSuggestions = true,
  });

  @override
  State<EnhancedTextInput> createState() => _EnhancedTextInputState();
}

class _EnhancedTextInputState extends State<EnhancedTextInput>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<String> _smartSuggestions = [];
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    _updateSmartSuggestions();
  }

  @override
  void didUpdateWidget(EnhancedTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.chatHistory.length != widget.chatHistory.length ||
        oldWidget.selectedGenres != widget.selectedGenres ||
        oldWidget.platformConnections != widget.platformConnections) {
      _updateSmartSuggestions();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSmartSuggestions() {
    if (!widget.showSmartSuggestions) {
      setState(() {
        _smartSuggestions = widget.suggestions;
      });
      return;
    }

    final suggestions = SmartSuggestionsService.getCombinedSuggestions(
      currentStep: widget.currentStep,
      chatHistory: widget.chatHistory,
      selectedGenres: widget.selectedGenres,
      platformConnections: widget.platformConnections,
      currentInput: _textController.text,
    );

    setState(() {
      _smartSuggestions = [...widget.suggestions, ...suggestions];
      _updateFilteredSuggestions();
    });
  }

  void _onTextChanged() {
    _updateSmartSuggestions();
    _updateFilteredSuggestions();
  }

  void _updateFilteredSuggestions() {
    final text = _textController.text.toLowerCase().trim();
    if (text.isEmpty) {
      setState(() {
        _filteredSuggestions = _smartSuggestions.take(6).toList();
        _showSuggestions = _hasFocus && _filteredSuggestions.isNotEmpty;
      });
    } else {
      final filtered = _smartSuggestions
          .where((suggestion) => 
              suggestion.toLowerCase().contains(text) ||
              text.split(' ').any((word) => 
                  suggestion.toLowerCase().contains(word)))
          .take(6)
          .toList();
      setState(() {
        _filteredSuggestions = filtered;
        _showSuggestions = _hasFocus && filtered.isNotEmpty;
      });
    }

    if (_showSuggestions) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onFocusChanged() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
    
    widget.onFocusChanged?.call();
    
    if (_hasFocus) {
      _updateFilteredSuggestions();
    } else {
      setState(() {
        _showSuggestions = false;
      });
      _controller.reverse();
    }
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && widget.isEnabled) {
      widget.onSubmit(text);
      _textController.clear();
      setState(() {
        _showSuggestions = false;
      });
      _controller.reverse();
      _updateSmartSuggestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Smart suggestions
        if (_showSuggestions && _filteredSuggestions.isNotEmpty)
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SuggestionChips(
                suggestions: _filteredSuggestions,
                onSuggestionTap: _onSuggestionTap,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
              ),
            ),
          ),
        
        // Text input field
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
             color: AppColors.surface.withValues(alpha: 0.9),
             borderRadius: BorderRadius.circular(24),
             border: Border.all(
               color: _hasFocus
                   ? AppColors.primary.withValues(alpha: 0.5)
                   : AppColors.border.withValues(alpha: 0.3),
               width: 1.5,
             ),
             boxShadow: [
               BoxShadow(
                 color: _hasFocus
                     ? AppColors.primary.withValues(alpha: 0.1)
                     : Colors.black.withValues(alpha: 0.05),
                 blurRadius: _hasFocus ? 8 : 4,
                 offset: const Offset(0, 2),
               ),
             ],
           ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Type your message...',
                    hintStyle: TextStyle(
                       color: AppColors.textSecondary.withValues(alpha: 0.6),
                       fontSize: 16,
                       fontWeight: FontWeight.w400,
                     ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                     color: AppColors.textPrimary,
                     fontSize: 16,
                     fontWeight: FontWeight.w400,
                     height: 1.4,
                   ),
                  onSubmitted: (_) => _onSubmit(),
                ),
              ),
              
              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: widget.isEnabled ? _onSubmit : null,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _textController.text.trim().isNotEmpty && widget.isEnabled
                           ? const LinearGradient(
                               colors: [AppColors.primary, AppColors.secondary],
                               begin: Alignment.topLeft,
                               end: Alignment.bottomRight,
                             )
                           : LinearGradient(
                               colors: [
                                 AppColors.primary.withValues(alpha: 0.3),
                                 AppColors.secondary.withValues(alpha: 0.3),
                               ],
                               begin: Alignment.topLeft,
                               end: Alignment.bottomRight,
                             ),
                      shape: BoxShape.circle,
                      boxShadow: _textController.text.trim().isNotEmpty && widget.isEnabled
                           ? [
                               BoxShadow(
                                 color: AppColors.primary.withValues(alpha: 0.3),
                                 blurRadius: 8,
                                 offset: const Offset(0, 2),
                               ),
                             ]
                           : null,
                    ),
                    child: Icon(
                       Icons.send_rounded,
                       color: Colors.white,
                       size: 20,
                     ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSuggestionTap(String suggestion) {
     _textController.text = suggestion;
     _textController.selection = TextSelection.fromPosition(
       TextPosition(offset: suggestion.length),
     );
     _onSubmit();
   }

   void _onSubmit() {
     final text = _textController.text.trim();
     if (text.isNotEmpty && widget.isEnabled) {
       widget.onSubmit(text);
       _textController.clear();
       _updateFilteredSuggestions();
     }
   }
}