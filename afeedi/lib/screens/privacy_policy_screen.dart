import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header('Afeedi Privacy Policy'),
            _body('Last updated: January 1, 2025'),
            const SizedBox(height: 20),
            _section(
              '1. Information We Collect',
              'Afeedi collects information you provide directly, including your name, email address, and content preferences selected during onboarding. We also collect usage data such as videos watched, content liked, saved, and followed creators to personalize your feed.',
            ),
            _section(
              '2. How We Use Your Information',
              'Your information is used solely to provide and improve the Afeedi service. This includes personalizing your content feed based on selected interests, saving your preferences locally on your device, and improving recommendation accuracy over time.',
            ),
            _section(
              '3. Data Storage',
              'Your preferences and interaction data are stored locally on your device using industry-standard secure storage. We do not sell your personal data to third parties. Analytics data used to improve the app is anonymized and aggregated.',
            ),
            _section(
              '4. Third-Party Content',
              "Afeedi displays content from YouTube, Instagram, TikTok, and Facebook. When you interact with embedded content, you are subject to the respective platform's privacy policy. YouTube content is displayed via official iframe embeds as permitted by YouTube's Terms of Service.",
            ),
            _section(
              '5. Google Calendar Integration',
              'If you connect Google Calendar, Afeedi requests read-only access to your calendar events to display them alongside your content feed. We do not store your calendar data on our servers; it is fetched directly from Google and cached temporarily on your device.',
            ),
            _section(
              '6. Data Retention',
              'Your data is stored on your device for as long as you use the app. You can delete your account and all associated data at any time from the Settings screen.',
            ),
            _section(
              "7. Children's Privacy",
              "Afeedi is not directed to children under 13. We do not knowingly collect personal information from children under 13. If you believe we have inadvertently collected such information, please contact us immediately.",
            ),
            _section(
              '8. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of significant changes via an in-app notification. Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),
            _section(
              '9. Contact Us',
              'If you have questions about this Privacy Policy or how we handle your data, please contact us at privacy@afeedi.com.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _body(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00D4FF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.6),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
