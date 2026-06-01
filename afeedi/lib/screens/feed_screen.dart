import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../core/theme/app_theme.dart';
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
        _posts = _selectedPlatforms.length == PlatformType.values.length
            ? feedContent
            : feedContent.where((p) => _selectedPlatforms.contains(p.platform)).toList();
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
        _posts = _selectedPlatforms.length == PlatformType.values.length
            ? feedContent
            : feedContent.where((p) => _selectedPlatforms.contains(p.platform)).toList();
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
      debugPrint('Error refreshing feed: $e');
    }
  }

  void _onLoading() async {
    try {
      final morePosts = await ContentService.instance.loadMoreContent(_posts.length, limit: 5);
      final filtered = _selectedPlatforms.length == PlatformType.values.length
          ? morePosts
          : morePosts.where((p) => _selectedPlatforms.contains(p.platform)).toList();
      setState(() {
        _posts.addAll(filtered);
      });
      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
      debugPrint('Error loading more posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Feed'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
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
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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
              title: const Text('Filter Posts'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: PlatformType.values.map((platform) {
                  return CheckboxListTile(
                    title: Text(platform.name),
                    value: _selectedPlatforms.contains(platform),
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
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadPosts(); // Reload posts with new filters
                  },
                  child: const Text('Apply'),
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