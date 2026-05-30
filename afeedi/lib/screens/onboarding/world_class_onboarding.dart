import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

const _kBg = Color(0xFF0D0B1E);
const _kBgMid = Color(0xFF1A1035);
const _kCyan = Color(0xFF00D4FF);
const _kPink = Color(0xFFFF3C7E);

class WorldClassOnboarding extends StatefulWidget {
  const WorldClassOnboarding({super.key});

  @override
  State<WorldClassOnboarding> createState() => _WorldClassOnboardingState();
}

class _WorldClassOnboardingState extends State<WorldClassOnboarding>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 10;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Step 1: Language
  String _selectedLanguage = 'en';

  // Step 3: Interests
  final Set<String> _selectedInterests = {};

  // Step 4: Content type
  String _contentType = 'mixed';

  // Step 5: Platforms
  final Set<String> _selectedPlatforms = {'youtube'};

  // Step 6: Viewing habits
  String _viewingTime = 'evening';
  String _sessionLength = 'medium';

  // Step 7: Personalization ranking
  final List<String> _rankingOrder = [
    'trending',
    'interests',
    'new_creators',
    'popular'
  ];

  // Step 8: Notifications
  bool _notifNew = true;
  bool _notifTrending = true;
  bool _notifWeekly = false;

  // Step 9: Privacy
  bool _analyticsConsent = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progressController.forward();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('onboarding_step') ?? 0;
    if (saved > 0 && saved < _totalSteps && mounted) {
      setState(() => _currentStep = saved);
      _pageController.jumpToPage(saved);
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onboarding_step', _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_canProceed()) return;
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      _progressController.reset();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _progressController.forward();
      _saveProgress();
    } else {
      _complete();
    }
  }

  void _back() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      _progressController.reset();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _progressController.forward();
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    if (_currentStep < _totalSteps - 1) {
      _progressController.reset();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _progressController.forward();
      _saveProgress();
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 2:
        return _selectedInterests.length >= 3;
      case 4:
        return _selectedPlatforms.isNotEmpty;
      default:
        return true;
    }
  }

  bool _isSkippable() {
    const skippable = {1, 5, 6, 7, 8};
    return skippable.contains(_currentStep);
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setStringList(
        'selected_interests', _selectedInterests.toList());
    await prefs.setString('content_type', _contentType);
    await prefs.setStringList(
        'connected_platforms', _selectedPlatforms.toList());
    await prefs.setString('viewing_time', _viewingTime);
    await prefs.setString('session_length', _sessionLength);
    await prefs.setBool('analytics_consent', _analyticsConsent);
    await prefs.remove('onboarding_step');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Ambient background glows
          _AmbientGlow(step: _currentStep, size: size),

          Column(
            children: [
              SafeArea(
                bottom: false,
                child: _TopBar(
                  current: _currentStep,
                  total: _totalSteps,
                  onBack: _currentStep > 0 ? _back : null,
                  onSkip: _isSkippable() ? _skip : null,
                  progressAnimation: _progressAnimation,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _LanguageStep(
                        selected: _selectedLanguage,
                        onSelect: (l) =>
                            setState(() => _selectedLanguage = l)),
                    _WelcomeStep(pulseAnim: _pulseAnimation),
                    _InterestsStep(
                        selected: _selectedInterests,
                        onToggle: (i) => setState(() {
                              if (_selectedInterests.contains(i)) {
                                _selectedInterests.remove(i);
                              } else {
                                _selectedInterests.add(i);
                              }
                            })),
                    _ContentTypeStep(
                        selected: _contentType,
                        onSelect: (t) =>
                            setState(() => _contentType = t)),
                    _PlatformsStep(
                        selected: _selectedPlatforms,
                        onToggle: (p) => setState(() {
                              if (p == 'youtube') return;
                              if (_selectedPlatforms.contains(p)) {
                                _selectedPlatforms.remove(p);
                              } else {
                                _selectedPlatforms.add(p);
                              }
                            })),
                    _ViewingHabitsStep(
                        time: _viewingTime,
                        session: _sessionLength,
                        onTimeSelect: (t) =>
                            setState(() => _viewingTime = t),
                        onSessionSelect: (s) =>
                            setState(() => _sessionLength = s)),
                    _RankingStep(
                        order: _rankingOrder,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _rankingOrder.removeAt(oldIndex);
                            _rankingOrder.insert(newIndex, item);
                          });
                        }),
                    _NotificationsStep(
                        notifNew: _notifNew,
                        notifTrending: _notifTrending,
                        notifWeekly: _notifWeekly,
                        onNewChanged: (v) =>
                            setState(() => _notifNew = v),
                        onTrendingChanged: (v) =>
                            setState(() => _notifTrending = v),
                        onWeeklyChanged: (v) =>
                            setState(() => _notifWeekly = v)),
                    _PrivacyStep(
                        consent: _analyticsConsent,
                        onChanged: (v) =>
                            setState(() => _analyticsConsent = v)),
                    _CompletionStep(pulseAnim: _pulseAnimation),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: _BottomBar(
                  step: _currentStep,
                  total: _totalSteps,
                  canProceed: _canProceed(),
                  isLast: _currentStep == _totalSteps - 1,
                  onNext: _next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Top bar with progress
// ─────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final Animation<double> progressAnimation;

  const _TopBar({
    required this.current,
    required this.total,
    required this.onBack,
    required this.onSkip,
    required this.progressAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70, size: 16),
                  ),
                )
              else
                const SizedBox(width: 36),
              const Spacer(),
              Text(
                '${current + 1} / $total',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (onSkip != null)
                GestureDetector(
                  onTap: onSkip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, _) {
              return LayoutBuilder(builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final segmentWidth =
                    (totalWidth - (total - 1) * 4) / total;
                return Row(
                  children: List.generate(total, (i) {
                    final filled = i < current ||
                        (i == current &&
                            progressAnimation.value > 0.5);
                    final active = i == current;
                    return Container(
                      width: segmentWidth,
                      height: 3,
                      margin: EdgeInsets.only(
                          right: i < total - 1 ? 4 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: filled
                            ? _kCyan
                            : active
                                ? _kCyan.withOpacity(
                                    0.3 + 0.5 * progressAnimation.value)
                                : Colors.white.withOpacity(0.12),
                      ),
                    );
                  }),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Bottom CTA bar
// ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int step;
  final int total;
  final bool canProceed;
  final bool isLast;
  final VoidCallback onNext;

  const _BottomBar({
    required this.step,
    required this.total,
    required this.canProceed,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    if (isLast) {
      label = "Start Exploring";
    } else if (step == 0) {
      label = "Get Started";
    } else if (step == 8) {
      label = "Agree & Continue";
    } else {
      label = "Continue";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: AnimatedOpacity(
        opacity: canProceed ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: canProceed ? onNext : null,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: canProceed
                  ? const LinearGradient(colors: [_kCyan, Color(0xFF0090E0)])
                  : null,
              color: canProceed ? null : Colors.white24,
              borderRadius: BorderRadius.circular(28),
              boxShadow: canProceed
                  ? [
                      BoxShadow(
                        color: _kCyan.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: canProceed
                          ? const Color(0xFF0D0B1E)
                          : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (canProceed && !isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF0D0B1E), size: 18),
                  ],
                  if (isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.rocket_launch_rounded,
                        color: Color(0xFF0D0B1E), size: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Ambient background glow
// ─────────────────────────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  final int step;
  final Size size;

  const _AmbientGlow({required this.step, required this.size});

  @override
  Widget build(BuildContext context) {
    final glowColor = step.isEven ? _kCyan : _kPink;
    return Positioned(
      top: -size.height * 0.1,
      right: -size.width * 0.2,
      child: Container(
        width: size.width * 0.8,
        height: size.width * 0.8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              glowColor.withOpacity(0.15),
              glowColor.withOpacity(0.03),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 1: Language selection
// ─────────────────────────────────────────────────────────

const _kLanguages = [
  {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'native': 'English'},
  {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳', 'native': 'हिंदी'},
  {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸', 'native': 'Español'},
  {'code': 'pt', 'name': 'Portuguese', 'flag': '🇧🇷', 'native': 'Português'},
  {'code': 'fr', 'name': 'French', 'flag': '🇫🇷', 'native': 'Français'},
  {'code': 'de', 'name': 'German', 'flag': '🇩🇪', 'native': 'Deutsch'},
  {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦', 'native': 'العربية'},
  {'code': 'id', 'name': 'Indonesian', 'flag': '🇮🇩', 'native': 'Bahasa'},
  {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵', 'native': '日本語'},
  {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷', 'native': '한국어'},
  {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳', 'native': '中文'},
  {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺', 'native': 'Русский'},
];

class _LanguageStep extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _LanguageStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose your language',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 6),
          const Text('You can change this anytime in settings',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _kLanguages.length,
            itemBuilder: (context, index) {
              final lang = _kLanguages[index];
              final isSelected = selected == lang['code'];
              return GestureDetector(
                onTap: () => onSelect(lang['code']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _kCyan : Colors.white.withOpacity(0.12),
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? _kCyan.withOpacity(0.12)
                        : Colors.white.withOpacity(0.04),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        lang['native']!,
                        style: TextStyle(
                          color: isSelected ? _kCyan : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 2: Welcome / value proposition
// ─────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  final Animation<double> pulseAnim;

  const _WelcomeStep({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kCyan, _kPink],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kCyan.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            'Your content,\nunified.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'YouTube, Instagram, TikTok, and more — all in one beautiful feed, personalized just for you.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _FeatureChip(icon: Icons.smart_toy_outlined, label: 'AI-powered'),
              _FeatureChip(icon: Icons.lock_outline, label: 'Private by default'),
              _FeatureChip(icon: Icons.language, label: '12 languages'),
              _FeatureChip(icon: Icons.bolt, label: 'Lightning fast'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kCyan, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 3: Interests (min 3)
// ─────────────────────────────────────────────────────────

const _kInterests = [
  {'id': 'technology', 'label': 'Technology', 'emoji': '💻'},
  {'id': 'gaming', 'label': 'Gaming', 'emoji': '🎮'},
  {'id': 'music', 'label': 'Music', 'emoji': '🎵'},
  {'id': 'fashion', 'label': 'Fashion', 'emoji': '👗'},
  {'id': 'food', 'label': 'Food & Cooking', 'emoji': '🍳'},
  {'id': 'travel', 'label': 'Travel', 'emoji': '✈️'},
  {'id': 'sports', 'label': 'Sports', 'emoji': '⚽'},
  {'id': 'comedy', 'label': 'Comedy', 'emoji': '😂'},
  {'id': 'education', 'label': 'Education', 'emoji': '📚'},
  {'id': 'beauty', 'label': 'Beauty', 'emoji': '💄'},
  {'id': 'fitness', 'label': 'Fitness', 'emoji': '💪'},
  {'id': 'business', 'label': 'Business', 'emoji': '📈'},
  {'id': 'news', 'label': 'News', 'emoji': '📰'},
  {'id': 'entertainment', 'label': 'Entertainment', 'emoji': '🎬'},
  {'id': 'science', 'label': 'Science', 'emoji': '🔬'},
  {'id': 'art', 'label': 'Art & Design', 'emoji': '🎨'},
];

class _InterestsStep extends StatelessWidget {
  final Set<String> selected;
  final void Function(String) onToggle;

  const _InterestsStep({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final remaining = math.max(0, 3 - selected.length);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What do you love?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              remaining > 0
                  ? 'Pick $remaining more to continue'
                  : '${selected.length} selected — looking great!',
              key: ValueKey(remaining),
              style: TextStyle(
                color: remaining > 0 ? Colors.white54 : _kCyan,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kInterests.map((interest) {
              final isSelected = selected.contains(interest['id']);
              return GestureDetector(
                onTap: () => onToggle(interest['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? _kCyan
                          : Colors.white.withOpacity(0.15),
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? _kCyan.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(interest['emoji']!,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        interest['label']!,
                        style: TextStyle(
                          color: isSelected ? _kCyan : Colors.white70,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 4: Content type preference
// ─────────────────────────────────────────────────────────

class _ContentTypeStep extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _ContentTypeStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const types = [
      {
        'id': 'short',
        'title': 'Quick Bites',
        'subtitle': 'Shorts, Reels & TikToks\nUnder 3 minutes',
        'icon': Icons.bolt_rounded,
        'gradient': [Color(0xFFFF3C7E), Color(0xFFFF6B6B)],
      },
      {
        'id': 'long',
        'title': 'Deep Dives',
        'subtitle': 'Full videos & documentaries\n10+ minutes',
        'icon': Icons.video_library_rounded,
        'gradient': [Color(0xFF6B35FF), Color(0xFF00D4FF)],
      },
      {
        'id': 'mixed',
        'title': 'Everything',
        'subtitle': 'The best of both worlds\nAI picks for you',
        'icon': Icons.auto_awesome_rounded,
        'gradient': [Color(0xFF00D4FF), Color(0xFF00FF88)],
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How do you like to watch?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 6),
          const Text('We\'ll tune your feed to match your style',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          const SizedBox(height: 24),
          ...types.map((type) {
            final isSelected = selected == type['id'];
            final gradientColors =
                type['gradient'] as List<Color>;
            return GestureDetector(
              onTap: () => onSelect(type['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? gradientColors.first
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? gradientColors.first.withOpacity(0.1)
                      : Colors.white.withOpacity(0.04),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(type['icon'] as IconData,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type['title'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type['subtitle'] as String,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gradientColors.first,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 5: Platform connections
// ─────────────────────────────────────────────────────────

const _kPlatforms = [
  {
    'id': 'youtube',
    'name': 'YouTube',
    'desc': 'Videos & Shorts',
    'icon': Icons.smart_display_rounded,
    'color': Color(0xFFFF0000),
    'required': true,
  },
  {
    'id': 'instagram',
    'name': 'Instagram',
    'desc': 'Reels & posts',
    'icon': Icons.camera_alt_rounded,
    'color': Color(0xFFE4405F),
    'required': false,
  },
  {
    'id': 'tiktok',
    'name': 'TikTok',
    'desc': 'Short-form videos',
    'icon': Icons.music_note_rounded,
    'color': Color(0xFF010101),
    'required': false,
  },
  {
    'id': 'facebook',
    'name': 'Facebook',
    'desc': 'Videos & Watch',
    'icon': Icons.facebook_rounded,
    'color': Color(0xFF1877F2),
    'required': false,
  },
];

class _PlatformsStep extends StatelessWidget {
  final Set<String> selected;
  final void Function(String) onToggle;

  const _PlatformsStep({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Connect your platforms',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 6),
          const Text(
              'We only read content — we never post or store your passwords',
              style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.4)),
          const SizedBox(height: 24),
          ..._kPlatforms.map((platform) {
            final isSelected = selected.contains(platform['id']);
            final isRequired = platform['required'] as bool;
            final color = platform['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onToggle(platform['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? color.withOpacity(0.08)
                        : Colors.white.withOpacity(0.04),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(platform['icon'] as IconData,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  platform['name'] as String,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (isRequired) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: _kCyan.withOpacity(0.2),
                                    ),
                                    child: const Text('Required',
                                        style: TextStyle(
                                            color: _kCyan,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              platform['desc'] as String,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (isRequired)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kCyan,
                          ),
                          child: const Icon(Icons.check,
                              color: Color(0xFF0D0B1E), size: 14),
                        )
                      else
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? color
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white38,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 13)
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 6: Viewing habits
// ─────────────────────────────────────────────────────────

class _ViewingHabitsStep extends StatelessWidget {
  final String time;
  final String session;
  final void Function(String) onTimeSelect;
  final void Function(String) onSessionSelect;

  const _ViewingHabitsStep({
    required this.time,
    required this.session,
    required this.onTimeSelect,
    required this.onSessionSelect,
  });

  @override
  Widget build(BuildContext context) {
    const timeSlots = [
      {'id': 'morning', 'label': 'Morning', 'emoji': '🌅', 'sub': '6am–12pm'},
      {'id': 'afternoon', 'label': 'Afternoon', 'emoji': '☀️', 'sub': '12–5pm'},
      {'id': 'evening', 'label': 'Evening', 'emoji': '🌆', 'sub': '5–9pm'},
      {'id': 'night', 'label': 'Night', 'emoji': '🌙', 'sub': '9pm+'},
    ];
    const sessions = [
      {'id': 'quick', 'label': 'Quick', 'sub': '< 15 min'},
      {'id': 'medium', 'label': 'Regular', 'sub': '15–45 min'},
      {'id': 'long', 'label': 'Long', 'sub': '45 min+'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('When do you watch?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 6),
          const Text('We\'ll schedule fresh content for your peak hours',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          const SizedBox(height: 24),
          const Text('TIME OF DAY',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: timeSlots.map((slot) {
              final isSelected = time == slot['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTimeSelect(slot['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? _kCyan
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? _kCyan.withOpacity(0.12)
                          : Colors.white.withOpacity(0.04),
                    ),
                    child: Column(
                      children: [
                        Text(slot['emoji']!,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          slot['label']!,
                          style: TextStyle(
                            color: isSelected ? _kCyan : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          slot['sub']!,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text('SESSION LENGTH',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: sessions.map((s) {
              final isSelected = session == s['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSessionSelect(s['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? _kPink
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? _kPink.withOpacity(0.1)
                          : Colors.white.withOpacity(0.04),
                    ),
                    child: Column(
                      children: [
                        Text(
                          s['label']!,
                          style: TextStyle(
                            color: isSelected ? _kPink : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          s['sub']!,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 7: Personalization ranking (reorderable)
// ─────────────────────────────────────────────────────────

const _kRankingItems = {
  'trending': {
    'label': 'Trending content',
    'desc': 'What\'s popular right now',
    'icon': Icons.trending_up_rounded,
    'color': Color(0xFFFF6B6B),
  },
  'interests': {
    'label': 'My interests',
    'desc': 'Based on what I love',
    'icon': Icons.favorite_rounded,
    'color': Color(0xFFFF3C7E),
  },
  'new_creators': {
    'label': 'New creators',
    'desc': 'Discover rising talent',
    'icon': Icons.person_add_rounded,
    'color': Color(0xFF00D4FF),
  },
  'popular': {
    'label': 'Most popular',
    'desc': 'Highest rated & liked',
    'icon': Icons.star_rounded,
    'color': Color(0xFFFFD700),
  },
};

class _RankingStep extends StatelessWidget {
  final List<String> order;
  final void Function(int, int) onReorder;

  const _RankingStep({required this.order, required this.onReorder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What matters most?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 6),
          const Text('Drag to rank — your #1 choice gets priority',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          const SizedBox(height: 20),
          Expanded(
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              onReorder: onReorder,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child,
              ),
              children: order.asMap().entries.map((entry) {
                final rank = entry.key;
                final id = entry.value;
                final item = _kRankingItems[id]!;
                return Container(
                  key: ValueKey(id),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rank == 0
                              ? _kCyan.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: rank == 0
                                ? _kCyan
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${rank + 1}',
                            style: TextStyle(
                              color: rank == 0 ? _kCyan : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:
                              (item['color'] as Color).withOpacity(0.15),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: item['color'] as Color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: rank,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.drag_handle_rounded,
                              color: Colors.white38, size: 20),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 8: Notification preferences
// ─────────────────────────────────────────────────────────

class _NotificationsStep extends StatelessWidget {
  final bool notifNew;
  final bool notifTrending;
  final bool notifWeekly;
  final void Function(bool) onNewChanged;
  final void Function(bool) onTrendingChanged;
  final void Function(bool) onWeeklyChanged;

  const _NotificationsStep({
    required this.notifNew,
    required this.notifTrending,
    required this.notifWeekly,
    required this.onNewChanged,
    required this.onTrendingChanged,
    required this.onWeeklyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stay in the loop',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 6),
          const Text('Only what matters — no spam, ever',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          const SizedBox(height: 32),
          _NotifToggle(
            icon: Icons.fiber_new_rounded,
            iconColor: _kCyan,
            title: 'New from your interests',
            subtitle: 'Fresh content matched to you',
            value: notifNew,
            onChanged: onNewChanged,
          ),
          _NotifToggle(
            icon: Icons.trending_up_rounded,
            iconColor: _kPink,
            title: 'Trending now',
            subtitle: 'What\'s blowing up right now',
            value: notifTrending,
            onChanged: onTrendingChanged,
          ),
          _NotifToggle(
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFFFFD700),
            title: 'Weekly digest',
            subtitle: 'Your top picks every Sunday',
            value: notifWeekly,
            onChanged: onWeeklyChanged,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.04),
              border:
                  Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_off_outlined,
                    color: Colors.white38, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can always change notification settings later',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _NotifToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: value
              ? iconColor.withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: iconColor.withOpacity(0.12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? iconColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 9: Privacy consent (GDPR)
// ─────────────────────────────────────────────────────────

class _PrivacyStep extends StatelessWidget {
  final bool consent;
  final void Function(bool) onChanged;

  const _PrivacyStep({required this.consent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF6B35FF), Color(0xFF00D4FF)],
              ),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Your privacy matters',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 12),
          ...[
            ('Your feed data stays on your device', Icons.phone_android_rounded),
            ('We never sell your data to advertisers', Icons.sell_outlined),
            ('Delete your account and all data anytime', Icons.delete_forever_rounded),
            ('Compliant with GDPR and CCPA', Icons.verified_rounded),
          ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(item.$2,
                        color: _kCyan, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.$1,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => onChanged(!consent),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: consent
                      ? _kCyan
                      : Colors.white.withOpacity(0.15),
                  width: consent ? 2 : 1,
                ),
                color: consent
                    ? _kCyan.withOpacity(0.08)
                    : Colors.white.withOpacity(0.04),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: consent ? _kCyan : Colors.transparent,
                      border: Border.all(
                        color: consent ? _kCyan : Colors.white38,
                        width: 2,
                      ),
                    ),
                    child: consent
                        ? const Icon(Icons.check,
                            color: Color(0xFF0D0B1E), size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share anonymous usage data',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Helps us improve Afeedi — no personal info shared',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'By continuing you agree to our Terms of Service and Privacy Policy. Analytics are off by default — your choice above.',
            style: TextStyle(
                color: Colors.white30, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 10: Completion / confetti
// ─────────────────────────────────────────────────────────

class _CompletionStep extends StatelessWidget {
  final Animation<double> pulseAnim;

  const _CompletionStep({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: pulseAnim.value,
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kCyan.withOpacity(0.1),
                  ),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_kCyan, Color(0xFF00FF88)],
                    ),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 48),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'You\'re all set!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your personalized feed is ready.\nLet\'s discover what\'s trending.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(value: '12', label: 'Languages'),
              const SizedBox(width: 16),
              _StatBadge(value: '4', label: 'Platforms'),
              const SizedBox(width: 16),
              _StatBadge(value: '16', label: 'Topics'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;

  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _kCyan,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
