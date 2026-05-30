import 'dart:convert';
import 'package:http/http.dart' as http;

// Replace with your YouTube Data API v3 key from https://console.cloud.google.com
const String _apiKey = '';

class YouTubeVideo {
  final String id;
  final String title;
  final String description;
  final String channelTitle;
  final String channelId;
  final String publishedAt;
  final int viewCount;
  final int likeCount;
  final String duration;
  final List<String> tags;
  final String categoryId;

  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.channelTitle,
    required this.channelId,
    required this.publishedAt,
    required this.viewCount,
    required this.likeCount,
    required this.duration,
    required this.tags,
    required this.categoryId,
  });

  /// Returns the YouTube watch URL for this video.
  String get watchUrl => 'https://www.youtube.com/watch?v=$id';

  /// Returns the maxresdefault thumbnail URL for this video.
  String get thumbnailUrl => 'https://i.ytimg.com/vi/$id/maxresdefault.jpg';

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final statistics = json['statistics'] as Map<String, dynamic>? ?? {};
    final contentDetails =
        json['contentDetails'] as Map<String, dynamic>? ?? {};

    final rawId = json['id'];
    final String videoId = rawId is Map
        ? (rawId['videoId'] as String? ?? '')
        : (rawId as String? ?? '');

    return YouTubeVideo(
      id: videoId,
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      channelId: snippet['channelId'] as String? ?? '',
      publishedAt: snippet['publishedAt'] as String? ?? '',
      viewCount:
          int.tryParse(statistics['viewCount'] as String? ?? '0') ?? 0,
      likeCount:
          int.tryParse(statistics['likeCount'] as String? ?? '0') ?? 0,
      duration: contentDetails['duration'] as String? ?? 'PT0S',
      tags: List<String>.from(snippet['tags'] as List? ?? []),
      categoryId: snippet['categoryId'] as String? ?? '',
    );
  }
}

class YouTubeDataApiService {
  static YouTubeDataApiService? _instance;
  static YouTubeDataApiService get instance =>
      _instance ??= YouTubeDataApiService._();

  YouTubeDataApiService._();

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const Duration _cacheDuration = Duration(minutes: 5);

  // In-memory cache: cacheKey -> (videos, fetchedAt)
  final Map<String, (List<YouTubeVideo>, DateTime)> _cache = {};

  bool _isCacheValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    return DateTime.now().difference(entry.$2) < _cacheDuration;
  }

  // ---------------------------------------------------------------------------
  // Public API methods
  // ---------------------------------------------------------------------------

  /// Fetches trending videos using chart=mostPopular.
  /// Falls back to mock data when the API key is absent or on any error.
  Future<List<YouTubeVideo>> fetchTrendingVideos({
    String? categoryId,
    String regionCode = 'US',
    int maxResults = 20,
  }) async {
    final cacheKey =
        'trending_${categoryId ?? 'all'}_${regionCode}_$maxResults';
    if (_isCacheValid(cacheKey)) return _cache[cacheKey]!.$1;

    if (_apiKey.isEmpty) return _mockTrendingVideos();

    try {
      final params = <String, String>{
        'part': 'snippet,statistics,contentDetails',
        'chart': 'mostPopular',
        'regionCode': regionCode,
        'maxResults': maxResults.toString(),
        'key': _apiKey,
        if (categoryId != null) 'videoCategoryId': categoryId,
      };
      final uri = Uri.parse('$_baseUrl/videos').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode != 200) return _mockTrendingVideos();

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List? ?? [])
          .map((e) => YouTubeVideo.fromJson(e as Map<String, dynamic>))
          .toList();

      _cache[cacheKey] = (items, DateTime.now());
      return items;
    } catch (_) {
      return _mockTrendingVideos();
    }
  }

  /// Searches YouTube for [query]. Falls back to mock data on any error.
  Future<List<YouTubeVideo>> fetchVideosByQuery({
    required String query,
    int maxResults = 20,
  }) async {
    final cacheKey = 'search_${query}_$maxResults';
    if (_isCacheValid(cacheKey)) return _cache[cacheKey]!.$1;

    if (_apiKey.isEmpty) return _mockSearchVideos(query);

    try {
      // Step 1: search endpoint to get video IDs
      final searchParams = <String, String>{
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': maxResults.toString(),
        'key': _apiKey,
      };
      final searchUri =
          Uri.parse('$_baseUrl/search').replace(queryParameters: searchParams);
      final searchResponse = await http.get(searchUri);
      if (searchResponse.statusCode != 200) return _mockSearchVideos(query);

      final searchData =
          jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final ids = (searchData['items'] as List? ?? [])
          .map((e) {
            final idField = e['id'];
            return idField is Map
                ? idField['videoId'] as String? ?? ''
                : idField as String? ?? '';
          })
          .where((id) => id.isNotEmpty)
          .join(',');

      if (ids.isEmpty) return _mockSearchVideos(query);

      // Step 2: videos endpoint for full details
      final detailParams = <String, String>{
        'part': 'snippet,statistics,contentDetails',
        'id': ids,
        'key': _apiKey,
      };
      final detailUri =
          Uri.parse('$_baseUrl/videos').replace(queryParameters: detailParams);
      final detailResponse = await http.get(detailUri);
      if (detailResponse.statusCode != 200) return _mockSearchVideos(query);

      final detailData =
          jsonDecode(detailResponse.body) as Map<String, dynamic>;
      final items = (detailData['items'] as List? ?? [])
          .map((e) => YouTubeVideo.fromJson(e as Map<String, dynamic>))
          .toList();

      _cache[cacheKey] = (items, DateTime.now());
      return items;
    } catch (_) {
      return _mockSearchVideos(query);
    }
  }

  /// Fetches snippet, statistics and contentDetails for a single [videoId].
  Future<YouTubeVideo?> fetchVideoDetails(String videoId) async {
    final cacheKey = 'detail_$videoId';
    if (_isCacheValid(cacheKey)) return _cache[cacheKey]!.$1.first;

    if (_apiKey.isEmpty) {
      return _mockTrendingVideos().firstWhere(
        (v) => v.id == videoId,
        orElse: () => _mockTrendingVideos().first,
      );
    }

    try {
      final params = <String, String>{
        'part': 'snippet,statistics,contentDetails',
        'id': videoId,
        'key': _apiKey,
      };
      final uri = Uri.parse('$_baseUrl/videos').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      if (items.isEmpty) return null;

      final video =
          YouTubeVideo.fromJson(items.first as Map<String, dynamic>);
      _cache[cacheKey] = ([video], DateTime.now());
      return video;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Mock data – used when API key is empty or any network error occurs
  // ---------------------------------------------------------------------------

  List<YouTubeVideo> _mockTrendingVideos() {
    return const [
      YouTubeVideo(
        id: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        description:
            'The official video for "Never Gonna Give You Up" by Rick Astley.',
        channelTitle: 'Rick Astley',
        channelId: 'UCuAXFkgsw1L7xaCfnd5JJOw',
        publishedAt: '2009-10-25T06:57:33Z',
        viewCount: 1400000000,
        likeCount: 14500000,
        duration: 'PT3M33S',
        tags: ['Rick Astley', 'pop', '80s'],
        categoryId: '10',
      ),
      YouTubeVideo(
        id: 'jNQXAC9IVRw',
        title: 'Me at the zoo',
        description: 'The first video on YouTube, uploaded on April 23, 2005.',
        channelTitle: 'jawed',
        channelId: 'UC4QobU6STFB0P71PMvkJZiQ',
        publishedAt: '2005-04-24T03:31:52Z',
        viewCount: 270000000,
        likeCount: 5400000,
        duration: 'PT19S',
        tags: ['first video', 'zoo', 'elephants'],
        categoryId: '22',
      ),
      YouTubeVideo(
        id: '9bZkp7q19f0',
        title: 'PSY - GANGNAM STYLE M/V',
        description: 'PSY - GANGNAM STYLE official music video.',
        channelTitle: 'officialpsy',
        channelId: 'UCrDkAvwZum-UTjHmzDI2iIw',
        publishedAt: '2012-07-15T07:46:32Z',
        viewCount: 4900000000,
        likeCount: 24000000,
        duration: 'PT4M13S',
        tags: ['PSY', 'Gangnam Style', 'K-pop'],
        categoryId: '10',
      ),
      YouTubeVideo(
        id: 'kJQP7kiw5Fk',
        title: 'Luis Fonsi - Despacito ft. Daddy Yankee',
        description: 'Official music video for Despacito.',
        channelTitle: 'Luis Fonsi',
        channelId: 'UCxoq-4GI4EHaEe2UvMlQAJQ',
        publishedAt: '2017-01-13T00:00:00Z',
        viewCount: 8200000000,
        likeCount: 51000000,
        duration: 'PT4M41S',
        tags: ['Despacito', 'Luis Fonsi', 'Latin'],
        categoryId: '10',
      ),
      YouTubeVideo(
        id: 'OPf0YbXqDm0',
        title: 'Mark Ronson - Uptown Funk ft. Bruno Mars',
        description: 'Uptown Funk official video.',
        channelTitle: 'MarkRonsonVEVO',
        channelId: 'UCsRM0YB_dabtEPGPTKo-gcw',
        publishedAt: '2014-11-19T00:00:00Z',
        viewCount: 4700000000,
        likeCount: 33000000,
        duration: 'PT4M30S',
        tags: ['Uptown Funk', 'Bruno Mars', 'funk'],
        categoryId: '10',
      ),
      YouTubeVideo(
        id: 'RgKAFK5djSk',
        title: 'Wiz Khalifa - See You Again ft. Charlie Puth',
        description: 'Official video for See You Again from Furious 7.',
        channelTitle: 'Wiz Khalifa',
        channelId: 'UCVmc3ov8jA-P8VuSqFN-xaQ',
        publishedAt: '2015-04-06T00:00:00Z',
        viewCount: 5700000000,
        likeCount: 40000000,
        duration: 'PT3M50S',
        tags: ['See You Again', 'Wiz Khalifa', 'Furious 7'],
        categoryId: '10',
      ),
      YouTubeVideo(
        id: 'JGwWNGJdvx8',
        title: 'Ed Sheeran - Shape of You',
        description: 'Official music video for Shape of You by Ed Sheeran.',
        channelTitle: 'Ed Sheeran',
        channelId: 'UC0C-w0YjGpqDXGB8IHb662A',
        publishedAt: '2017-01-30T00:00:00Z',
        viewCount: 5800000000,
        likeCount: 44000000,
        duration: 'PT3M53S',
        tags: ['Ed Sheeran', 'Shape of You', 'pop'],
        categoryId: '10',
      ),
      YouTubeVideo(
        id: 'pRpeEdMmmQ0',
        title: 'Shakira - Waka Waka (This Time for Africa)',
        description: 'Official 2010 FIFA World Cup song.',
        channelTitle: 'Shakira',
        channelId: 'UCp4Y5nfUJzHUnlRQ4m73VTg',
        publishedAt: '2010-06-04T00:00:00Z',
        viewCount: 3300000000,
        likeCount: 23000000,
        duration: 'PT3M36S',
        tags: ['Waka Waka', 'FIFA', 'World Cup'],
        categoryId: '10',
      ),
      YouTubeVideo(
        id: 'YqeW9_5kURI',
        title: 'Baby Shark Dance | Most Viewed Video',
        description: 'Baby Shark Dance by Pinkfong.',
        channelTitle: 'Pinkfong Baby Shark - Kids Songs & Stories',
        channelId: 'UCcdwLMPsaU2ezNSJU1nFoBQ',
        publishedAt: '2016-06-17T00:00:00Z',
        viewCount: 13000000000,
        likeCount: 30000000,
        duration: 'PT2M17S',
        tags: ['Baby Shark', 'kids', 'children'],
        categoryId: '10',
      ),
      YouTubeVideo(
        id: 'fJ9rUzIMcZQ',
        title: 'Bohemian Rhapsody (Official Video Remastered)',
        description: 'Bohemian Rhapsody by Queen, remastered official video.',
        channelTitle: 'Queen Official',
        channelId: 'UCiMhD4jzUqG-IgPzUmmytRQ',
        publishedAt: '1975-10-31T00:00:00Z',
        viewCount: 1700000000,
        likeCount: 17000000,
        duration: 'PT5M55S',
        tags: ['Queen', 'Bohemian Rhapsody', 'rock'],
        categoryId: '10',
      ),
    ];
  }

  List<YouTubeVideo> _mockSearchVideos(String query) {
    final all = [
      ..._mockTrendingVideos(),
      const YouTubeVideo(
        id: 'L_jWHffIx5E',
        title: 'Smash Mouth - All Star',
        description: 'Smash Mouth - All Star official music video.',
        channelTitle: 'Smash Mouth',
        channelId: 'UCzWQYUVCpZqtN93H8RR44Qw',
        publishedAt: '2017-07-18T00:00:00Z',
        viewCount: 500000000,
        likeCount: 5000000,
        duration: 'PT3M20S',
        tags: ['All Star', 'Smash Mouth', 'alternative'],
        categoryId: '10',
      ),
      const YouTubeVideo(
        id: 'y6120QOlsfU',
        title: 'Darude - Sandstorm',
        description: 'Darude - Sandstorm official video.',
        channelTitle: 'Darude',
        channelId: 'UCTunqPPMSqM7D0IxJIEXkXA',
        publishedAt: '2010-08-23T00:00:00Z',
        viewCount: 310000000,
        likeCount: 3100000,
        duration: 'PT3M44S',
        tags: ['Sandstorm', 'Darude', 'EDM'],
        categoryId: '10',
      ),
    ];
    return all.take(10).toList();
  }
}
