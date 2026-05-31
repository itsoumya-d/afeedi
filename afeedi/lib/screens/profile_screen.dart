import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/local_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> _userProfile = {
    'name': 'Afeedi User',
    'email': '',
    'joinDate': 'Recently',
    'avatar': '',
    'isPremium': false,
    'level': 1,
    'totalWatchTime': '0 min',
    'videosWatched': 0,
    'streakDays': 0,
    'connectedPlatforms': 0,
  };

  final List<Map<String, dynamic>> _achievements = [
    {
      'id': 'early_bird',
      'title': 'Early Bird',
      'description': 'Watch 10 videos before 9 AM',
      'icon': Icons.wb_sunny,
      'color': Color(0xFFFFE66D),
      'unlocked': false,
      'progress': 0.0,
    },
    {
      'id': 'binge_watcher',
      'title': 'Binge Watcher',
      'description': 'Watch 5 hours in a single day',
      'icon': Icons.play_circle_filled,
      'color': Color(0xFFFF6B6B),
      'unlocked': false,
      'progress': 0.0,
    },
    {
      'id': 'explorer',
      'title': 'Content Explorer',
      'description': 'Watch videos from all 4 platforms',
      'icon': Icons.explore,
      'color': Color(0xFF4ECDC4),
      'unlocked': false,
      'progress': 0.0,
    },
    {
      'id': 'streak_master',
      'title': 'Streak Master',
      'description': 'Maintain a 30-day viewing streak',
      'icon': Icons.local_fire_department,
      'color': Color(0xFFFF8A65),
      'unlocked': false,
      'progress': 0.0,
    },
  ];

  final List<Map<String, dynamic>> _viewingHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = LocalAuthService.instance.currentUser;
    if (user != null) {
      // Derive a display name from the email (part before @)
      final emailName = user.email.split('@').first;
      final displayName = emailName
          .replaceAll(RegExp(r'[._\-]'), ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');

      // Load platform connections count
      int connectedCount = 0;
      try {
        final connections = await LocalStorageService.instance.getPlatformConnections(user.id);
        connectedCount = connections.length;
      } catch (_) {}

      setState(() {
        _userProfile = {
          'name': displayName.isNotEmpty ? displayName : 'Afeedi User',
          'email': user.email,
          'joinDate': _formatJoinDate(user.createdAt),
          'avatar': '',
          'isPremium': user.isPremium,
          'level': 1,
          'totalWatchTime': '0 min',
          'videosWatched': 0,
          'streakDays': 0,
          'connectedPlatforms': connectedCount,
        };
      });
    }
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Recently';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A3E),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryCyan.withOpacity(0.08),
              const Color(0xFF1A0A3E),
              AppTheme.primaryPink.withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 12),
                      _buildStreakBanner(),
                      _buildStatsRow(),
                      _buildPlatformConnections(),
                      const SizedBox(height: 8),
                      _buildTabBar(),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAchievementsTab(),
                            _buildHistoryTab(),
                            _buildSubscriptionTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showEditProfileDialog(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit,
                color: AppTheme.primaryCyan,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Stack(
            children: [
              _buildAvatarWidget(),
              if (_userProfile['isPremium'] as bool)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A0A3E), width: 2),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile['name'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userProfile['email'] as String,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryCyan,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Joined ${_userProfile['joinDate']}',
                  style: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget() {
    final name = _userProfile['name'] as String? ?? 'U';
    final initials = name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    final avatarUrl = _userProfile['avatar'] as String? ?? '';

    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: avatarUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials),
              ),
            )
          : _buildInitialsAvatar(initials),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Center(
      child: Text(
        initials.isNotEmpty ? initials : 'AU',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStreakBanner() {
    final streak = _userProfile['streakDays'] as int? ?? 0;
    final isActive = streak > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  const Color(0xFFFF6B35).withOpacity(0.4),
                  const Color(0xFFFF8A65).withOpacity(0.25),
                ]
              : [
                  const Color(0xFFFF6B35).withOpacity(0.15),
                  const Color(0xFFFF8A65).withOpacity(0.08),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFF6B35).withOpacity(0.6)
              : const Color(0xFFFF6B35).withOpacity(0.25),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isActive)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                  ),
                ),
              Icon(
                Icons.local_fire_department,
                color: isActive
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFFFF6B35).withOpacity(0.5),
                size: isActive ? 44 : 36,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day${streak == 1 ? '' : 's'} Streak',
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFFFF8A65).withOpacity(0.7),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Keep it up! Watch today to continue.'
                      : 'Start your streak today!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    streak == 1 ? 'day' : 'days',
                    style: TextStyle(
                      color: const Color(0xFFFF6B35).withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final videosWatched = _userProfile['videosWatched'] as int? ?? 0;
    final watchTime = _userProfile['totalWatchTime'] as String? ?? '0 min';
    final level = _userProfile['level'] as int? ?? 1;
    final connectedPlatforms = _userProfile['connectedPlatforms'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Level',
            'Lv $level',
            Icons.trending_up,
            AppTheme.primaryCyan,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Watch Time',
            watchTime,
            Icons.access_time,
            AppTheme.primaryPink,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Videos',
            '$videosWatched',
            Icons.play_circle,
            const Color(0xFFFFE66D),
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Platforms',
            '$connectedPlatforms',
            Icons.devices,
            const Color(0xFF4ECDC4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildPlatformConnections() {
    final platforms = [
      {
        'name': 'YouTube',
        'icon': Icons.play_circle,
        'color': const Color(0xFFFF0000),
        'connected': false,
      },
      {
        'name': 'TikTok',
        'icon': Icons.music_video,
        'color': Colors.white,
        'connected': false,
      },
      {
        'name': 'Instagram',
        'icon': Icons.camera_alt,
        'color': const Color(0xFFE1306C),
        'connected': false,
      },
      {
        'name': 'Facebook',
        'icon': Icons.facebook,
        'color': const Color(0xFF1877F2),
        'connected': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Connected Platforms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...platforms.map((p) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (p['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  p['icon'] as IconData,
                  color: p['color'] as Color,
                  size: 22,
                ),
              ),
              title: Text(
                p['name'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              trailing: p['connected'] as bool
                  ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF))
                  : TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${p['name']} connection coming soon'),
                          backgroundColor: const Color(0xFF2D1B69),
                        ),
                      ),
                      child: const Text(
                        'Connect',
                        style: TextStyle(color: Color(0xFF00E5FF)),
                      ),
                    ),
            )),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryCyan.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppTheme.primaryCyan,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Achievements'),
          Tab(text: 'History'),
          Tab(text: 'Subscription'),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: _achievements.length,
        itemBuilder: (context, index) {
          final achievement = _achievements[index];
          return _buildAchievementCard(achievement);
        },
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'] as bool;
    final progress = achievement['progress'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (achievement['color'] as Color).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? (achievement['color'] as Color).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
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
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        achievement['color'] as Color),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? (achievement['color'] as Color).withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement['icon'] as IconData,
                  color: isUnlocked
                      ? achievement['color'] as Color
                      : Colors.white.withOpacity(0.5),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            achievement['title'] as String,
            style: TextStyle(
              color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            achievement['description'] as String,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: achievement['color'] as Color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: _viewingHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: Colors.white.withOpacity(0.3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No viewing history yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start watching to build your history!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showClearHistoryDialog(),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: AppTheme.primaryCyan,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _viewingHistory.length,
                    itemBuilder: (context, index) {
                      final item = _viewingHistory[index];
                      return _buildHistoryItem(item);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final completed = item['completed'] as bool;
    final watchedDuration = item['watchedDuration'] as String;
    final totalDuration = item['duration'] as String;

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
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['thumbnail'] as String,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              if (completed)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryCyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    totalDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item['creator'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(item['platform'] as String).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['platform'] as String,
                        style: TextStyle(
                          color: _getPlatformColor(item['platform'] as String),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['watchedAt'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (!completed) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Watched $watchedDuration of $totalDuration',
                    style: const TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.more_vert,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSubscriptionCard(),
          const SizedBox(height: 20),
          _buildSubscriptionFeatures(),
          const SizedBox(height: 20),
          if (!(_userProfile['isPremium'] as bool)) _buildUpgradeButton(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final isPremium = _userProfile['isPremium'] as bool;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [AppTheme.primaryCyan, AppTheme.primaryPink]
              : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium ? Colors.transparent : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isPremium ? Icons.star : Icons.star_border,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? 'Premium Member' : 'Free Member',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Enjoy unlimited access to all features'
                : 'Upgrade to unlock premium features',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionFeatures() {
    final isPremium = _userProfile['isPremium'] as bool;
    final features = [
      {
        'title': 'Ad-free Experience',
        'description': 'Watch without interruptions',
        'icon': Icons.block,
        'available': isPremium,
      },
      {
        'title': 'Offline Downloads',
        'description': 'Save videos for offline viewing',
        'icon': Icons.download,
        'available': isPremium,
      },
      {
        'title': 'Premium Analytics',
        'description': 'Detailed viewing insights',
        'icon': Icons.analytics,
        'available': isPremium,
      },
      {
        'title': 'Priority Support',
        'description': '24/7 customer support',
        'icon': Icons.support_agent,
        'available': isPremium,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => _buildFeatureItem(feature)),
      ],
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature) {
    final available = feature['available'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: available
            ? AppTheme.primaryCyan.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: available
              ? AppTheme.primaryCyan.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: available
                  ? AppTheme.primaryCyan.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              feature['icon'] as IconData,
              color: available
                  ? AppTheme.primaryCyan
                  : Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] as String,
                  style: TextStyle(
                    color: available ? Colors.white : Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature['description'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            available ? Icons.check_circle : Icons.lock,
            color: available
                ? AppTheme.primaryCyan
                : Colors.white.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton(
        onPressed: () => _showUpgradeDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'Upgrade to Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'facebook':
        return const Color(0xFF1877F2);
      default:
        return AppTheme.primaryCyan;
    }
  }

  // Dialog methods
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Profile editing functionality will be implemented here.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Clear History',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear your viewing history? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _viewingHistory.clear();
              });
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Upgrade to Premium',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Premium subscription functionality will be implemented here.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }
}
