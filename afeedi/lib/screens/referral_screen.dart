import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_auth_service.dart';
import '../services/analytics_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String _referralCode = '';
  int _invitesSent = 0;
  int _friendsJoined = 0;
  bool _codeCopied = false;
  bool _loading = true;
  DateTime? _lastShareTime;

  static const _cyan = Color(0xFF00D4FF);
  static const _bg = Color(0xFF0D0D1A);
  static const _card = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _loadReferralData();
    AnalyticsService.instance.trackUserInteraction(
      action: 'referral_screen_opened',
      screen: 'referral',
    );
  }

  Future<void> _loadReferralData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = LocalAuthService.instance.currentUser;
    final rawId = user?.id ?? prefs.getString('user_id') ?? 'AFEEDI';
    // Derive a short, memorable code from the user ID
    final code = 'AF-${rawId.substring(rawId.length > 6 ? rawId.length - 6 : 0).toUpperCase()}';
    setState(() {
      _referralCode = code;
      _invitesSent = prefs.getInt('referral_invites_sent') ?? 0;
      _friendsJoined = prefs.getInt('referral_friends_joined') ?? 0;
      _loading = false;
    });
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _referralCode));
    setState(() => _codeCopied = true);
    await AnalyticsService.instance.trackUserInteraction(
      action: 'referral_code_copied',
      screen: 'referral',
      additionalData: {'code': _referralCode},
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  Future<void> _shareInvite() async {
    final now = DateTime.now();
    if (_lastShareTime != null && now.difference(_lastShareTime!) < const Duration(seconds: 5)) return;
    _lastShareTime = now;

    final message =
        'I\'ve been using Afeedi to watch all my favorite content from YouTube, TikTok, Instagram, and more in one place — personalized just for me. '
        'Join me and get 7 days of Pro free! Use my code: $_referralCode\n'
        'Download: https://afeedi.com/download';
    await Clipboard.setData(ClipboardData(text: message));

    final prefs = await SharedPreferences.getInstance();
    final newCount = _invitesSent + 1;
    await prefs.setInt('referral_invites_sent', newCount);
    setState(() => _invitesSent = newCount);

    await AnalyticsService.instance.trackUserInteraction(
      action: 'referral_invite_shared',
      screen: 'referral',
      additionalData: {'invites_sent': newCount},
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite message copied! Paste it anywhere to share.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _cyan.withValues(alpha: 0.9),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.black,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invite Friends',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 28),
            _buildReferralCode(),
            const SizedBox(height: 20),
            _buildShareButton(),
            const SizedBox(height: 28),
            _buildStatsRow(),
            const SizedBox(height: 28),
            _buildRewardSteps(),
            const SizedBox(height: 28),
            _buildHowItWorks(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _cyan.withValues(alpha: 0.15),
            const Color(0xFF7C3AED).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard, color: _cyan, size: 52),
          const SizedBox(height: 16),
          const Text(
            'Give 7 Days Pro,\nGet 7 Days Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'When a friend joins Afeedi using your code and watches 5 videos, you both get 7 days of Pro free.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCode() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Your referral code',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _referralCode,
                style: const TextStyle(
                  color: _cyan,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: _codeCopied ? 'Code copied' : 'Copy referral code',
                button: true,
                child: GestureDetector(
                  onTap: _copyCode,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    // Minimum 44×44pt touch target (12px padding around 20px icon)
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _codeCopied
                          ? _cyan.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _codeCopied ? Icons.check : Icons.copy,
                      color: _codeCopied ? _cyan : Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _cyan,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: _shareInvite,
      icon: const Icon(Icons.share, size: 20),
      label: const Text(
        'Share Invite',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('$_invitesSent', 'Invites Sent', Icons.send_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('$_friendsJoined', 'Friends Joined', Icons.group_outlined)),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '${(_friendsJoined * 7)}d',
            'Pro Days Earned',
            Icons.workspace_premium_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _cyan, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSteps() {
    final steps = [
      (
        icon: Icons.share_outlined,
        color: _cyan,
        title: 'Share your code',
        subtitle: 'Send it to friends via any app',
      ),
      (
        icon: Icons.person_add_outlined,
        color: const Color(0xFF7C3AED),
        title: 'Friend signs up',
        subtitle: 'They enter your code at signup',
      ),
      (
        icon: Icons.play_circle_outline,
        color: const Color(0xFFFF6B35),
        title: 'They watch 5 videos',
        subtitle: 'On any platform, within 7 days',
      ),
      (
        icon: Icons.workspace_premium,
        color: const Color(0xFFFFD700),
        title: 'You both get 7 days Pro',
        subtitle: 'Unlimited saves, no ads',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How the reward works',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s.icon, color: s.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ${s.title}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          s.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Each successful referral grants 7 days of Pro to both you and your friend\n'
            '• Your friend must be a new user who signs up with your code\n'
            '• Pro days are added to your account automatically\n'
            '• No limit on how many friends you can invite\n'
            '• Rewards stack — invite 4 friends, get 28 days Pro free',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
