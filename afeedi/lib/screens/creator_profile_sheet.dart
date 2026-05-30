import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  // Platform → content items for this creator (cross-platform aggregation)
  Map<PlatformType, List<Content>> _byPlatform = {};
  bool _loading = true;
  bool _loadError = false;

  static const _platformColors = {
    PlatformType.youtube: Color(0xFFFF0000),
    PlatformType.tiktok: Color(0xFF69C9D0),
    PlatformType.instagram: Color(0xFFE1306C),
    PlatformType.facebook: Color(0xFF1877F2),
  };
  static const _platformNames = {
    PlatformType.youtube: 'YouTube',
    PlatformType.tiktok: 'TikTok',
    PlatformType.instagram: 'Instagram',
    PlatformType.facebook: 'Facebook',
  };

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.creatorId != null
        ? UserInteractionService.instance.isFollowed(widget.creatorId!)
        : false;
    _loadCreatorContent();
  }

  Future<void> _loadCreatorContent() async {
    try {
      // Load a larger pool to find cross-platform content
      final all = await ContentService.instance.getFeedContent(limit: 200);
      final creatorItems = all
          .where(
            (c) =>
                c.creatorName?.toLowerCase() ==
                widget.creatorName.toLowerCase(),
          )
          .toList();

      // Group by platform
      final Map<PlatformType, List<Content>> grouped = {};
      for (final c in creatorItems) {
        grouped.putIfAbsent(c.platform, () => []).add(c);
      }

      // Recent content: up to 2 per platform, sorted by platform priority
      final recent = <Content>[];
      for (final platform in [
        PlatformType.youtube,
        PlatformType.tiktok,
        PlatformType.instagram,
        PlatformType.facebook,
      ]) {
        recent.addAll((grouped[platform] ?? []).take(2));
        if (recent.length >= 6) break;
      }

      if (mounted) {
        setState(() {
          _byPlatform = grouped;
          _recentContent = recent;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadError = true;
        });
    }
  }

  /// Deterministic mock follower count for a specific platform.
  int _platformFollowers(PlatformType platform) {
    final seed = ('${widget.creatorId ?? widget.creatorName}_${platform.name}')
        .hashCode
        .abs();
    switch (platform) {
      case PlatformType.youtube:
        return 10000 + (seed % 4990000); // 10K – 5M
      case PlatformType.tiktok:
        return 5000 + (seed % 2995000); // 5K – 3M
      case PlatformType.instagram:
        return 8000 + (seed % 1992000); // 8K – 2M
      case PlatformType.facebook:
        return 3000 + (seed % 997000); // 3K – 1M
    }
  }

  int _totalFollowers() =>
      _activeplatforms.fold(0, (sum, p) => sum + _platformFollowers(p));

  List<PlatformType> get _activeplatforms => _byPlatform.isNotEmpty
      ? _byPlatform.keys.toList()
      : (widget.platform != null ? [widget.platform!] : [PlatformType.youtube]);

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
    final totalFollowers = _totalFollowers();
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
            Semantics(
              label: 'Drag to resize panel',
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                children: [
                  // Avatar + name
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: platformColor.withValues(alpha: 0.2),
                          backgroundImage:
                              widget.content.creatorAvatarUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.content.creatorAvatarUrl!,
                                )
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: platformColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: platformColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ExcludeSemantics(
                                child: Icon(
                                  _platformIcon(widget.platform),
                                  color: platformColor,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.platform?.name.toUpperCase() ??
                                    'UNKNOWN',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: platformColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Total reach headline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(
                        label: 'Total Reach',
                        value: _formatCount(totalFollowers),
                      ),
                      _StatDivider(),
                      _Stat(label: 'Videos', value: _formatCount(videos)),
                      _StatDivider(),
                      _Stat(
                        label: 'Platforms',
                        value: '${_activeplatforms.length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Per-platform breakdown
                  _buildPlatformBreakdown(),
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
                        backgroundColor: _isFollowed
                            ? Colors.white.withValues(alpha: 0.1)
                            : platformColor,
                        foregroundColor: _isFollowed
                            ? platformColor
                            : Colors.white,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Recent content section
                  Text(
                    _activeplatforms.length > 1
                        ? 'Recent Content (${_activeplatforms.length} platforms)'
                        : 'Recent Content',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00BCD4),
                      ),
                    )
                  else if (_loadError)
                    Semantics(
                      label: 'Could not load content. Double-tap to retry.',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _loadError = false;
                            _loading = true;
                          });
                          _loadCreatorContent();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Could not load content. Tap to retry.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_recentContent.isEmpty)
                    Text(
                      'No recent content found.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    )
                  else
                    ..._recentContent.map((c) => _ContentRow(content: c)),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformBreakdown() {
    final platforms = _activeplatforms;
    if (platforms.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, color: Color(0xFF00D4FF), size: 14),
              const SizedBox(width: 6),
              Text(
                'Cross-Platform Reach',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...platforms.map((platform) {
            final count = _platformFollowers(platform);
            final total = _totalFollowers();
            final fraction = total > 0 ? count / total : 0.0;
            final color = _platformColors[platform] ?? const Color(0xFF00D4FF);
            final name = _platformNames[platform] ?? platform.name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      name,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          color.withValues(alpha: 0.7),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatCount(count),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
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
                ? CachedNetworkImage(
                    imageUrl: content.thumbnailUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(),
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
                fontWeight: FontWeight.w500,
              ),
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
      child: Icon(
        Icons.video_library,
        color: Colors.white.withValues(alpha: 0.4),
        size: 24,
      ),
    );
  }
}
