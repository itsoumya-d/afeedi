import 'package:flutter/foundation.dart';
import '../src/stubs/html.dart' if (dart.library.html) 'dart:html' as html;
import 'dart:async';
import '../src/stubs/js.dart' if (dart.library.js) 'dart:js' as js;
import '../models/content_model.dart';
import '../models/user_model.dart';
import 'analytics_service.dart';

class OpenSourceIntegrationService {
  static OpenSourceIntegrationService? _instance;
  static OpenSourceIntegrationService get instance => _instance ??= OpenSourceIntegrationService._();
  
  OpenSourceIntegrationService._();
  
  // Open-source libraries configuration
  static const Map<String, Map<String, dynamic>> openSourceLibraries = {
    // Video streaming libraries
    'hls_js': {
      'name': 'HLS.js',
      'version': '1.4.12',
      'cdn_url': 'https://cdn.jsdelivr.net/npm/hls.js@1.4.12/dist/hls.min.js',
      'description': 'JavaScript HLS client using Media Source Extension',
      'license': 'Apache-2.0',
      'features': ['HLS streaming', 'Adaptive bitrate', 'Live streaming'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge'],
    },
    'dash_js': {
      'name': 'DASH.js',
      'version': '4.7.2',
      'cdn_url': 'https://cdn.dashjs.org/v4.7.2/dash.all.min.js',
      'description': 'DASH client built on MSE',
      'license': 'BSD-3-Clause',
      'features': ['DASH streaming', 'Adaptive bitrate', 'DRM support'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge'],
    },
    'video_js': {
      'name': 'Video.js',
      'version': '8.5.2',
      'cdn_url': 'https://vjs.zencdn.net/8.5.2/video.min.js',
      'css_url': 'https://vjs.zencdn.net/8.5.2/video-js.css',
      'description': 'HTML5 video player',
      'license': 'Apache-2.0',
      'features': ['HTML5 video', 'Plugins', 'Responsive', 'Accessibility'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge', 'IE11'],
    },
    'plyr': {
      'name': 'Plyr',
      'version': '3.7.8',
      'cdn_url': 'https://cdn.plyr.io/3.7.8/plyr.js',
      'css_url': 'https://cdn.plyr.io/3.7.8/plyr.css',
      'description': 'Simple, customizable HTML5 Video, Audio, YouTube and Vimeo player',
      'license': 'MIT',
      'features': ['Multiple providers', 'Responsive', 'Accessible', 'Customizable'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge'],
    },
    
    // AI/ML libraries
    'tensorflow_js': {
      'name': 'TensorFlow.js',
      'version': '4.10.0',
      'cdn_url': 'https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.10.0/dist/tf.min.js',
      'description': 'Machine learning library for JavaScript',
      'license': 'Apache-2.0',
      'features': ['Neural networks', 'Computer vision', 'NLP', 'Recommendation systems'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge'],
    },
    'ml5_js': {
      'name': 'ml5.js',
      'version': '0.12.2',
      'cdn_url': 'https://unpkg.com/ml5@0.12.2/dist/ml5.min.js',
      'description': 'Friendly machine learning for creative coding',
      'license': 'MIT',
      'features': ['Image classification', 'Object detection', 'Sentiment analysis'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge'],
    },
    'brain_js': {
      'name': 'Brain.js',
      'version': '2.0.0-beta.20',
      'cdn_url': 'https://unpkg.com/brain.js@2.0.0-beta.20/dist/brain.min.js',
      'description': 'Neural networks in JavaScript',
      'license': 'MIT',
      'features': ['Neural networks', 'LSTM', 'RNN', 'GPU acceleration'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge'],
    },
    
    // Utility libraries
    'lodash': {
      'name': 'Lodash',
      'version': '4.17.21',
      'cdn_url': 'https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js',
      'description': 'Modern JavaScript utility library',
      'license': 'MIT',
      'features': ['Array manipulation', 'Object utilities', 'Function utilities'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge', 'IE9+'],
    },
    'rxjs': {
      'name': 'RxJS',
      'version': '7.8.1',
      'cdn_url': 'https://unpkg.com/rxjs@7.8.1/dist/bundles/rxjs.umd.min.js',
      'description': 'Reactive Extensions for JavaScript',
      'license': 'Apache-2.0',
      'features': ['Reactive programming', 'Observables', 'Operators'],
      'browser_support': ['Chrome', 'Firefox', 'Safari', 'Edge'],
    },
  };
  
  // Loaded libraries tracking
  final Set<String> _loadedLibraries = {};

  // Initialize open-source integration
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await _initializeWebLibraries();
      }
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'opensource_integration_initialized',
        screen: 'streaming',
        additionalData: {
          'loaded_libraries': _loadedLibraries.toList(),
          'platform': kIsWeb ? 'web' : 'mobile',
        },
      );
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'opensource_integration_error',
        errorMessage: error.toString(),
        screen: 'streaming',
      );
      rethrow;
    }
  }
  
  // Load specific open-source library
  Future<bool> loadLibrary(String libraryKey) async {
    if (_loadedLibraries.contains(libraryKey)) {
      return true; // Already loaded
    }
    
    final libraryConfig = openSourceLibraries[libraryKey];
    if (libraryConfig == null) {
      debugPrint('Library $libraryKey not found in configuration');
      return false;
    }
    
    try {
      if (kIsWeb) {
        await _loadWebLibrary(libraryKey, libraryConfig);
      }
      
      _loadedLibraries.add(libraryKey);
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'opensource_library_loaded',
        screen: 'streaming',
        additionalData: {
          'library': libraryKey,
          'version': libraryConfig['version'],
        },
      );
      
      return true;
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'library_load_error',
        errorMessage: 'Failed to load $libraryKey: $error',
        screen: 'streaming',
      );
      return false;
    }
  }
  
  // Get HLS.js player instance
  Future<dynamic> getHLSPlayer(html.VideoElement videoElement) async {
    if (!await loadLibrary('hls_js')) {
      throw Exception('Failed to load HLS.js library');
    }
    
    if (kIsWeb) {
      // Create HLS.js instance
      final hls = js.context.callMethod('eval', ['new Hls()']);
      return hls;
    }
    
    return null;
  }
  
  // Get DASH.js player instance
  Future<dynamic> getDASHPlayer() async {
    if (!await loadLibrary('dash_js')) {
      throw Exception('Failed to load DASH.js library');
    }
    
    if (kIsWeb) {
      // Create DASH.js instance
      final dashPlayer = js.context.callMethod('eval', ['dashjs.MediaPlayer().create()']);
      return dashPlayer;
    }
    
    return null;
  }
  
  // Get Video.js player instance
  Future<dynamic> getVideoJSPlayer(String elementId, Map<String, dynamic> options) async {
    if (!await loadLibrary('video_js')) {
      throw Exception('Failed to load Video.js library');
    }
    
    if (kIsWeb) {
      // Create Video.js instance
      final player = js.context.callMethod('videojs', [elementId, options]);
      return player;
    }
    
    return null;
  }
  
  // Get TensorFlow.js instance for AI recommendations
  Future<dynamic> getTensorFlowJS() async {
    if (!await loadLibrary('tensorflow_js')) {
      throw Exception('Failed to load TensorFlow.js library');
    }
    
    if (kIsWeb) {
      return js.context['tf'];
    }
    
    return null;
  }
  
  // Create AI recommendation model using TensorFlow.js
  Future<AIRecommendationModel?> createRecommendationModel() async {
    try {
      final tf = await getTensorFlowJS();
      if (tf == null) return null;
      
      return AIRecommendationModel(tf);
    } catch (error) {
      debugPrint('Error creating recommendation model: $error');
      return null;
    }
  }
  
  // Get browser compatibility for libraries
  Map<String, List<String>> getBrowserCompatibility() {
    final compatibility = <String, List<String>>{};
    
    for (final entry in openSourceLibraries.entries) {
      final libraryKey = entry.key;
      final config = entry.value;
      compatibility[libraryKey] = List<String>.from(config['browser_support'] ?? []);
    }
    
    return compatibility;
  }
  
  // Check if library is supported in current browser
  bool isLibrarySupported(String libraryKey) {
    if (!kIsWeb) return true; // Mobile apps support all libraries
    
    final config = openSourceLibraries[libraryKey];
    if (config == null) return false;
    
    final supportedBrowsers = List<String>.from(config['browser_support'] ?? []);
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    
    for (final browser in supportedBrowsers) {
      if (userAgent.contains(browser.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  // Get recommended libraries for content type
  List<String> getRecommendedLibraries(ContentType contentType) {
    switch (contentType) {
      case ContentType.video:
        return ['hls_js', 'dash_js', 'video_js'];
      case ContentType.short:
      case ContentType.reel:
        return ['plyr', 'video_js'];
      case ContentType.story:
        return ['plyr'];
      case ContentType.post:
        return ['plyr'];
    }
  }
  
  // Get library information
  Map<String, dynamic>? getLibraryInfo(String libraryKey) {
    return openSourceLibraries[libraryKey];
  }
  
  // Get all available libraries
  Map<String, Map<String, dynamic>> getAllLibraries() {
    return Map.from(openSourceLibraries);
  }
  
  // Check if library is loaded
  bool isLibraryLoaded(String libraryKey) {
    return _loadedLibraries.contains(libraryKey);
  }
  
  // Private helper methods
  
  Future<void> _initializeWebLibraries() async {
    // Load essential libraries for web streaming
    final essentialLibraries = ['hls_js', 'video_js', 'tensorflow_js'];
    
    for (final library in essentialLibraries) {
      if (isLibrarySupported(library)) {
        await loadLibrary(library);
      }
    }
  }
  
  Future<void> _loadWebLibrary(String libraryKey, Map<String, dynamic> config) async {
    // Load CSS if available
    if (config['css_url'] != null) {
      await _loadCSS(config['css_url']);
    }
    
    // Load JavaScript
    await _loadScript(config['cdn_url']);
    
    // Wait for library to be available
    await _waitForLibrary(libraryKey);
  }
  
  Future<void> _loadScript(String url) async {
    final script = html.ScriptElement()
      ..src = url
      ..type = 'text/javascript'
      ..async = true;
    
    final completer = Completer<void>();
    
    script.onLoad.listen((_) {
      completer.complete();
    });
    
    script.onError.listen((_) {
      completer.completeError('Failed to load script: $url');
    });
    
    html.document.head!.append(script);
    
    return completer.future;
  }
  
  Future<void> _loadCSS(String url) async {
    final link = html.LinkElement()
      ..rel = 'stylesheet'
      ..type = 'text/css'
      ..href = url;
    
    html.document.head!.append(link);
  }
  
  Future<void> _waitForLibrary(String libraryKey) async {
    // Wait for specific library globals to be available
    final maxAttempts = 50;
    var attempts = 0;
    
    while (attempts < maxAttempts) {
      if (_isLibraryAvailable(libraryKey)) {
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    throw Exception('Library $libraryKey failed to load within timeout');
  }
  
  bool _isLibraryAvailable(String libraryKey) {
    if (!kIsWeb) return true;
    
    switch (libraryKey) {
      case 'hls_js':
        return js.context['Hls'] != null;
      case 'dash_js':
        return js.context['dashjs'] != null;
      case 'video_js':
        return js.context['videojs'] != null;
      case 'plyr':
        return js.context['Plyr'] != null;
      case 'tensorflow_js':
        return js.context['tf'] != null;
      case 'ml5_js':
        return js.context['ml5'] != null;
      case 'brain_js':
        return js.context['brain'] != null;
      case 'lodash':
        return js.context['_'] != null;
      case 'rxjs':
        return js.context['rxjs'] != null;
      default:
        return false;
    }
  }
}

// AI Recommendation Model using TensorFlow.js
class AIRecommendationModel {
  final dynamic tf;
  dynamic _model;
  bool _isInitialized = false;
  
  AIRecommendationModel(this.tf);
  
  // Initialize the recommendation model
  Future<void> initialize() async {
    try {
      // Create a simple neural network for recommendations
      _model = tf.sequential({
        'layers': [
          tf.layers.dense({
            'inputShape': [10], // 10 features: platform, content type, user preferences, etc.
            'units': 64,
            'activation': 'relu'
          }),
          tf.layers.dropout({'rate': 0.2}),
          tf.layers.dense({
            'units': 32,
            'activation': 'relu'
          }),
          tf.layers.dense({
            'units': 1,
            'activation': 'sigmoid' // Output recommendation score 0-1
          })
        ]
      });
      
      // Compile the model
      _model.compile({
        'optimizer': 'adam',
        'loss': 'binaryCrossentropy',
        'metrics': ['accuracy']
      });
      
      _isInitialized = true;
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'ai_model_initialized',
        screen: 'ai_recommendations',
        additionalData: {
          'model_type': 'tensorflow_js',
          'architecture': 'neural_network',
        },
      );
    } catch (error) {
      await AnalyticsService.instance.trackError(
        errorType: 'ai_model_error',
        errorMessage: error.toString(),
        screen: 'ai_recommendations',
      );
      rethrow;
    }
  }
  
  // Predict recommendation score for content
  Future<double> predictScore({
    required Content content,
    User? user,
    Map<String, dynamic>? context,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Prepare input features
      final features = _prepareFeatures(content, user, context);
      
      // Create tensor from features
      final inputTensor = tf.tensor2d([features], [1, features.length]);
      
      // Make prediction
      final prediction = _model.predict(inputTensor);
      final score = await prediction.data();
      
      // Clean up tensors
      inputTensor.dispose();
      prediction.dispose();
      
      return score[0].toDouble();
    } catch (error) {
      debugPrint('Error predicting recommendation score: $error');
      return 0.5; // Default neutral score
    }
  }
  
  // Train the model with user feedback
  Future<void> trainWithFeedback(List<Map<String, dynamic>> trainingData) async {
    if (!_isInitialized || trainingData.isEmpty) return;
    
    try {
      final features = <List<double>>[];
      final labels = <double>[];
      
      for (final data in trainingData) {
        features.add(_prepareFeatures(
          data['content'],
          data['user'],
          data['context'],
        ));
        labels.add(data['score'].toDouble());
      }
      
      final xs = tf.tensor2d(features);
      final ys = tf.tensor2d(labels.map((l) => [l]).toList());
      
      // Train the model
      await _model.fit(xs, ys, {
        'epochs': 10,
        'batchSize': 32,
        'validationSplit': 0.2,
        'verbose': 0,
      });
      
      // Clean up tensors
      xs.dispose();
      ys.dispose();
      
      await AnalyticsService.instance.trackUserInteraction(
        action: 'ai_model_trained',
        screen: 'ai_recommendations',
        additionalData: {
          'training_samples': trainingData.length,
        },
      );
    } catch (error) {
      debugPrint('Error training model: $error');
    }
  }
  
  // Prepare feature vector for prediction
  List<double> _prepareFeatures(
    Content content,
    User? user,
    Map<String, dynamic>? context,
  ) {
    return [
      // Platform encoding (0-3)
      content.platform.index.toDouble() / 3.0,
      
      // Content type encoding (0-4)
      content.contentType.index.toDouble() / 4.0,
      
      // Content popularity (normalized)
      (content.viewCount / 1000000.0).clamp(0.0, 1.0),
      
      // Content engagement rate
      content.viewCount > 0 
          ? (content.likeCount / content.viewCount).clamp(0.0, 1.0)
          : 0.0,
      
      // Content recency (days old, normalized)
      content.publishedAt != null
          ? (1.0 - (DateTime.now().difference(content.publishedAt!).inDays / 365.0)).clamp(0.0, 1.0)
          : 0.5,
      
      // User premium status
      user?.isPremium == true ? 1.0 : 0.0,
      
      // Time of day (0-1)
      DateTime.now().hour / 24.0,
      
      // Day of week (0-1)
      DateTime.now().weekday / 7.0,
      
      // Content duration (normalized)
      content.durationSeconds != null
          ? (content.durationSeconds! / 3600.0).clamp(0.0, 1.0)
          : 0.5,
      
      // Random factor for exploration
      0.1,
    ];
  }
  
  // Dispose model resources
  void dispose() {
    if (_model != null) {
      _model.dispose();
    }
  }
}

