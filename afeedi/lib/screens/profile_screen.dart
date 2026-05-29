import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../services/local_auth_service.dart';
import '../services/user_interaction_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  final Map<String, dynamic> _userProfile = {
    'name': 'You',
    'email': '',
    'joinDate': 'Today',
    'avatar': null,
    'isPremium': false,
    'level': 1,
    'totalWatchTime': '0 min',
    'videosWatched': 0,
    'streakDays': 1,
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = LocalAuthService.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    String name;
    String email;
    String joinDate;

    if (user != null) {
      name = prefs.getString('onboarding_user_name') ??
          prefs.getString('user_name') ??
          user.email.split('@').first;
      email = user.email;
      joinDate = '${_monthName(user.createdAt.month)} ${user.createdAt.year}';
    } else {
      name = prefs.getString('onboarding_user_name') ?? 'You';
      email = '';
      joinDate = 'Today';
    }

    // Load persisted stats
    final videosWatched = prefs.getInt('stat_videos_watched') ?? 0;
    final streakDays = prefs.getInt('stat_streak_days') ?? 1;
    final watchMinutes = prefs.getInt('stat_watch_minutes') ?? 0;
    final watchTimeStr = watchMinutes >= 60
        ? '${watchMinutes ~/ 60}h ${watchMinutes % 60}m'
        : '${watchMinutes}m';

    // Load interaction stats from UserInteractionService
    final interactionService = UserInteractionService.instance;
    final likedCount = interactionService.getSavedContentIds().length +
        interactionService.getFollowedCreatorIds().length; // proxies for activity
    final savedCount = interactionService.getSavedContentIds().length;
    final followingCount = interactionService.getFollowedCreatorIds().length;

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

    if (mounted) {
      setState(() {
        _userProfile['name'] = name;
        _userProfile['email'] = email;
        _userProfile['joinDate'] = joinDate;
        _userProfile['videosWatched'] = videosWatched;
        _userProfile['streakDays'] = streakDays;
        _userProfile['totalWatchTime'] = watchTimeStr;
        _userProfile['level'] = (videosWatched ~/ 10) + 1;
        _userProfile['savedCount'] = savedCount;
        _userProfile['followingCount'] = followingCount;
        _userProfile['likedCount'] = likedCount;
      });
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryCyan.withValues(alpha: 0.1),
              AppTheme.darkPrimary,
              AppTheme.primaryPink.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildProfileHeader(),
              _buildStatsRow(),
              _buildTabBar(),
              Expanded(
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
                color: Colors.white.withValues(alpha: 0.1),
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
                color: Colors.white.withValues(alpha: 0.1),
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
    final name = _userProfile['name'] as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Column(
      children: [
        // Banner / cover photo (TikTok/YouTube Channel pattern)
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Banner gradient
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryCyan.withValues(alpha: 0.7),
                    AppTheme.primaryPink.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Opacity(
                opacity: 0.15,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemCount: 80,
                  itemBuilder: (_, __) => Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // Avatar overlaid on banner bottom (offset 50% below)
            Positioned(
              bottom: -50,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.darkPrimary, width: 4),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_userProfile['isPremium'])
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.darkPrimary, width: 2),
                        ),
                        child: const Icon(Icons.star, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 60), // Space for avatar overflow
        Text(
          _userProfile['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _userProfile['email'],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                color: AppTheme.primaryCyan,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Joined ${_userProfile['joinDate']}',
                style: TextStyle(
                  color: AppTheme.primaryCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Level',
            _userProfile['level'].toString(),
            Icons.trending_up,
            AppTheme.primaryCyan,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Watch Time',
            _userProfile['totalWatchTime'],
            Icons.access_time,
            AppTheme.primaryPink,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Videos',
            _userProfile['videosWatched'].toString(),
            Icons.play_circle,
            const Color(0xFFFFE66D),
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Streak',
            '${_userProfile['streakDays']} days',
            Icons.local_fire_department,
            const Color(0xFFFF8A65),
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
              color: color.withValues(alpha: 0.2),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
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
      color: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryCyan.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppTheme.primaryCyan,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
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
    final isUnlocked = achievement['unlocked'];
    final progress = achievement['progress'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? achievement['color'].withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked 
              ? achievement['color'].withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
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
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(achievement['color']),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? achievement['color'].withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement['icon'],
                  color: isUnlocked 
                      ? achievement['color']
                      : Colors.white.withValues(alpha: 0.5),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            achievement['title'],
            style: TextStyle(
              color: isUnlocked 
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            achievement['description'],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
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
                color: achievement['color'],
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
      child: Column(
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
            child: _viewingHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 56, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'No history yet',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Videos you watch will appear here',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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
    final completed = item['completed'];
    final watchedDuration = item['watchedDuration'];
    final totalDuration = item['duration'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['thumbnail'],
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
                    decoration: BoxDecoration(
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
                    color: Colors.black.withValues(alpha: 0.8),
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
                  item['title'],
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
                  item['creator'],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(item['platform']).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['platform'],
                        style: TextStyle(
                          color: _getPlatformColor(item['platform']),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['watchedAt'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (!completed) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Watched $watchedDuration of $totalDuration',
                    style: TextStyle(
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
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSubscriptionCard(),
          const SizedBox(height: 20),
          _buildSubscriptionFeatures(),
          const Spacer(),
          if (!_userProfile['isPremium'])
            _buildUpgradeButton(),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _userProfile['isPremium']
              ? [AppTheme.primaryCyan, AppTheme.primaryPink]
              : [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _userProfile['isPremium']
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _userProfile['isPremium'] ? Icons.star : Icons.star_border,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _userProfile['isPremium'] ? 'Premium Member' : 'Free Member',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile['isPremium']
                ? 'Enjoy unlimited access to all features'
                : 'Upgrade to unlock premium features',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_userProfile['isPremium']) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Renews March 15, 2024',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionFeatures() {
    final features = [
      {
        'title': 'Ad-free Experience',
        'description': 'Watch without interruptions',
        'icon': Icons.block,
        'available': _userProfile['isPremium'],
      },
      {
        'title': 'Offline Downloads',
        'description': 'Save videos for offline viewing',
        'icon': Icons.download,
        'available': _userProfile['isPremium'],
      },
      {
        'title': 'Premium Analytics',
        'description': 'Detailed viewing insights',
        'icon': Icons.analytics,
        'available': _userProfile['isPremium'],
      },
      {
        'title': 'Priority Support',
        'description': '24/7 customer support',
        'icon': Icons.support_agent,
        'available': _userProfile['isPremium'],
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
        ...features.map((feature) => _buildFeatureItem(feature)).toList(),
      ],
    );
  }
  
  Widget _buildFeatureItem(Map<String, dynamic> feature) {
    final available = feature['available'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: available 
            ? AppTheme.primaryCyan.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: available 
              ? AppTheme.primaryCyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: available 
                  ? AppTheme.primaryCyan.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              feature['icon'],
              color: available 
                  ? AppTheme.primaryCyan
                  : Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'],
                  style: TextStyle(
                    color: available 
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature['description'],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
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
                : Colors.white.withValues(alpha: 0.3),
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
        gradient: LinearGradient(
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