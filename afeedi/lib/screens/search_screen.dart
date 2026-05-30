import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/youtube_data_api_service.dart';
import '../core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<YouTubeVideo> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    final results = await YouTubeDataApiService.instance
        .fetchVideosByQuery(query: query.trim(), maxResults: 20);
    if (mounted) setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: AppTheme.primaryCyan,
          decoration: InputDecoration(
            hintText: 'Search videos, topics, creators...',
            hintStyle: const TextStyle(color: Colors.white38),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _search,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.primaryCyan),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryCyan),
      );
    }
    if (!_hasSearched) {
      return _buildSuggestions();
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(
              'No results for "${_controller.text}"',
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) => _VideoResultCard(
          video: _results[index]),
    );
  }

  Widget _buildSuggestions() {
    const suggestions = [
      'Trending music 2024',
      'Flutter tutorial',
      'Cooking recipes',
      'Travel vlogs',
      'Gaming highlights',
      'Science explained',
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('POPULAR SEARCHES',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...suggestions.map((s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.trending_up_rounded,
                  color: Colors.white38, size: 18),
              title: Text(s,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              onTap: () {
                _controller.text = s;
                _search(s);
              },
            )),
      ],
    );
  }
}

class _VideoResultCard extends StatelessWidget {
  final YouTubeVideo video;

  const _VideoResultCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(video.watchUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: Image.network(
                video.thumbnailUrl,
                width: 120,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 80,
                  color: Colors.white12,
                  child: const Icon(Icons.play_circle_outline,
                      color: Colors.white38),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelTitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
