import 'package:flutter/foundation.dart';
import '../src/stubs/html.dart' if (dart.library.html) 'dart:html' as html;
import '../src/stubs/js.dart' if (dart.library.js) 'dart:js' as js;
import '../models/content_model.dart';
import 'analytics_service.dart';

class BrowserCompatibilityService {
  static BrowserCompatibilityService? _instance;
  static BrowserCompatibilityService get instance => _instance ??= BrowserCompatibilityService._();
  
  BrowserCompatibilityService._();
  
  // Browser detection results
  late BrowserInfo _browserInfo;
  late List<String> _supportedFeatures;
  late Map<String, bool> _featureSupport;
  
  // Initialize browser compatibility checking
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        _browserInfo = _detectBrowser();
        _supportedFeatures = _detectSupportedFeatures();
        _featureSupport = _checkFeatureSupport();
      } else {
        // Mobile apps support all features
        _browserInfo = BrowserInfo(
          name: 'Mobile App',
          version: '1.0.0',
          userAgent: 'Mobile Application',
          isSupported: true,
        );
        _supportedFeatures = _getAllFeatures();
        _featureSupport = Map.fromIterable(
          _getAllFeatures(),
          key: (feature) => feature,
          value: (feature) => true,
        );
      }
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'browser_compatibility_checked',
        screen: 'compatibility',
        additionalData: {
          'browser_name': _browserInfo.name,
          'browser_version': _browserInfo.version,
          'is_supported': _browserInfo.isSupported,
          'supported_features': _supportedFeatures,
        },
      );
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'browser_compatibility_error',
        errorMessage: error.toString(),
        screen: 'compatibility',
      );
      rethrow;
    }
  }
  
  // Get browser information
  BrowserInfo get browserInfo => _browserInfo;
  
  // Get supported features
  List<String> get supportedFeatures => _supportedFeatures;
  
  // Check if browser is supported
  bool get isBrowserSupported => _browserInfo.isSupported;
  
  // Check if specific feature is supported
  bool isFeatureSupported(String feature) {
    return _featureSupport[feature] ?? false;
  }
  
  // Get optimal streaming configuration for current browser
  StreamingConfig getOptimalStreamingConfig() {
    final config = StreamingConfig();
    
    // Video codec support
    if (isFeatureSupported('h264')) {
      config.preferredVideoCodecs.add('h264');
    }
    if (isFeatureSupported('vp9')) {
      config.preferredVideoCodecs.add('vp9');
    }
    if (isFeatureSupported('av1')) {
      config.preferredVideoCodecs.add('av1');
    }
    
    // Audio codec support
    if (isFeatureSupported('aac')) {
      config.preferredAudioCodecs.add('aac');
    }
    if (isFeatureSupported('opus')) {
      config.preferredAudioCodecs.add('opus');
    }
    
    // Streaming protocol support
    if (isFeatureSupported('hls')) {
      config.supportedProtocols.add('hls');
    }
    if (isFeatureSupported('dash')) {
      config.supportedProtocols.add('dash');
    }
    if (isFeatureSupported('mse')) {
      config.supportedProtocols.add('mse');
    }
    
    // Quality settings based on browser performance
    config.maxQuality = _getMaxSupportedQuality();
    config.adaptiveBitrate = isFeatureSupported('mse');
    config.hardwareAcceleration = isFeatureSupported('hardware_acceleration');
    
    return config;
  }
  
  // Get recommended player for content
  String getRecommendedPlayer(Content content) {
    // For YouTube content
    if (content.platform == PlatformType.youtube) {
      if (isFeatureSupported('iframe_api')) {
        return 'youtube_iframe';
      }
      return 'youtube_embed';
    }
    
    // For other platforms
    if (isFeatureSupported('hls') && content.videoUrl?.contains('.m3u8') == true) {
      return 'hls_player';
    }
    
    if (isFeatureSupported('dash') && content.videoUrl?.contains('.mpd') == true) {
      return 'dash_player';
    }
    
    if (isFeatureSupported('mse')) {
      return 'mse_player';
    }
    
    return 'html5_video';
  }
  
  // Check if browser needs polyfills
  List<String> getRequiredPolyfills() {
    final polyfills = <String>[];
    
    if (!isFeatureSupported('promise')) {
      polyfills.add('es6-promise');
    }
    
    if (!isFeatureSupported('fetch')) {
      polyfills.add('whatwg-fetch');
    }
    
    if (!isFeatureSupported('intersection_observer')) {
      polyfills.add('intersection-observer');
    }
    
    if (!isFeatureSupported('resize_observer')) {
      polyfills.add('resize-observer-polyfill');
    }
    
    return polyfills;
  }
  
  // Get browser performance score
  double getBrowserPerformanceScore() {
    double score = 0.0;
    
    // Base score for supported browser
    if (_browserInfo.isSupported) {
      score += 0.3;
    }
    
    // Video support
    if (isFeatureSupported('h264')) score += 0.1;
    if (isFeatureSupported('vp9')) score += 0.1;
    if (isFeatureSupported('av1')) score += 0.05;
    
    // Streaming support
    if (isFeatureSupported('mse')) score += 0.15;
    if (isFeatureSupported('hls')) score += 0.1;
    if (isFeatureSupported('dash')) score += 0.1;
    
    // Modern features
    if (isFeatureSupported('webgl')) score += 0.05;
    if (isFeatureSupported('hardware_acceleration')) score += 0.05;
    
    return score.clamp(0.0, 1.0);
  }
  
  // Get compatibility warnings
  List<String> getCompatibilityWarnings() {
    final warnings = <String>[];
    
    if (!_browserInfo.isSupported) {
      warnings.add('Your browser is not officially supported. Some features may not work correctly.');
    }
    
    if (!isFeatureSupported('mse')) {
      warnings.add('Media Source Extensions not supported. Adaptive streaming may be limited.');
    }
    
    if (!isFeatureSupported('hls') && !isFeatureSupported('dash')) {
      warnings.add('Advanced streaming protocols not supported. Video quality may be limited.');
    }
    
    if (!isFeatureSupported('hardware_acceleration')) {
      warnings.add('Hardware acceleration not available. Video playback may use more CPU.');
    }
    
    if (_browserInfo.name.toLowerCase().contains('internet explorer')) {
      warnings.add('Internet Explorer is deprecated. Please upgrade to a modern browser.');
    }
    
    return warnings;
  }
  
  // Private helper methods
  
  BrowserInfo _detectBrowser() {
    if (!kIsWeb) {
      return BrowserInfo(
        name: 'Mobile App',
        version: '1.0.0',
        userAgent: 'Mobile Application',
        isSupported: true,
      );
    }
    
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    
    String name = 'Unknown';
    String version = '0.0.0';
    bool isSupported = false;
    
    // Chrome
    if (userAgent.contains('chrome') && !userAgent.contains('edge')) {
      name = 'Chrome';
      final match = RegExp(r'chrome/([\d.]+)').firstMatch(userAgent);
      version = match?.group(1) ?? '0.0.0';
      isSupported = _isVersionSupported(version, '80.0.0');
    }
    // Firefox
    else if (userAgent.contains('firefox')) {
      name = 'Firefox';
      final match = RegExp(r'firefox/([\d.]+)').firstMatch(userAgent);
      version = match?.group(1) ?? '0.0.0';
      isSupported = _isVersionSupported(version, '75.0.0');
    }
    // Safari
    else if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
      name = 'Safari';
      final match = RegExp(r'version/([\d.]+)').firstMatch(userAgent);
      version = match?.group(1) ?? '0.0.0';
      isSupported = _isVersionSupported(version, '13.0.0');
    }
    // Edge
    else if (userAgent.contains('edge')) {
      name = 'Edge';
      final match = RegExp(r'edge/([\d.]+)').firstMatch(userAgent);
      version = match?.group(1) ?? '0.0.0';
      isSupported = _isVersionSupported(version, '80.0.0');
    }
    // Internet Explorer
    else if (userAgent.contains('trident') || userAgent.contains('msie')) {
      name = 'Internet Explorer';
      isSupported = false; // IE not supported
    }
    
    return BrowserInfo(
      name: name,
      version: version,
      userAgent: html.window.navigator.userAgent,
      isSupported: isSupported,
    );
  }
  
  List<String> _detectSupportedFeatures() {
    final features = <String>[];
    
    if (!kIsWeb) {
      return _getAllFeatures();
    }
    
    // Video codec support
    final video = html.VideoElement();
    if (video.canPlayType('video/mp4; codecs="avc1.42E01E"') != '') {
      features.add('h264');
    }
    if (video.canPlayType('video/webm; codecs="vp9"') != '') {
      features.add('vp9');
    }
    if (video.canPlayType('video/mp4; codecs="av01.0.08M.08"') != '') {
      features.add('av1');
    }
    
    // Audio codec support
    if (video.canPlayType('audio/mp4; codecs="mp4a.40.2"') != '') {
      features.add('aac');
    }
    if (video.canPlayType('audio/webm; codecs="opus"') != '') {
      features.add('opus');
    }
    
    // Streaming protocol support
    if (video.canPlayType('application/vnd.apple.mpegurl') != '') {
      features.add('hls');
    }
    if (video.canPlayType('application/dash+xml') != '') {
      features.add('dash');
    }
    
    // Modern web features
    if (js.context.hasProperty('MediaSource')) {
      features.add('mse');
    }
    if (js.context.hasProperty('WebGLRenderingContext')) {
      features.add('webgl');
    }
    if (js.context.hasProperty('Promise')) {
      features.add('promise');
    }
    if (js.context.hasProperty('fetch')) {
      features.add('fetch');
    }
    if (js.context.hasProperty('IntersectionObserver')) {
      features.add('intersection_observer');
    }
    if (js.context.hasProperty('ResizeObserver')) {
      features.add('resize_observer');
    }
    
    // Hardware acceleration (approximate detection)
    try {
      final canvas = html.CanvasElement();
      final gl = canvas.getContext('webgl');
      if (gl != null) {
        features.add('hardware_acceleration');
      }
    } catch (e) {
      // Hardware acceleration not available
    }
    
    // iframe API support
    if (js.context.hasProperty('postMessage')) {
      features.add('iframe_api');
    }
    
    return features;
  }
  
  Map<String, bool> _checkFeatureSupport() {
    final support = <String, bool>{};
    
    for (final feature in _getAllFeatures()) {
      support[feature] = _supportedFeatures.contains(feature);
    }
    
    return support;
  }
  
  List<String> _getAllFeatures() {
    return [
      'h264', 'vp9', 'av1',
      'aac', 'opus',
      'hls', 'dash', 'mse',
      'webgl', 'promise', 'fetch',
      'intersection_observer', 'resize_observer',
      'hardware_acceleration', 'iframe_api',
    ];
  }
  
  String _getMaxSupportedQuality() {
    // Determine max quality based on browser capabilities
    if (isFeatureSupported('hardware_acceleration') && 
        isFeatureSupported('vp9')) {
      return '1080p';
    }
    
    if (isFeatureSupported('h264')) {
      return '720p';
    }
    
    return '480p';
  }
  
  bool _isVersionSupported(String version, String minVersion) {
    try {
      final versionParts = version.split('.').map(int.parse).toList();
      final minVersionParts = minVersion.split('.').map(int.parse).toList();
      
      for (int i = 0; i < minVersionParts.length; i++) {
        if (i >= versionParts.length) return false;
        
        if (versionParts[i] > minVersionParts[i]) return true;
        if (versionParts[i] < minVersionParts[i]) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Browser information class
class BrowserInfo {
  final String name;
  final String version;
  final String userAgent;
  final bool isSupported;
  
  const BrowserInfo({
    required this.name,
    required this.version,
    required this.userAgent,
    required this.isSupported,
  });
  
  @override
  String toString() {
    return 'BrowserInfo(name: $name, version: $version, supported: $isSupported)';
  }
}

// Streaming configuration class
class StreamingConfig {
  final List<String> preferredVideoCodecs = [];
  final List<String> preferredAudioCodecs = [];
  final List<String> supportedProtocols = [];
  String maxQuality = '720p';
  bool adaptiveBitrate = false;
  bool hardwareAcceleration = false;
  
  Map<String, dynamic> toJson() {
    return {
      'preferred_video_codecs': preferredVideoCodecs,
      'preferred_audio_codecs': preferredAudioCodecs,
      'supported_protocols': supportedProtocols,
      'max_quality': maxQuality,
      'adaptive_bitrate': adaptiveBitrate,
      'hardware_acceleration': hardwareAcceleration,
    };
  }
  
  @override
  String toString() {
    return 'StreamingConfig(maxQuality: $maxQuality, protocols: $supportedProtocols)';
  }
}