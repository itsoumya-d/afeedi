import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

class GdprConsentScreen extends StatefulWidget {
  final VoidCallback onConsented;
  const GdprConsentScreen({super.key, required this.onConsented});

  @override
  State<GdprConsentScreen> createState() => _GdprConsentScreenState();
}

class _GdprConsentScreenState extends State<GdprConsentScreen> {
  bool _analyticsConsent = false;
  bool _personalizationConsent = true;
  bool _essentialConsent = true; // Always required

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gdpr_consent_given', true);
    await prefs.setBool('gdpr_analytics', _analyticsConsent);
    await prefs.setBool('gdpr_personalization', _personalizationConsent);
    await prefs.setString('gdpr_consent_date', DateTime.now().toIso8601String());
    widget.onConsented();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Your Privacy Matters',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Before you start, please review how Afeedi uses your data. You can change these settings anytime in your profile.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              _buildConsentItem(
                title: 'Essential Data',
                description: 'Required for the app to function. Includes your login session and preferences.',
                value: _essentialConsent,
                onChanged: null, // Cannot be toggled off
                icon: Icons.lock_outline,
              ),
              _buildConsentItem(
                title: 'Personalization',
                description: 'Allows us to personalize your content feed and recommendations.',
                value: _personalizationConsent,
                onChanged: (v) => setState(() => _personalizationConsent = v),
                icon: Icons.tune,
              ),
              _buildConsentItem(
                title: 'Analytics',
                description: 'Help us improve the app by sharing anonymous usage data.',
                value: _analyticsConsent,
                onChanged: (v) => setState(() => _analyticsConsent = v),
                icon: Icons.analytics_outlined,
              ),
              const Spacer(),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy. You must be 13 or older to use Afeedi.',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    // Essential only
                    setState(() { _analyticsConsent = false; _personalizationConsent = false; });
                    await _saveAndContinue();
                  },
                  child: Text('Accept Essential Only', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentItem({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D4FF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00D4FF),
          ),
        ],
      ),
    );
  }
}
