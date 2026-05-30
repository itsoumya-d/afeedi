import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/local_auth_service.dart';
import '../services/user_interaction_service.dart';
import '../services/content_service.dart';
import '../services/navigation_service.dart';
import '../models/content_model.dart';

// ─── Color palette ───────────────────────────────────────────────────────────
const Color _bgPrimary       = Color(0xFF0D0B1E);
const Color _surface         = Color(0xFF1A1A2E);
const Color _surfaceElevated = Color(0xFF252545);
const Color _accent          = Color(0xFF00D4FF);
const Color _accentPink      = Color(0xFFFF006E);
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

  final List<Map<String, dynamic>> _achievements = [
    {
      'id': 'welcome',
      'title': 'Welcome!',
      'description': 'Create your Afeedi account',
      'icon': Icons.celebration,
      'color': Color(0xFFFFE66D),
      'unlocked': true,
      'progress': 1.0,
    },
    {
      'id': 'first_video',
      'title': 'First Watch',
      'description': 'Watch your first video',
      'icon': Icons.play_circle_filled,
      'color': Color(0xFFFF6B6B),
      'unlocked': false,
      'progress': 0.0,
    },
    {
      'id': 'explorer',
      'title': 'Content Explorer',
      'description': 'Watch videos from 3 platforms',
      'icon': Icons.explore,
      'color': Color(0xFF4ECDC4),
      'unlocked': false,
      'progress': 0.0,
    },
    {
      'id': 'streak_starter',
      'title': 'Streak Starter',
      'description': 'Maintain a 7-day viewing streak',
      'icon': Icons.local_fire_department,
      'color': Color(0xFFFF8A65),
      'unlocked': false,
      'progress': 0.14,
    },
  ];

  final List<Map<String, dynamic>> _viewingHistory = [];
  final List<Content> _likedItems     = [];
  final List<Content> _savedItems     = [];

  bool _bioExpanded = false;

  static const String _bioText =
      'Curious mind. Content explorer. Watching the world one feed at a time.';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user  = LocalAuthService.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    String name;
    String email;
    String joinDate;

    if (user != null) {
      name = prefs.getString('onboarding_user_name') ??
          prefs.getString('user_name') ??
          user.email.split('@').first;
      email    = user.email;
      joinDate = '${_monthName(user.createdAt.month)} ${user.createdAt.year}';
    } else {
      name     = prefs.getString('onboarding_user_name') ?? 'You';
      email    = '';
      joinDate = 'Today';
    }

    final videosWatched = prefs.getInt('stat_videos_watched') ?? 0;
    final streakDays    = prefs.getInt('stat_streak_days')    ?? 1;
    final watchMinutes  = prefs.getInt('stat_watch_minutes')  ?? 0;
    final watchTimeStr  = watchMinutes >= 60
        ? '${watchMinutes ~/ 60}h ${watchMinutes % 60}m'
        : '${watchMinutes}m';

    final savedCount     = prefs.getInt('stat_saved_count')     ?? 0;
    final followingCount = prefs.getInt('stat_following_count') ?? 0;
    final likedCount     = prefs.getInt('stat_liked_count')     ?? 0;

    // Update achievements based on real activity
    if (user != null || name != 'You') {
      _achievements[0]['unlocked'] = true;
    }
    if (videosWatched > 0) {
      _achievements[1]['unlocked'] = true;
      _achievements[1]['progress'] = 1.0;
    }
    if (followingCount >= 1) {
      _achievements[2]['progress'] = (followingCount / 3.0).clamp(0.0, 1.0);
      if (followingCount >= 3) _achievements[2]['unlocked'] = true;
    }
    if (streakDays >= 7) {
      _achievements[3]['unlocked'] = true;
      _achievements[3]['progress'] = 1.0;
    } else {
      _achievements[3]['progress'] = streakDays / 7.0;
    }

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

    if (mounted) {
      setState(() {
        _userProfile['name']           = name;
        _userProfile['email']          = email;
        _userProfile['joinDate']       = joinDate;
        _userProfile['videosWatched']  = videosWatched;
        _userProfile['streakDays']     = streakDays;
        _userProfile['totalWatchTime'] = watchTimeStr;
        _userProfile['level']          = (videosWatched ~/ 10) + 1;
        _userProfile['savedCount']     = savedContent.isEmpty ? savedCount : savedContent.length;
        _userProfile['followingCount'] = followingCount;
        _userProfile['likedCount']     = likedContent.isEmpty ? likedCount : likedContent.length;
        _savedItems
          ..clear()
          ..addAll(savedContent);
        _likedItems
          ..clear()
          ..addAll(likedContent);
      });
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month];
  }

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
              ? Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverGradient(),
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
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              tooltip: 'Back',
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
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              tooltip: 'Edit profile',
            ),
          ),
        ),

        // Avatar — 80dp circle overlapping cover bottom by 40dp, 16dp from left
        Positioned(
          bottom: -40,
          left: 16,
          child: _buildAvatar(),
        ),
      ],
    );
  }

  Widget _coverGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C1C2E), Color(0xFF0D0D1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = _userProfile['avatar'] as String?;
    final name      = _userProfile['name']   as String? ?? '';
    final initial   = name.isNotEmpty ? name[0].toUpperCase() : 'A';

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
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _surfaceElevated,
                      child: const Icon(Icons.person, color: Colors.white38),
                    ),
                  )
                : _avatarFallback(initial),
          ),
        ),
        // Premium / verified badge
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
    final name     = _userProfile['name']     as String? ?? '';
    final email    = _userProfile['email']    as String? ?? '';
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        color: _accent, size: 13),
                    const SizedBox(width: 5),
                    Text(
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
          const SizedBox(height: 16),
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
            _bioText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: _bioExpanded ? null : 2,
            overflow:
                _bioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _bioExpanded ? 'Show less' : 'Show more',
            style: const TextStyle(color: _accent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final videosWatched  = _userProfile['videosWatched']  as int?    ?? 0;
    final totalWatchTime = _userProfile['totalWatchTime'] as String? ?? '0m';
    final streakDays     = _userProfile['streakDays']     as int?    ?? 0;
    final savedCount     = _userProfile['savedCount']     as int?    ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildStatItem('$videosWatched', 'Videos\nWatched'),
          _buildStatDivider(),
          _buildStatItem(totalWatchTime, 'Watch\nTime'),
          _buildStatDivider(),
          _buildStatItem('${streakDays}d', 'Streak'),
          _buildStatDivider(),
          _buildStatItem('$savedCount', 'Saved'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  // ─── TAB BAR ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: _bgPrimary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: _accent,
        indicatorWeight: 2.5,
        labelColor: _accent,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        isScrollable: false,
        tabs: const [
          Tab(text: 'Liked'),
          Tab(text: 'Saved'),
          Tab(text: 'History'),
          Tab(text: 'Achievements'),
        ],
      ),
    );
  }

  // ─── LIKED TAB ────────────────────────────────────────────────────────────

  Widget _buildLikedTab() {
    if (_likedItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: 'No liked content',
        subtitle: 'Videos you like will appear here',
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              const Text('Bookmarks', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.bookmarks),
                child: const Text('View All', style: TextStyle(color: _accent, fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _savedItems.isEmpty
              ? _buildEmptyState(icon: Icons.bookmark_outline, title: 'Nothing saved yet', subtitle: 'Bookmark content to see it here')
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 16 / 9,
                  ),
                  itemCount: _savedItems.length,
                  itemBuilder: (context, index) => _buildContentTile(_savedItems[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildContentTile(Content content) {
    final thumb = content.thumbnailUrl ?? '';
    final title = content.title ?? '';
    return ClipRRect(
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
                    child: const Icon(Icons.play_circle_outline, color: Colors.white38),
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
              const Text(
                'Watch History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
                child: const Text(
                  'View All',
                  style: TextStyle(color: _accent, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _viewingHistory.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history,
                  title: 'No history yet',
                  subtitle: 'Videos you watch will appear here',
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
    final completed       = item['completed']       as bool?   ?? false;
    final watchedDuration = item['watchedDuration'] as String? ?? '';
    final totalDuration   = item['duration']        as String? ?? '';
    final thumbUrl        = item['thumbnail']       as String? ?? '';
    final title           = item['title']           as String? ?? '';
    final creator         = item['creator']         as String? ?? '';
    final platform        = item['platform']        as String? ?? '';
    final watchedAt       = item['watchedAt']       as String? ?? '';

    return Container(
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
                    ? Image.network(
                        thumbUrl,
                        width: 96,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 64,
                          color: _surfaceElevated,
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white38,
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
                          color: Colors.white38,
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
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 11),
                  ),
                ),
              if (totalDuration.isNotEmpty)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      totalDuration,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9),
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
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (platform.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPlatformColor(platform)
                              .withValues(alpha: 0.18),
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
                              color: Colors.white38, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                if (!completed && watchedDuration.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Watched $watchedDuration of $totalDuration',
                    style: const TextStyle(color: _accent, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            constraints:
                const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const Icon(Icons.more_vert,
                color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }

  // ─── ACHIEVEMENTS TAB ─────────────────────────────────────────────────────

  Widget _buildAchievementsTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildEngagementScore()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildAchievementCard(_achievements[index]),
              childCount: _achievements.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementScore() {
    final videos = _userProfile['videosWatched'] as int? ?? 0;
    final streak = _userProfile['streakDays']    as int? ?? 0;
    final saved  = _userProfile['savedCount']    as int? ?? 0;
    final score  =
        ((videos * 2) + (streak * 5) + (saved * 3)).clamp(0, 999);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _accent.withValues(alpha: 0.14),
          _accentPink.withValues(alpha: 0.14),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Engagement Score',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
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
              _miniStat('$videos', 'Watched'),
              const SizedBox(height: 8),
              _miniStat('${streak}d', 'Streak'),
              const SizedBox(height: 8),
              _miniStat('$saved', 'Saved'),
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
          style: const TextStyle(color: Colors.white38, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'] as bool? ?? false;
    final progress   = (achievement['progress'] as double?) ?? 0.0;
    final color      = achievement['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? color.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? color.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (!isUnlocked)
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? color.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement['icon'] as IconData,
                  color: isUnlocked
                      ? color
                      : Colors.white.withValues(alpha: 0.45),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement['title'] as String? ?? '',
            style: TextStyle(
              color: isUnlocked ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            achievement['description'] as String? ?? '',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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
            Icon(icon, size: 60, color: Colors.white.withValues(alpha: 0.18)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white30, fontSize: 13),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Profile editing will be available in the next update.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear History',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to clear your viewing history? This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _viewingHistory.clear());
            },
            child: const Text('Clear',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
