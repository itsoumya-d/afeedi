import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat/chat_interface.dart';

class OnboardingChatbotScreen extends StatefulWidget {
  const OnboardingChatbotScreen({super.key});

  @override
  State<OnboardingChatbotScreen> createState() => _OnboardingChatbotScreenState();
}

class _OnboardingChatbotScreenState extends State<OnboardingChatbotScreen>
    with TickerProviderStateMixin {
  late ChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _chatController.initialize();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: ChatInterface(controller: _chatController),
        ),
      ),
    );
  }
}
