import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
import '../services/user_interaction_service.dart';

class CreatorProfileSheet extends StatefulWidget {
  final String creatorName;
  final String? creatorId;
  final PlatformType? platform;
  final Content content;

  const CreatorProfileSheet({
    super.key,
    required this.creatorName,
    this.creatorId,
    this.platform,
    required this.content,
  });

  /// Show the sheet from any context.
  static Future<void> show(BuildContext context, Content content) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatorProfileSheet(
        creatorName: content.creatorName ?? 'Unknown Creator',
        creatorId: content.creatorId,
        platform: content.platform,
        content: content,
      ),
    );
  }

  @override
  State<CreatorProfileSheet> createState() => _CreatorProfileSheetState();
}

class _CreatorProfileSheetState extends State<CreatorProfileSheet> {
  late bool _isFollowed;
  List<Content> _recentContent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.creatorId != null
        ? UserInteractionService.instance.isFollowed(widget.creatorId!)
        : false;
    _loadRecentContent();
  }

  Future<void> _loadRecentContent() async {
    try {
      final all = await ContentService.instance.getFeedContent(limit: 50);
      final filtered = all
          .where((c) =>
              c.creatorName?.toLowerCase() ==
              widget.creatorName.toLowerCase())
          .take(3)
          .toList();
      if (mounted) {
        setState(() {
          _recentContent = filtered;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Deterministic mock follower count from creatorId hash.
  int _mockFollowers() {
    final seed = (widget.creatorId ?? widget.creatorName).hashCode.abs();
    // Range 1 000 – 9 999 999
    return 1000 + (seed % 9998999);
  }

  /// Deterministic mock video count from creatorId hash.
  int _mockVideoCount() {
    final seed = (widget.creatorId ?? widget.creatorName).hashCode.abs();
    return 5 + (seed % 495);
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Color _platformColor(PlatformType? p) {
    switch (p) {
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.instagram:
        return const Color(0xFFE4405F);
      case PlatformType.tiktok:
        return const Color(0xFF69C9D0);
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
      default:
        return const Color(0xFF00BCD4);
    }
  }

  IconData _platformIcon(PlatformType? p) {
    switch (p) {
      case PlatformType.youtube:
        return Icons.play_circle_outline;
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.tiktok:
        return Icons.music_note;
      case PlatformType.facebook:
        return Icons.facebook;
      default:
        return Icons.public;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final followers = _mockFollowers();
    final videos = _mockVideoCount();
    final platformColor = _platformColor(widget.platform);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // Avatar + name
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: platformColor.withValues(alpha: 0.2),
                          backgroundImage: widget.content.creatorAvatarUrl != null
                              ? NetworkImage(widget.content.creatorAvatarUrl!)
                              : null,
                          child: widget.content.creatorAvatarUrl == null
                              ? Text(
                                  _initials(widget.creatorName),
                                  style: TextStyle(
                                    color: platformColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.creatorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Platform badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: platformColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: platformColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_platformIcon(widget.platform),
                                  color: platformColor, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                widget.platform?.name.toUpperCase() ?? 'UNKNOWN',
                                style: TextStyle(
                                    color: platformColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(
                          label: 'Followers',
                          value: _formatCount(followers)),
                      _StatDivider(),
                      _Stat(
                          label: 'Videos',
                          value: _formatCount(videos)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Follow / Following button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (widget.creatorId == null) return;
                        final next = await UserInteractionService.instance
                            .toggleFollow(widget.creatorId!);
                        setState(() => _isFollowed = next);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isFollowed ? Colors.white.withValues(alpha: 0.1) : platformColor,
                        foregroundColor:
                            _isFollowed ? platformColor : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: platformColor),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        _isFollowed ? 'Following' : 'Follow',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Recent content section
                  const Text(
                    'Recent Content',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00BCD4)))
                  else if (_recentContent.isEmpty)
                    Text(
                      'No recent content found.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13),
                    )
                  else
                    ..._recentContent.map((c) => _ContentRow(content: c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _ContentRow extends StatelessWidget {
  final Content content;
  const _ContentRow({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: content.thumbnailUrl != null
                ? Image.network(
                    content.thumbnailUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    semanticLabel: content.title ?? 'Video thumbnail',
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content.title ?? 'Untitled',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.white.withValues(alpha: 0.1),
      child: Icon(Icons.video_library,
          color: Colors.white.withValues(alpha: 0.4), size: 24),
    );
  }
}
