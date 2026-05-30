import 'package:flutter/material.dart';

class QualitySelectorWidget extends StatelessWidget {
  final String currentQuality;
  final List<String> availableQualities;
  final Function(String) onQualitySelected;
  final bool showBitrate;

  const QualitySelectorWidget({
    super.key,
    required this.currentQuality,
    required this.availableQualities,
    required this.onQualitySelected,
    this.showBitrate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.high_quality, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Quality',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Quality options
          ...availableQualities.map((quality) => _buildQualityOption(quality)),

          // Auto quality option
          _buildQualityOption('Auto', isAuto: true),
        ],
      ),
    );
  }

  Widget _buildQualityOption(String quality, {bool isAuto = false}) {
    final isSelected = currentQuality == quality;
    final qualityData = _getQualityData(quality);

    return GestureDetector(
      onTap: () => onQualitySelected(quality),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quality indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Quality text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quality,
                  style: TextStyle(
                    color: isSelected ? Colors.red : Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (showBitrate && qualityData['bitrate'] != null)
                  Text(
                    qualityData['bitrate'],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Quality badge
            if (!isAuto)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: qualityData['color'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  qualityData['label'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (isAuto)
              const Icon(Icons.auto_awesome, color: Colors.orange, size: 16),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getQualityData(String quality) {
    switch (quality.toLowerCase()) {
      case '2160p':
      case '4k':
        return {'label': '4K', 'bitrate': '~25 Mbps', 'color': Colors.purple};
      case '1440p':
      case '2k':
        return {'label': '2K', 'bitrate': '~16 Mbps', 'color': Colors.blue};
      case '1080p':
      case 'fhd':
        return {'label': 'FHD', 'bitrate': '~8 Mbps', 'color': Colors.green};
      case '720p':
      case 'hd':
        return {'label': 'HD', 'bitrate': '~5 Mbps', 'color': Colors.orange};
      case '480p':
        return {'label': 'SD', 'bitrate': '~2.5 Mbps', 'color': Colors.yellow};
      case '360p':
        return {'label': 'LQ', 'bitrate': '~1 Mbps', 'color': Colors.red};
      case '240p':
        return {'label': 'VLQ', 'bitrate': '~0.5 Mbps', 'color': Colors.grey};
      default:
        return {'label': 'AUTO', 'bitrate': null, 'color': Colors.grey};
    }
  }
}

// Compact quality selector for mobile
class CompactQualitySelector extends StatelessWidget {
  final String currentQuality;
  final List<String> availableQualities;
  final Function(String) onQualitySelected;

  const CompactQualitySelector({
    super.key,
    required this.currentQuality,
    required this.availableQualities,
    required this.onQualitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: availableQualities.length + 1, // +1 for Auto
        itemBuilder: (context, index) {
          final quality = index < availableQualities.length
              ? availableQualities[index]
              : 'Auto';

          final isSelected = currentQuality == quality;

          return GestureDetector(
            onTap: () => onQualitySelected(quality),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.red
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  quality,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Quality indicator widget
class QualityIndicatorWidget extends StatelessWidget {
  final String quality;
  final bool isBuffering;
  final double? bufferProgress;

  const QualityIndicatorWidget({
    super.key,
    required this.quality,
    this.isBuffering = false,
    this.bufferProgress,
  });

  @override
  Widget build(BuildContext context) {
    final qualityData = _getQualityData(quality);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quality badge
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: qualityData['color'],
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          // Quality text
          Text(
            quality,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Buffering indicator
          if (isBuffering) ...<Widget>[
            const SizedBox(width: 6),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                value: bufferProgress,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getQualityData(String quality) {
    switch (quality.toLowerCase()) {
      case '2160p':
      case '4k':
        return {'color': Colors.purple};
      case '1440p':
      case '2k':
        return {'color': Colors.blue};
      case '1080p':
      case 'fhd':
        return {'color': Colors.green};
      case '720p':
      case 'hd':
        return {'color': Colors.orange};
      case '480p':
        return {'color': Colors.yellow};
      case '360p':
        return {'color': Colors.red};
      default:
        return {'color': Colors.grey};
    }
  }
}
