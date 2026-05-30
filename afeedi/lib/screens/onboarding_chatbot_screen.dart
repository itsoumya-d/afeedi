import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat/chat_interface.dart';

class OnboardingChatbotScreen extends StatefulWidget {
  const OnboardingChatbotScreen({super.key});

  @override
  State<OnboardingChatbotScreen> createState() =>
      _OnboardingChatbotScreenState();
}

class _OnboardingChatbotScreenState extends State<OnboardingChatbotScreen>
    with TickerProviderStateMixin {
  late ChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();
    _chatController.initialize();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _chatController.saveProgressDraft();
        if (!context.mounted) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'Leave setup?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Your progress will be saved as a draft. You can continue later.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Leave',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            ),
          ),
          child: SafeArea(child: ChatInterface(controller: _chatController)),
        ),
      ),
    );
  }
}
