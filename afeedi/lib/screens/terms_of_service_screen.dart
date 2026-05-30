import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms of Service',
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
            _header('Afeedi Terms of Service'),
            _body('Effective date: June 1, 2026'),
            const SizedBox(height: 20),
            _section(
              '1. Acceptance of Terms',
              'By downloading, installing, or using the Afeedi application, you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the app.',
            ),
            _section(
              '2. Description of Service',
              'Afeedi is a video aggregator that displays publicly available video content from YouTube, Instagram, TikTok, and Facebook. We do not host, upload, or store any video content. All content remains on and is streamed from the originating platform.',
            ),
            _section(
              '3. Third-Party Content & Platforms',
              'All content displayed in Afeedi is subject to the terms and policies of the originating platform. YouTube content is subject to YouTube\'s Terms of Service (youtube.com/t/terms) and Google\'s Privacy Policy. We are not affiliated with, endorsed by, or in partnership with YouTube, Instagram, TikTok, or Facebook.',
            ),
            _section(
              '4. User Conduct',
              'You agree not to: (a) scrape, copy, or reproduce content from Afeedi or the third-party platforms via the app; (b) reverse engineer, decompile, or disassemble the Afeedi application; (c) use the app for any unlawful purpose or in violation of any applicable laws or regulations; (d) attempt to gain unauthorized access to any portion of the app or its related systems.',
            ),
            _section(
              '5. Subscriptions & Billing',
              'Afeedi Pro is available at \$4.99/month or \$39.99/year, billed through your Apple App Store or Google Play account. A 7-day free trial is available for new subscribers. You may cancel at any time through your App Store or Google Play subscription settings. Cancellation takes effect at the end of the current billing period. No refunds are issued for partial subscription periods, in accordance with Apple and Google platform policies.',
            ),
            _section(
              '6. Intellectual Property',
              'The Afeedi name, logo, and application design are proprietary and protected by intellectual property laws. Third-party content displayed within the app remains the property of its respective owners and platforms. Nothing in these terms grants you any rights to Afeedi\'s trademarks or third-party intellectual property.',
            ),
            _section(
              '7. Disclaimer of Warranties',
              'Afeedi is provided "as is" and "as available" without warranties of any kind, express or implied. We do not warrant uninterrupted availability, error-free operation, or the continued availability of any specific content. Third-party platform outages or policy changes may affect content availability.',
            ),
            _section(
              '8. Limitation of Liability',
              'To the maximum extent permitted by applicable law, Afeedi\'s total liability to you for any claim arising from or related to these terms or the app shall not exceed the amount you paid to Afeedi in the twelve (12) months preceding the claim.',
            ),
            _section(
              '9. Governing Law',
              'These Terms of Service shall be governed by and construed in accordance with the laws of the State of Delaware, USA, without regard to its conflict of law provisions.',
            ),
            _section(
              '10. Contact',
              'For legal inquiries regarding these Terms of Service, please contact us at legal@afeedi.com. Effective date: June 1, 2026.',
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
