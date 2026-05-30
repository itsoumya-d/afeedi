import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../widgets/feed/enhanced_feed_post_card.dart';
import '../widgets/common/shared_bottom_navigation.dart';
import '../services/content_service.dart';
import '../models/content_model.dart';
import '../widgets/common/loading_shimmer.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  List<Content> _posts = [];
  bool _isLoading = true;
  List<PlatformType> _selectedPlatforms = PlatformType.values;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final feedContent = await ContentService.instance.getFeedContent();
      setState(() {
        _posts = feedContent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading feed: $e');
    }
  }



  Future<void> _onRefresh() async {
    try {
      final feedContent = await ContentService.instance.getFeedContent();
      setState(() {
        _posts = feedContent;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
      debugPrint('Error refreshing feed: $e');
    }
  }

  void _onLoading() async {
    try {
      final morePosts = await ContentService.instance.getFeedContent(limit: 5);
      setState(() {
        _posts.addAll(morePosts);
      });
      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
      debugPrint('Error loading more posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Content Feed',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingShimmer()
          : SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: true,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: EnhancedFeedPostCard(
                      content: _posts[index],
                      showPlatformLogo: true,
                      showInteractions: true,
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: SharedBottomNavigation(
        currentIndex: 0, // Assuming feed is accessed from Home tab
        onTabChanged: (index) {
          // Navigate to dashboard with specific tab
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard',
            (route) => false,
            arguments: {'initialTab': index},
          );
        },
        showFloatingActionButton: false,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text('Filter Posts', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: PlatformType.values.map((platform) {
                  return CheckboxListTile(
                    title: Text(
                      platform.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: _selectedPlatforms.contains(platform),
                    activeColor: const Color(0xFF00D4FF),
                    checkColor: Colors.black,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedPlatforms.add(platform);
                        } else {
                          _selectedPlatforms.remove(platform);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadPosts(); // Reload posts with new filters
                  },
                  child: const Text('Apply', style: TextStyle(color: Color(0xFF00D4FF))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}