import 'package:flutter/material.dart';
import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import 'responsive_video_player.dart';
import 'platform_branding_widget.dart';

class WebStreamingInterface extends StatefulWidget {
  final List<Content> contents;
  final bool enableGuestMode;
  final Function(Content)? onContentSelected;
  final Function(String)? onSearch;
  final EdgeInsets? padding;
  
  const WebStreamingInterface({
    super.key,
    required this.contents,
    this.enableGuestMode = true,
    this.onContentSelected,
    this.onSearch,
    this.padding,
  });
  
  @override
  State<WebStreamingInterface> createState() => _WebStreamingInterfaceState();
}

class _WebStreamingInterfaceState extends State<WebStreamingInterface>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Content? _selectedContent;
  bool _isFullscreen = false;
  String _searchQuery = '';
  List<Content> _filteredContents = [];
  
  // Platform filter
  Set<PlatformType> _selectedPlatforms = {};
  
  // View mode
  ViewMode _viewMode = ViewMode.grid;
  
  @override
  void initState() {
    super.initState();
    _initializeInterface();
    _filteredContents = widget.contents;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _initializeInterface() {
    // Initialize tab controller for different content categories
    _tabController = TabController(
      length: 5, // All, Videos, Shorts, Stories, Posts
      vsync: this,
    );
    
    // Initialize all platforms as selected
    _selectedPlatforms = Set.from(PlatformType.values);
    
    // Track interface initialization
    AnalyticsService.instance.trackUserInteraction(
      action: 'web_streaming_interface_initialized',
      screen: 'streaming_interface',
      additionalData: {
        'content_count': widget.contents.length,
        'guest_mode': widget.enableGuestMode,
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isFullscreen ? _buildFullscreenPlayer() : _buildMainInterface(),
    );
  }
  
  Widget _buildMainInterface() {
    return Column(
      children: [
        // Header with search and filters
        _buildHeader(),
        
        // Platform filters
        _buildPlatformFilters(),
        
        // Content tabs
        _buildContentTabs(),
        
        // Main content area
        Expanded(
          child: _selectedContent != null
              ? _buildPlayerView()
              : _buildContentGrid(),
        ),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          // Logo/Title
          const Text(
            'Afeedi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Search bar
          Expanded(
            child: _buildSearchBar(),
          ),
          
          const SizedBox(width: 16),
          
          // View mode toggle
          _buildViewModeToggle(),
          
          const SizedBox(width: 16),
          
          // User account or guest indicator
          _buildUserIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search content...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterContent();
          });
          
          widget.onSearch?.call(value);
          
          AnalyticsService.instance.trackUserInteraction(
            action: 'content_searched',
            screen: 'streaming_interface',
            additionalData: {
              'query': value,
              'query_length': value.length,
            },
          );
        },
      ),
    );
  }
  
  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(ViewMode.grid, Icons.grid_view),
          _buildViewModeButton(ViewMode.list, Icons.list),
          _buildViewModeButton(ViewMode.carousel, Icons.view_carousel),
        ],
      ),
    );
  }
  
  Widget _buildViewModeButton(ViewMode mode, IconData icon) {
    final isSelected = _viewMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = mode;
        });
        
        AnalyticsService.instance.trackUserInteraction(
          action: 'view_mode_changed',
          screen: 'streaming_interface',
          additionalData: {
            'new_mode': mode.name,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }
  
  Widget _buildUserIndicator() {
    final user = AuthService.instance.currentUser;
    
    if (user != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Text(
              user.email.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            user.email.split('@')[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      );
    }
    
    if (widget.enableGuestMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange,
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              color: Colors.orange,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Guest',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox();
  }
  
  Widget _buildPlatformFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: PlatformType.values.length,
        itemBuilder: (context, index) {
          final platform = PlatformType.values[index];
          final isSelected = _selectedPlatforms.contains(platform);
          
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedPlatforms.remove(platform);
                } else {
                  _selectedPlatforms.add(platform);
                }
                _filterContent();
              });
              
              AnalyticsService.instance.trackUserInteraction(
                action: 'platform_filter_toggled',
                screen: 'streaming_interface',
                additionalData: {
                  'platform': platform.name,
                  'selected': !isSelected,
                },
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withValues(alpha: 0.2) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? Colors.white 
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlatformLogoWidget(
                    platform: platform,
                    size: 20,
                    showBackground: false,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getPlatformName(platform),
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildContentTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.red,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        onTap: (index) {
          _filterContent();
          
          AnalyticsService.instance.trackUserInteraction(
            action: 'content_tab_selected',
            screen: 'streaming_interface',
            additionalData: {
              'tab_index': index,
              'tab_name': _getTabName(index),
            },
          );
        },
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Videos'),
          Tab(text: 'Shorts'),
          Tab(text: 'Stories'),
          Tab(text: 'Posts'),
        ],
      ),
    );
  }
  
  Widget _buildContentGrid() {
    if (_filteredContents.isEmpty) {
      return _buildEmptyState();
    }
    
    switch (_viewMode) {
      case ViewMode.grid:
        return ResponsiveVideoGrid(
          contents: _filteredContents,
          onVideoTap: _selectContent,
          padding: widget.padding,
        );
      case ViewMode.list:
        return _buildListView();
      case ViewMode.carousel:
        return _buildCarouselView();
    }
  }
  
  Widget _buildListView() {
    return ListView.builder(
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: _filteredContents.length,
      itemBuilder: (context, index) {
        final content = _filteredContents[index];
        return _buildListItem(content);
      },
    );
  }
  
  Widget _buildListItem(Content content) {
    return GestureDetector(
      onTap: () => _selectContent(content),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 120,
                height: 68,
                color: Colors.black,
                child: content.thumbnailUrl != null
                    ? Image.network(
                        content.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 32,
                          );
                        },
                      )
                    : const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title ?? 'Untitled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content.creatorName ?? 'Unknown Creator',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      PlatformBrandingWidget(
                        platform: content.platform,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        content.formattedViewCount,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (content.durationSeconds != null) ...<Widget>[
                        const SizedBox(width: 8),
                        Text(
                          content.formattedDuration,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCarouselView() {
    return ResponsiveVideoCarousel(
      contents: _filteredContents,
      onVideoTap: _selectContent,
      title: 'Recommended Content',
      padding: widget.padding,
    );
  }
  
  Widget _buildPlayerView() {
    if (_selectedContent == null) return const SizedBox();
    
    return Column(
      children: [
        // Back button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedContent = null;
                  });
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Back to Grid',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Video player
        Expanded(
          child: ResponsiveVideoPlayer(
            content: _selectedContent!,
            autoPlay: true,
            showControls: true,
            showBranding: true,
            onFullscreen: () {
              setState(() {
                _isFullscreen = true;
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildFullscreenPlayer() {
    if (_selectedContent == null) return const SizedBox();
    
    return Stack(
      children: [
        ResponsiveVideoPlayer(
          content: _selectedContent!,
          autoPlay: true,
          showControls: true,
          showBranding: true,
          onFullscreen: () {
            setState(() {
              _isFullscreen = false;
            });
          },
        ),
        
        // Exit fullscreen button
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isFullscreen = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fullscreen_exit,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No content found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  void _selectContent(Content content) {
    setState(() {
      _selectedContent = content;
    });
    
    widget.onContentSelected?.call(content);
    
    AnalyticsService.instance.trackUserInteraction(
      action: 'content_selected',
      screen: 'streaming_interface',
      additionalData: {
        'content_id': content.id,
        'platform': content.platform.name,
        'content_type': content.contentType.name,
      },
    );
  }
  
  void _filterContent() {
    setState(() {
      _filteredContents = widget.contents.where((content) {
        // Platform filter
        if (!_selectedPlatforms.contains(content.platform)) {
          return false;
        }
        
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final title = content.title?.toLowerCase() ?? '';
          final creator = content.creatorName?.toLowerCase() ?? '';
          final description = content.description?.toLowerCase() ?? '';
          
          if (!title.contains(query) && 
              !creator.contains(query) && 
              !description.contains(query)) {
            return false;
          }
        }
        
        // Tab filter
        final tabIndex = _tabController.index;
        switch (tabIndex) {
          case 0: // All
            return true;
          case 1: // Videos
            return content.contentType == ContentType.video;
          case 2: // Shorts
            return content.contentType == ContentType.short || 
                   content.contentType == ContentType.reel;
          case 3: // Stories
            return content.contentType == ContentType.story;
          case 4: // Posts
            return content.contentType == ContentType.post;
          default:
            return true;
        }
      }).toList();
    });
  }
  
  String _getPlatformName(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return 'YouTube';
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.tiktok:
        return 'TikTok';
      case PlatformType.facebook:
        return 'Facebook';
    }
  }
  
  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'all';
      case 1:
        return 'videos';
      case 2:
        return 'shorts';
      case 3:
        return 'stories';
      case 4:
        return 'posts';
      default:
        return 'unknown';
    }
  }
}

// View mode enum
enum ViewMode {
  grid,
  list,
  carousel,
}