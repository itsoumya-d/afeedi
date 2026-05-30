import 'package:flutter/material.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/onboarding/chat_message_widget.dart';
import '../../widgets/onboarding/typing_indicator.dart';
import '../../widgets/onboarding/quick_reply_chips.dart';
import '../../widgets/onboarding/genre_selection.dart';
import '../../widgets/onboarding/language_selection.dart';
import '../../widgets/onboarding/platform_connection.dart';
import '../../widgets/onboarding/text_input_widget.dart';
import '../../services/navigation_service.dart';

class ChatInterface extends StatefulWidget {
  final ChatController controller;
  
  const ChatInterface({
    super.key,
    required this.controller,
  });

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
  }

  void _onControllerUpdate() {
    if (widget.controller.showTyping) {
      _typingController.repeat();
    } else {
      _typingController.stop();
      _fadeController.forward();
    }
    
    if (widget.controller.showQuickReplies || 
        widget.controller.showTextInput ||
        widget.controller.showGenreSelection ||
        widget.controller.showLanguagePicker ||
        widget.controller.showPlatformSelection) {
      _slideController.forward();
    } else {
      _fadeController.reset();
      _slideController.reset();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _fadeController.dispose();
    _slideController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, child) {
              return ListView.builder(
                controller: widget.controller.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _calculateItemCount(),
                itemBuilder: _buildChatItem,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Welcome to Afeedi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (widget.controller.onboardingSteps.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${widget.controller.currentStep + 1} of ${widget.controller.onboardingSteps.length}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    Text(
                      '${((widget.controller.currentStep / widget.controller.onboardingSteps.length) * 100).round()}%',
                      style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: widget.controller.currentStep / widget.controller.onboardingSteps.length,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                minHeight: 3,
              ),
            ],
          ],
        );
      },
    );
  }

  int _calculateItemCount() {
    return widget.controller.messages.length + 
        (widget.controller.showTyping ? 1 : 0) + 
        (widget.controller.showQuickReplies ? 1 : 0) +
        (widget.controller.showTextInput ? 1 : 0) +
        (widget.controller.showGenreSelection ? 1 : 0) +
        (widget.controller.showLanguagePicker ? 1 : 0) +
        (widget.controller.showPlatformSelection ? 1 : 0) +
        (widget.controller.showFinalButton ? 1 : 0);
  }

  Widget _buildChatItem(BuildContext context, int index) {
    if (index < widget.controller.messages.length) {
      return ChatMessageWidget(
        message: widget.controller.messages[index],
        fadeAnimation: _fadeAnimation,
      );
    }
    
    index -= widget.controller.messages.length;
    
    if (widget.controller.showTyping && index == 0) {
      return TypingIndicator(typingAnimation: _typingAnimation);
    }
    if (widget.controller.showTyping) index--;
    
    if (widget.controller.showQuickReplies && index == 0) {
      return QuickReplyChips(
        quickReplies: widget.controller.quickReplies,
        onReplyTap: widget.controller.handleQuickReply,
        slideAnimation: _slideAnimation,
        fadeAnimation: _fadeAnimation,
      );
    }
    if (widget.controller.showQuickReplies) index--;
    
    if (widget.controller.showTextInput && index == 0) {
      return TextInputWidget(
        controller: widget.controller.textController,
        focusNode: widget.controller.textFocusNode,
        hintText: 'Type your message...',
        onSubmitted: (_) => widget.controller.handleTextInput(),
        onSend: widget.controller.handleTextInput,
        slideAnimation: _slideAnimation,
        fadeAnimation: _fadeAnimation,
        suggestions: widget.controller.currentSuggestions,
        onSuggestionTap: widget.controller.handleSuggestionTap,
      );
    }
    if (widget.controller.showTextInput) index--;
    
    if (widget.controller.showGenreSelection && index == 0) {
      return GenreSelection(
        allGenres: widget.controller.allGenres,
        filteredGenres: widget.controller.filteredGenres,
        selectedGenres: widget.controller.selectedGenres,
        searchController: widget.controller.searchController,
        searchFocusNode: widget.controller.searchFocusNode,
        onGenreToggle: widget.controller.handleGenreToggle,
        onSearchChanged: widget.controller.handleGenreSearchChanged,
        onContinue: widget.controller.handleGenreContinue,
        slideAnimation: _slideAnimation,
        fadeAnimation: _fadeAnimation,
      );
    }
    if (widget.controller.showGenreSelection) index--;

    if (widget.controller.showLanguagePicker && index == 0) {
      return LanguageSelectionWidget(
        onLanguageSelected: widget.controller.handleLanguageSelected,
        slideAnimation: _slideAnimation,
        fadeAnimation: _fadeAnimation,
      );
    }
    if (widget.controller.showLanguagePicker) index--;

    if (widget.controller.showPlatformSelection && index == 0) {
      return PlatformConnection(
        platformConnections: widget.controller.platformConnections,
        onPlatformConnect: widget.controller.handlePlatformConnect,
        onSkip: widget.controller.handlePlatformSkip,
        onContinue: widget.controller.handlePlatformContinue,
        slideAnimation: _slideAnimation,
        fadeAnimation: _fadeAnimation,
      );
    }
    if (widget.controller.showPlatformSelection) index--;
    
    if (widget.controller.showFinalButton && index == 0) {
      return _buildFinalButton();
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildFinalButton() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start Exploring! 🚀',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}