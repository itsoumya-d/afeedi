import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/content_model.dart';
import '../../services/analytics_service.dart';
import 'platform_branding_widget.dart';
import 'video_controls_widget.dart';
import 'universal_platform_player.dart';

class ResponsiveVideoPlayer extends StatefulWidget {
  final Content content;
  final bool autoPlay;
  final bool showControls;
  final bool showBranding;
  final VoidCallback? onFullscreen;
  final Function(double)? onProgress;
  final Function(String)? onQualityChanged;
  final EdgeInsets? padding;
  
  const ResponsiveVideoPlayer({
    super.key,
    required this.content,
    this.autoPlay = false,
    this.showControls = true,
    this.showBranding = true,
    this.onFullscreen,
    this.onProgress,
    this.onQualityChanged,
    this.padding,
  });
  
  @override
  State<ResponsiveVideoPlayer> createState() => _ResponsiveVideoPlayerState();
}

class _ResponsiveVideoPlayerState extends State<ResponsiveVideoPlayer>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isFullscreen = false;
  
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePlayer();
  }
  
  @override
  void dispose() {
    _controlsAnimationController.dispose();
    super.dispose();
  }
  
  void _initializeAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showControls) {
      _controlsAnimationController.forward();
    }
  }
  
  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
      
      // Track initialization start
      await AnalyticsService.instance.trackUserInteraction(
        action: 'video_player_initializing',
        screen: 'video_player',
        additionalData: {
          'content_id': widget.content.id,
          'platform': widget.content.platform.name,
          'content_type': widget.content.contentType.name,
        },
      );
      
      // The UniversalPlatformPlayer will handle all initialization
      // No need to create a separate player here
      
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = error.toString();
      });
      
      await AnalyticsService.instance.trackError(
        errorType: 'video_player_error',
        errorMessage: error.toString(),
        screen: 'video_player',
      );
    }
  }
  
  // Player listeners are now handled by UniversalPlatformPlayer
  
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }
  
  void _toggleFullscreen() async {
    try {
      setState(() {
        _isFullscreen = !_isFullscreen;
      });
      
      if (_isFullscreen) {
        // Enter fullscreen mode
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
          overlays: [],
        );
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        // Exit fullscreen mode
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      
      widget.onFullscreen?.call();
      
      AnalyticsService.instance.trackUserInteraction(
        action: _isFullscreen ? 'fullscreen_entered' : 'fullscreen_exited',
        screen: 'video_player',
        additionalData: {
          'content_id': widget.content.id,
          'platform': widget.content.platform.name,
        },
      );
    } catch (error) {
      // Handle fullscreen error
      AnalyticsService.instance.trackError(
        errorType: 'fullscreen_error',
        errorMessage: error.toString(),
        screen: 'video_player',
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;
        final isMobile = constraints.maxWidth <= 768;
        final aspectRatio = _getAspectRatio();
        
        return Container(
          padding: widget.padding,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Video player content
                    _buildPlayerContent(),
                    
                    // Loading indicator
                    if (_isLoading) _buildLoadingIndicator(),
                    
                    // Error display
                    if (_hasError) _buildErrorDisplay(),
                    
                    // Platform branding
                    if (widget.showBranding && !_hasError)
                      _buildPlatformBranding(),
                    
                    // Video controls
                    if (widget.showControls && !_isLoading && !_hasError)
                      _buildVideoControls(isMobile),
                    
                    // Tap to toggle controls
                    _buildTapDetector(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPlayerContent() {
    return UniversalPlatformPlayer(
      content: widget.content,
      autoPlay: widget.autoPlay,
      showControls: widget.showControls,
      onPlayerReady: () {
        setState(() {
          _isLoading = false;
        });
        
        // Track successful player initialization
        AnalyticsService.instance.trackUserInteraction(
          action: 'universal_player_ready',
          screen: 'video_player',
          additionalData: {
            'content_id': widget.content.id,
            'platform': widget.content.platform.name,
            'content_type': widget.content.contentType.name,
          },
        );
      },
      onError: (error) {
        setState(() {
          _hasError = true;
          _errorMessage = error;
          _isLoading = false;
        });
        
        // Track player error
        AnalyticsService.instance.trackError(
          errorType: 'universal_player_error',
          errorMessage: error,
          screen: 'video_player',
          additionalData: {
            'content_id': widget.content.id,
            'platform': widget.content.platform.name,
          },
        );
      },
    );
  }
  

  
  Widget _buildMobilePlayer() {
    // Implementation for mobile WebView player
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Mobile Player',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorDisplay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlatformBranding() {
    return Positioned(
      top: 12,
      right: 12,
      child: PlatformBrandingWidget(
        platform: widget.content.platform,
        size: 32,
      ),
    );
  }
  
  Widget _buildVideoControls(bool isMobile) {
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _controlsAnimation.value,
          child: VideoControlsWidget(
            player: null, // Player controls now handled by UniversalPlatformPlayer
            content: widget.content,
            isMobile: isMobile,
            onFullscreen: _toggleFullscreen,
            onQualityChanged: widget.onQualityChanged,
            onProgress: widget.onProgress,
          ),
        );
      },
    );
  }
  
  Widget _buildTapDetector() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleControls,
        onDoubleTap: () async {
          // Double-tap play/pause functionality now handled by UniversalPlatformPlayer
        },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
  
  double _getAspectRatio() {
    switch (widget.content.contentType) {
      case ContentType.short:
      case ContentType.reel:
        return 9 / 16; // Vertical aspect ratio
      case ContentType.story:
        return 9 / 16; // Vertical aspect ratio
      case ContentType.video:
      case ContentType.post:
      default:
        return 16 / 9; // Horizontal aspect ratio
    }
  }
}

// Responsive grid for multiple videos
class ResponsiveVideoGrid extends StatelessWidget {
  final List<Content> contents;
  final Function(Content)? onVideoTap;
  final bool autoPlay;
  final EdgeInsets? padding;
  
  const ResponsiveVideoGrid({
    super.key,
    required this.contents,
    this.onVideoTap,
    this.autoPlay = false,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        final childAspectRatio = _getChildAspectRatio(constraints.maxWidth);
        
        return Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final content = contents[index];
              return GestureDetector(
                onTap: () => onVideoTap?.call(content),
                child: ResponsiveVideoPlayer(
                  content: content,
                  autoPlay: false, // Don't autoplay in grid
                  showControls: false, // Minimal controls in grid
                  showBranding: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4; // Desktop
    if (width > 768) return 3;  // Tablet
    if (width > 480) return 2;  // Large mobile
    return 1; // Small mobile
  }
  
  double _getChildAspectRatio(double width) {
    if (width > 768) return 16 / 10; // Desktop/Tablet
    return 16 / 12; // Mobile
  }
}

// Responsive video carousel
class ResponsiveVideoCarousel extends StatelessWidget {
  final List<Content> contents;
  final Function(Content)? onVideoTap;
  final String? title;
  final EdgeInsets? padding;
  
  const ResponsiveVideoCarousel({
    super.key,
    required this.contents,
    this.onVideoTap,
    this.title,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final content = contents[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onVideoTap?.call(content),
                  child: ResponsiveVideoPlayer(
                    content: content,
                    autoPlay: false,
                    showControls: false,
                    showBranding: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}