import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
import '../services/analytics_service.dart';
import '../services/navigation_service.dart';

class WeeklyDigestScreen extends StatefulWidget {
  const WeeklyDigestScreen({super.key});

  @override
  State<WeeklyDigestScreen> createState() => _WeeklyDigestScreenState();
}

class _WeeklyDigestScreenState extends State<WeeklyDigestScreen> {
  static const _bg = Color(0xFF0D0D1A);
  static const _card = Color(0xFF1A1A2E);
  static const _cyan = Color(0xFF00D4FF);
  static const _purple = Color(0xFF7C3AED);

  List<Content> _picks = [];
  bool _loading = true;
  bool _isPro = false;
  String _userName = '';
  List<String> _genres = [];

  @override
  void initState() {
    super.initState();
    _load();
    AnalyticsService.instance.trackUserInteraction(
      action: 'weekly_digest_opened',
      screen: 'weekly_digest',
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('onboarding_user_name') ?? '';
      _genres = prefs.getStringList('onboarding_selected_genres') ?? [];
      final isPro = prefs.getBool('is_premium') ?? false;

      final content = await ContentService.instance
          .getOnboardingBasedRecommendations(limit: 5);
      if (!mounted) return;
      setState(() {
        _isPro = isPro;
        // Free users see first 2 picks; Pro sees all 5
        _picks = isPro ? content.take(5).toList() : content.take(2).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _weekLabel {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[startOfWeek.month - 1]} ${startOfWeek.day} – ${months[endOfWeek.month - 1]} ${endOfWeek.day}';
  }

  Future<void> _shareDigest() async {
    final titles = _picks.take(3).map((c) => '• ${c.title}').join('\n');
    final msg =
        'My Afeedi Weekly Digest — $_weekLabel\n\nTop picks this week:\n$titles\n\nGet your personalized feed: https://afeedi.com/download';
    await Clipboard.setData(ClipboardData(text: msg));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Digest copied — share it anywhere!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _cyan.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
      ),
    );
    await AnalyticsService.instance.trackUserInteraction(
      action: 'weekly_digest_shared',
      screen: 'weekly_digest',
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _userName.isNotEmpty
        ? 'Hi ${_userName.split(' ').first},'
        : 'Your';

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
          'Weekly Digest',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _shareDigest,
            icon: const Icon(Icons.share, color: _cyan, size: 18),
            label: const Text('Share', style: TextStyle(color: _cyan)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(greeting),
                  const SizedBox(height: 24),
                  if (_genres.isNotEmpty) _buildGenreChips(),
                  if (_genres.isNotEmpty) const SizedBox(height: 20),
                  _buildPicksList(),
                  if (!_isPro && _picks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildProUnlockBanner(),
                  ],
                  const SizedBox(height: 24),
                  _buildShareCTA(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String greeting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _cyan.withValues(alpha: 0.12),
            _purple.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: _cyan, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'AI DIGEST',
                      style: TextStyle(
                        color: _cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _weekLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$greeting here are your top picks',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Curated from across YouTube, TikTok, Instagram & more — just for you.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChips() {
    final shown = _genres.take(4).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: shown.map((g) {
        final hue = (g.hashCode % 360).toDouble();
        final color = HSLColor.fromAHSL(1, hue, 0.6, 0.55).toColor();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            g,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPicksList() {
    if (_picks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Complete onboarding to personalize your digest.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This week\'s picks',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ..._picks.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPickCard(entry.value, rank: entry.key + 1),
          );
        }),
      ],
    );
  }

  Widget _buildPickCard(Content content, {required int rank}) {
    final platformColors = {
      PlatformType.youtube: const Color(0xFFFF0000),
      PlatformType.tiktok: const Color(0xFF69C9D0),
      PlatformType.instagram: const Color(0xFFE1306C),
      PlatformType.facebook: const Color(0xFF1877F2),
    };
    final platformNames = {
      PlatformType.youtube: 'YouTube',
      PlatformType.tiktok: 'TikTok',
      PlatformType.instagram: 'Instagram',
      PlatformType.facebook: 'Facebook',
    };
    final platformColor = platformColors[content.platform] ?? _cyan;
    final platformName = platformNames[content.platform] ?? 'Video';
    final thumbnail = content.thumbnailUrl;

    return Semantics(
      label:
          'Rank $rank: ${content.title ?? 'Video'}, $platformName. Double-tap to play.',
      button: true,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.player, arguments: content);
          AnalyticsService.instance.trackUserInteraction(
            action: 'weekly_digest_pick_tapped',
            screen: 'weekly_digest',
            additionalData: {'rank': rank, 'content_id': content.id},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              // Rank number
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank == 1
                        ? const Color(0xFFFFD700)
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: rank == 1 ? 18 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4),
                ),
                child: thumbnail != null
                    ? Image.network(
                        thumbnail,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _thumbnailFallback(platformColor),
                      )
                    : _thumbnailFallback(platformColor),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title ?? 'Untitled',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: platformColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              platformName,
                              style: TextStyle(
                                color: platformColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (content.tags.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              content.tags.first,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white38,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnailFallback(Color color) {
    return Container(
      width: 80,
      height: 60,
      color: color.withValues(alpha: 0.2),
      child: Icon(Icons.play_circle_filled, color: color, size: 28),
    );
  }

  Widget _buildProUnlockBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7C3AED).withValues(alpha: 0.18),
              const Color(0xFF00D4FF).withValues(alpha: 0.18),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFF7C3AED), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3 more picks locked',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Upgrade to Pro for all 5 personalized picks.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Unlock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCTA() {
    return Semantics(
      label: 'Share your digest and get 7 days Pro free. Double-tap to share.',
      button: true,
      child: GestureDetector(
        onTap: _shareDigest,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _purple.withValues(alpha: 0.18),
                _cyan.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _purple.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard, color: _purple, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share your digest → Get 7 Days Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'When a friend joins using your link, you both get Pro free.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const ExcludeSemantics(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white30,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
