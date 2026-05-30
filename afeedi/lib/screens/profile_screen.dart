import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/local_auth_service.dart';
import '../services/subscription_service.dart';
import '../services/user_interaction_service.dart';
import '../services/content_service.dart';
import '../services/navigation_service.dart';
import '../models/content_model.dart';
import '../l10n/app_localizations.dart';

// ─── Color palette ───────────────────────────────────────────────────────────
const Color _bgPrimary = Color(0xFF0D0B1E);
const Color _surface = Color(0xFF1A1A2E);
const Color _surfaceElevated = Color(0xFF252545);
const Color _accent = Color(0xFF00D4FF);
const Color _accentPink = Color(0xFFFF006E);
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, dynamic> _userProfile = {
    'name': 'You',
    'email': '',
    'joinDate': 'Today',
    'avatar': null,
    'coverPhoto': null,
    'isPremium': false,
    'level': 1,
    'totalWatchTime': '0 min',
    'videosWatched': 0,
    'streakDays': 1,
    'savedCount': 0,
    'likedCount': 0,
    'followingCount': 0,
  };

  // Achievements are populated dynamically in _loadUserData
  final List<Map<String, dynamic>> _achievements = [];

  List<Map<String, dynamic>> _viewingHistory = [];
  final List<Content> _likedItems = [];
  final List<Content> _savedItems = [];

  bool _bioExpanded = false;
  bool _isLoading = true;
  String? _localAvatarPath;

  String _bioText = '';
  List<String> _topInterests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = LocalAuthService.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    String name;
    String email;
    String joinDate;

    if (user != null) {
      name =
          prefs.getString('onboarding_user_name') ??
          prefs.getString('user_name') ??
          user.email.split('@').first;
      email = user.email;
      joinDate = '${_monthName(user.createdAt.month)} ${user.createdAt.year}';
    } else {
      name = prefs.getString('onboarding_user_name') ?? 'You';
      email = '';
      joinDate = 'Today';
    }

    final videosWatched = prefs.getInt('stat_videos_watched') ?? 0;
    final streakDays = prefs.getInt('stat_streak_days') ?? 1;
    final watchMinutes = prefs.getInt('stat_watch_minutes') ?? 0;
    final watchTimeStr = watchMinutes >= 60
        ? '${watchMinutes ~/ 60}h ${watchMinutes % 60}m'
        : '${watchMinutes}m';

    final savedCount = prefs.getInt('stat_saved_count') ?? 0;
    final followingCount = prefs.getInt('stat_following_count') ?? 0;
    final likedCount = prefs.getInt('stat_liked_count') ?? 0;

    // Check onboarding genres for "Genre Fan" achievement
    final onboardingGenres = prefs.getStringList('selected_genres') ?? [];

    // Build 6 achievements dynamically
    final builtAchievements = <Map<String, dynamic>>[
      {
        'id': 'first_watch',
        'title': 'First Watch',
        'description': 'Watch your first video',
        'icon': Icons.play_arrow,
        'color': const Color(0xFF00D4FF),
        'unlocked': videosWatched >= 1,
        'progress': videosWatched >= 1 ? 1.0 : 0.0,
        'progressLabel': videosWatched >= 1 ? 'Completed!' : '0/1 videos',
      },
      {
        'id': 'binge_watcher',
        'title': 'Binge Watcher',
        'description': 'Watch 10 videos',
        'icon': Icons.tv,
        'color': const Color(0xFF9C27B0),
        'unlocked': videosWatched >= 10,
        'progress': (videosWatched / 10.0).clamp(0.0, 1.0),
        'progressLabel': videosWatched >= 10
            ? 'Completed!'
            : '$videosWatched/10 videos',
      },
      {
        'id': 'explorer',
        'title': 'Explorer',
        'description': 'Watch content from 3 platforms',
        'icon': Icons.explore,
        'color': const Color(0xFF4CAF50),
        'unlocked': followingCount >= 3,
        'progress': (followingCount / 3.0).clamp(0.0, 1.0),
        'progressLabel': followingCount >= 3
            ? 'Completed!'
            : '$followingCount/3 platforms',
      },
      {
        'id': 'genre_fan',
        'title': 'Genre Fan',
        'description': 'Select 3+ genres in onboarding',
        'icon': Icons.category,
        'color': const Color(0xFFFF9800),
        'unlocked': onboardingGenres.length >= 3,
        'progress': (onboardingGenres.length / 3.0).clamp(0.0, 1.0),
        'progressLabel': onboardingGenres.length >= 3
            ? 'Completed!'
            : '${onboardingGenres.length}/3 genres',
      },
      {
        'id': 'week_streak',
        'title': 'Week Streak',
        'description': 'Maintain a 7-day viewing streak',
        'icon': Icons.local_fire_department,
        'color': const Color(0xFFF44336),
        'unlocked': streakDays >= 7,
        'progress': (streakDays / 7.0).clamp(0.0, 1.0),
        'progressLabel': streakDays >= 7 ? 'Completed!' : '$streakDays/7 days',
      },
      {
        'id': 'curator',
        'title': 'Curator',
        'description': 'Save 5 videos to your collection',
        'icon': Icons.bookmark,
        'color': const Color(0xFF2196F3),
        'unlocked': savedCount >= 5,
        'progress': (savedCount / 5.0).clamp(0.0, 1.0),
        'progressLabel': savedCount >= 5 ? 'Completed!' : '$savedCount/5 saved',
      },
    ];

    // Load real saved and liked content
    await UserInteractionService.instance.initialize();
    final savedIds = UserInteractionService.instance.getSavedContentIds();
    final likedIds = UserInteractionService.instance.getLikedContentIds();

    final savedContent = <Content>[];
    for (final id in savedIds.take(20)) {
      final c = await ContentService.instance.getVideoById(id);
      if (c != null) savedContent.add(c);
    }

    final likedContent = <Content>[];
    for (final id in likedIds.take(20)) {
      final c = await ContentService.instance.getVideoById(id);
      if (c != null) likedContent.add(c);
    }

    // Load viewing history
    final watchedIdsRaw = prefs.getStringList('watched_ids') ?? [];
    final historyItems = <Map<String, dynamic>>[];
    for (final id in watchedIdsRaw.take(50).toList().reversed) {
      final content = await ContentService.instance.getVideoById(id);
      if (content != null) {
        historyItems.add({
          'content': content,
          'progress': prefs.getDouble('watch_progress_$id') ?? 0.0,
          'watched_at': prefs.getString('watched_at_$id') ?? 'Recently',
        });
      }
    }

    final topInterests = await _loadTopInterests();

    if (mounted) {
      setState(() {
        _userProfile['name'] = name;
        _userProfile['email'] = email;
        _userProfile['joinDate'] = joinDate;
        _userProfile['videosWatched'] = videosWatched;
        _userProfile['streakDays'] = streakDays;
        _userProfile['totalWatchTime'] = watchTimeStr;
        _userProfile['level'] = (videosWatched ~/ 10) + 1;
        _userProfile['savedCount'] = savedContent.isEmpty
            ? savedCount
            : savedContent.length;
        _userProfile['followingCount'] = followingCount;
        _userProfile['likedCount'] = likedContent.isEmpty
            ? likedCount
            : likedContent.length;
        _userProfile['isPremium'] = SubscriptionService.instance.isPremium;
        _topInterests = topInterests;
        _achievements
          ..clear()
          ..addAll(builtAchievements);
        _savedItems
          ..clear()
          ..addAll(savedContent);
        _likedItems
          ..clear()
          ..addAll(likedContent);
        _viewingHistory = historyItems;
        final bio = prefs.getString('user_bio');
        if (bio != null && bio.isNotEmpty) _bioText = bio;
        final savedAvatarPath = prefs.getString('user_avatar_path');
        if (savedAvatarPath != null &&
            !savedAvatarPath.contains('..') &&
            File(savedAvatarPath).existsSync()) {
          _localAvatarPath = savedAvatarPath;
        }
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _loadTopInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('genre_implicit_weights') ?? '';
    if (raw.isEmpty) return [];
    final entries = raw
        .split(',')
        .map((e) {
          final parts = e.split(':');
          if (parts.length != 2) return null;
          return MapEntry(parts[0], int.tryParse(parts[1]) ?? 0);
        })
        .whereType<MapEntry<String, int>>()
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList();
  }

  String _monthName(int month) =>
      DateFormat.MMMM().format(DateTime(2000, month));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────── BUILD ──────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLikedTab(),
                  _buildSavedTab(),
                  _buildHistoryTab(),
                  _buildAchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SLIVER HEADER ────────────────────────────────────────────────────────

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverAndAvatar(),
          _buildProfileInfo(),
          _buildStatsRow(),
          if (_topInterests.isNotEmpty) _buildTopInterestsRow(),
        ],
      ),
    );
  }

  // ─── COVER + AVATAR ───────────────────────────────────────────────────────

  Widget _buildCoverAndAvatar() {
    final coverUrl = _userProfile['coverPhoto'] as String?;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover photo — 200dp height
        SizedBox(
          height: 200,
          width: double.infinity,
          child: coverUrl != null && coverUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(color: Colors.grey[900]),
                  errorWidget: (ctx, url, err) => _coverGradient(),
                )
              : _coverGradient(),
        ),

        // Back button — top-left, 44x44 touch target
        Positioned(
          top: 12,
          left: 12,
          child: SafeArea(
            bottom: false,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              tooltip: AppLocalizations.of(context)?.back ?? 'Back',
            ),
          ),
        ),

        // Edit profile button — top-right, 44x44 touch target
        Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: IconButton(
              onPressed: _showEditProfileDialog,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              tooltip:
                  AppLocalizations.of(context)?.editProfileTooltip ??
                  'Edit profile',
            ),
          ),
        ),

        // Avatar — 80dp circle overlapping cover bottom by 40dp, 16dp from left
        Positioned(
          bottom: -40,
          left: 16,
          child: GestureDetector(
            onTap: _pickAvatarImage,
            child: _buildAvatar(),
          ),
        ),
      ],
    );
  }

  Widget _coverGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF0F3460), Color(0xFF00D4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Future<void> _pickAvatarImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_path', picked.path);
    if (mounted) setState(() => _localAvatarPath = picked.path);
  }

  Widget _buildAvatar() {
    final name = _userProfile['name'] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Stack(
      children: [
        // Outer border ring — 80dp avatar + 4dp border each side = 88dp
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _bgPrimary, width: 4),
            color: _surfaceElevated,
          ),
          child: ClipOval(
            child: _localAvatarPath != null
                ? Image.file(
                    File(_localAvatarPath!),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(initial),
                  )
                : _avatarFallback(initial),
          ),
        ),
        // Camera icon overlay (bottom-left to avoid overlap with premium badge)
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
              border: Border.all(color: _bgPrimary, width: 2),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
          ),
        ),
        // Premium / verified badge (bottom-right)
        if (_userProfile['isPremium'] == true)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _accentPink,
                shape: BoxShape.circle,
                border: Border.all(color: _bgPrimary, width: 2),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _accentPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── PROFILE INFO ─────────────────────────────────────────────────────────

  Widget _buildProfileInfo() {
    final name = _userProfile['name'] as String? ?? '';
    final email = _userProfile['email'] as String? ?? '';
    final joinDate = _userProfile['joinDate'] as String? ?? '';

    return Padding(
      // 40dp for avatar overhang + 8dp gap
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + PRO badge row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_userProfile['isPremium'] == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accent, _accentPink],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // @handle / email
          if (email.isNotEmpty)
            Text(
              email.contains('@') ? '@${email.split('@').first}' : email,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 10),

          // Bio
          _buildBioSection(),
          const SizedBox(height: 10),

          // Member since chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, color: _accent, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)?.memberSince(joinDate) ??
                          'Member since $joinDate',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Invite friends CTA
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/referral'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00D4FF).withValues(alpha: 0.18),
                          const Color(0xFF7C3AED).withValues(alpha: 0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: Color(0xFF00D4FF),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Invite Friends → Get 7 Days Pro',
                          style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return GestureDetector(
      onTap: () => setState(() => _bioExpanded = !_bioExpanded),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _bioText.isNotEmpty
                ? _bioText
                : (AppLocalizations.of(context)?.defaultBio ??
                      'Curious mind. Content explorer. Watching the world one feed at a time.'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: _bioExpanded ? null : 2,
            overflow: _bioExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _bioExpanded
                ? (AppLocalizations.of(context)?.showLess ?? 'Show less')
                : (AppLocalizations.of(context)?.showMore ?? 'Show more'),
            style: const TextStyle(color: _accent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final videosWatched = _userProfile['videosWatched'] as int? ?? 0;
    final totalWatchTime = _userProfile['totalWatchTime'] as String? ?? '0m';
    final streakDays = _userProfile['streakDays'] as int? ?? 0;
    final savedCount = _userProfile['savedCount'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _buildStatCard(
            '$videosWatched',
            AppLocalizations.of(context)?.videosWatchedLabel ??
                'Videos\nWatched',
            Icons.play_circle_outline,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            totalWatchTime,
            AppLocalizations.of(context)?.watchTimeLabel ?? 'Watch Time',
            Icons.access_time,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            '${streakDays}d',
            AppLocalizations.of(context)?.streak ?? 'Streak',
            Icons.local_fire_department_outlined,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            '$savedCount',
            AppLocalizations.of(context)?.saved ?? 'Saved',
            Icons.bookmark_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accent, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP INTERESTS ────────────────────────────────────────────────────────

  Widget _buildTopInterestsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Interests',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _topInterests.map((genre) {
              final label = genre.length > 1
                  ? genre[0].toUpperCase() + genre.substring(1)
                  : genre.toUpperCase();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.interests, color: _accent, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── TAB BAR ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final likedCount = _userProfile['likedCount'] as int? ?? 0;
    final savedCount = _userProfile['savedCount'] as int? ?? 0;
    final watchedCount = _userProfile['videosWatched'] as int? ?? 0;

    return Container(
      color: _bgPrimary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: _accent,
        indicatorWeight: 2.5,
        labelColor: _accent,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        isScrollable: false,
        tabs: [
          _buildBadgeTab(
            AppLocalizations.of(context)?.liked ?? 'Liked',
            likedCount,
          ),
          _buildBadgeTab(
            AppLocalizations.of(context)?.saved ?? 'Saved',
            savedCount,
          ),
          _buildBadgeTab(
            AppLocalizations.of(context)?.history ?? 'History',
            watchedCount,
          ),
          Tab(
            text: AppLocalizations.of(context)?.achievements ?? 'Achievements',
          ),
        ],
      ),
    );
  }

  Tab _buildBadgeTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── LIKED TAB ────────────────────────────────────────────────────────────

  Widget _buildLikedTab() {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: _accent));
    if (_likedItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title:
            AppLocalizations.of(context)?.noLikedContent ??
            'No liked videos yet',
        subtitle:
            AppLocalizations.of(context)?.noLikedContentHint ??
            'Like videos to see them here',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 16 / 9,
      ),
      itemCount: _likedItems.length,
      itemBuilder: (context, index) => _buildContentTile(_likedItems[index]),
    );
  }

  // ─── SAVED TAB ────────────────────────────────────────────────────────────

  Widget _buildSavedTab() {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: _accent));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)?.bookmarks ?? 'Bookmarks',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.bookmarks),
                child: Text(
                  AppLocalizations.of(context)?.viewAll ?? 'View All',
                  style: const TextStyle(color: _accent, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _savedItems.isEmpty
              ? _buildEmptyState(
                  icon: Icons.bookmark_outline,
                  title:
                      AppLocalizations.of(context)?.nothingSavedYet ??
                      'No saved videos yet',
                  subtitle:
                      AppLocalizations.of(context)?.bookmarkContentHint ??
                      'Save videos to watch later',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 16 / 9,
                  ),
                  itemCount: _savedItems.length,
                  itemBuilder: (context, index) =>
                      _buildContentTile(_savedItems[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildContentTile(Content content) {
    final thumb = content.thumbnailUrl ?? '';
    final title = content.title ?? '';
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.player, arguments: content),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumb.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: _surfaceElevated,
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white54,
                      ),
                    ),
                    placeholder: (_, __) => Container(color: _surfaceElevated),
                  )
                : Container(color: _surfaceElevated),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HISTORY TAB ──────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)?.watchHistory ?? 'Watch History',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.history),
                child: Text(
                  AppLocalizations.of(context)?.viewAll ?? 'View All',
                  style: const TextStyle(color: _accent, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _viewingHistory.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history,
                  title:
                      AppLocalizations.of(context)?.noHistoryYet ??
                      'No watch history yet',
                  subtitle:
                      AppLocalizations.of(context)?.noHistoryHint ??
                      'Videos you watch will appear here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _viewingHistory.length,
                  itemBuilder: (context, index) =>
                      _buildHistoryItem(_viewingHistory[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final content = item['content'] as Content?;
    final completed = item['completed'] as bool? ?? false;
    final watchedDuration = item['watchedDuration'] as String? ?? '';
    final totalDuration = item['duration'] as String? ?? '';
    final thumbUrl =
        content?.thumbnailUrl ?? (item['thumbnail'] as String? ?? '');
    final title = content?.title ?? (item['title'] as String? ?? '');
    final creator = content?.creatorName ?? (item['creator'] as String? ?? '');
    final platform =
        content?.platform.name ?? (item['platform'] as String? ?? '');
    final watchedAt =
        item['watched_at'] as String? ?? (item['watchedAt'] as String? ?? '');

    return GestureDetector(
      onTap: content != null
          ? () => Navigator.pushNamed(
              context,
              AppRoutes.player,
              arguments: content,
            )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            // Thumbnail stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumbUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumbUrl,
                          width: 96,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) =>
                              Container(color: Colors.grey[900]),
                          errorWidget: (ctx, url, err) => Container(
                            width: 96,
                            height: 64,
                            color: _surfaceElevated,
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white54,
                              size: 24,
                            ),
                          ),
                        )
                      : Container(
                          width: 96,
                          height: 64,
                          color: _surfaceElevated,
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white54,
                            size: 24,
                          ),
                        ),
                ),
                if (completed)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
                if (totalDuration.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        totalDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    creator,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (platform.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPlatformColor(
                              platform,
                            ).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            platform,
                            style: TextStyle(
                              color: _getPlatformColor(platform),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (platform.isNotEmpty && watchedAt.isNotEmpty)
                        const SizedBox(width: 6),
                      if (watchedAt.isNotEmpty)
                        Flexible(
                          child: Text(
                            watchedAt,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (!completed && watchedDuration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(
                            context,
                          )?.watchedOf(watchedDuration, totalDuration) ??
                          'Watched $watchedDuration of $totalDuration',
                      style: const TextStyle(color: _accent, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white54,
                size: 18,
              ),
              color: const Color(0xFF1E1E2E),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              onSelected: (value) async {
                if (value == 'play' && content != null) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.player,
                    arguments: content,
                  );
                } else if (value == 'remove' && content != null) {
                  final prefs = await SharedPreferences.getInstance();
                  final ids = prefs.getStringList('watched_ids') ?? [];
                  ids.remove(content.id);
                  await prefs.setStringList('watched_ids', ids);
                  await prefs.remove('watch_progress_${content.id}');
                  await prefs.remove('watched_at_${content.id}');
                  if (mounted) {
                    setState(
                      () => _viewingHistory.removeWhere(
                        (i) => (i['content'] as Content?)?.id == content.id,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(ctx)?.play ?? 'Play',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(ctx)?.removeFromHistory ??
                            'Remove from history',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACHIEVEMENTS TAB ─────────────────────────────────────────────────────

  Widget _buildAchievementsTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildEngagementScore()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildAchievementCard(
              icon: _achievements[index]['icon'] as IconData,
              color: _achievements[index]['color'] as Color,
              title: _achievements[index]['title'] as String,
              description: _achievements[index]['description'] as String,
              unlocked: _achievements[index]['unlocked'] as bool? ?? false,
              progress: _achievements[index]['progressLabel'] as String?,
            ),
            childCount: _achievements.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildEngagementScore() {
    final videos = _userProfile['videosWatched'] as int? ?? 0;
    final streak = _userProfile['streakDays'] as int? ?? 0;
    final saved = _userProfile['savedCount'] as int? ?? 0;
    final score = ((videos * 2) + (streak * 5) + (saved * 3)).clamp(0, 999);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withValues(alpha: 0.14),
            _accentPink.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.engagementScore ??
                      'Engagement Score',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$score pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.ofMaxKeepWatching(
                        (score / 10).clamp(0, 100).toInt(),
                      ) ??
                      '${(score / 10).clamp(0, 100).toInt()}% of max — keep watching!',
                  style: const TextStyle(color: _accent, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              _miniStat(
                '$videos',
                AppLocalizations.of(context)?.watchedLabel ?? 'Watched',
              ),
              const SizedBox(height: 8),
              _miniStat(
                '${streak}d',
                AppLocalizations.of(context)?.streak ?? 'Streak',
              ),
              const SizedBox(height: 8),
              _miniStat(
                '$saved',
                AppLocalizations.of(context)?.saved ?? 'Saved',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool unlocked,
    String? progress,
  }) {
    return Semantics(
      label:
          'Achievement: $title, ${unlocked ? 'completed' : (progress ?? 'locked')}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked
              ? color.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? color.withValues(alpha: 0.4) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: unlocked ? color.withValues(alpha: 0.2) : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: unlocked ? color : Colors.white30,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: unlocked ? Colors.white : Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      progress,
                      style: TextStyle(
                        color: unlocked ? color : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (unlocked)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.white.withValues(alpha: 0.20)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'tiktok':
        return const Color(0xFF00E5FF);
      case 'facebook':
        return const Color(0xFF1877F2);
      default:
        return _accent;
    }
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: _userProfile['name'] as String? ?? '',
    );
    final bioController = TextEditingController(
      text: _bioText.isNotEmpty
          ? _bioText
          : (AppLocalizations.of(context)?.defaultBio ??
                'Curious mind. Content explorer. Watching the world one feed at a time.'),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)?.editProfile ?? 'Edit Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)?.displayName ??
                      'Display Name',
                  labelStyle: const TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return AppLocalizations.of(context)?.nameCannotBeEmpty ??
                        'Name cannot be empty';
                  if (v.trim().length > 50)
                    return AppLocalizations.of(context)?.nameTooLong ??
                        'Name too long (max 50 chars)';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bioController,
                maxLength: 150,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.bio ?? 'Bio',
                  labelStyle: const TextStyle(color: Colors.white60),
                  counterStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newName = nameController.text.trim();
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', newName);
              await prefs.setString('onboarding_user_name', newName);
              await prefs.setString('user_bio', bioController.text.trim());
              if (mounted) {
                setState(() {
                  _userProfile['name'] = newName;
                  _bioText = bioController.text.trim().isEmpty
                      ? (AppLocalizations.of(context)?.defaultBio ??
                            'Curious mind. Content explorer. Watching the world one feed at a time.')
                      : bioController.text.trim();
                });
              }
            },
            child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }
}
