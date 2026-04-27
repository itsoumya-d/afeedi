import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ContentTypeSelection extends StatefulWidget {
  final List<String> selectedContentTypes;
  final Function(List<String>) onContentTypesChanged;

  const ContentTypeSelection({
    Key? key,
    required this.selectedContentTypes,
    required this.onContentTypesChanged,
  }) : super(key: key);

  @override
  State<ContentTypeSelection> createState() => _ContentTypeSelectionState();
}

class _ContentTypeSelectionState extends State<ContentTypeSelection> {
  late List<String> _selectedContentTypes;

  // Content types with descriptions and icons
  final List<Map<String, dynamic>> _contentTypes = [
    {
      'type': 'Entertainment',
      'description': 'Fun and engaging content for leisure time',
      'icon': Icons.movie_outlined,
    },
    {
      'type': 'Educational Content',
      'description': 'Learn new skills and expand your knowledge',
      'icon': Icons.school_outlined,
    },
    {
      'type': 'News',
      'description': 'Stay updated with current events',
      'icon': Icons.newspaper_outlined,
    },
    {
      'type': 'Tutorials',
      'description': 'Step-by-step guides and how-to videos',
      'icon': Icons.build_outlined,
    },
    {
      'type': 'Reviews',
      'description': 'Product and service evaluations',
      'icon': Icons.rate_review_outlined,
    },
    {
      'type': 'Vlogs',
      'description': 'Personal video blogs and daily life content',
      'icon': Icons.videocam_outlined,
    },
    {
      'type': 'Music Videos',
      'description': 'Music performances and official videos',
      'icon': Icons.music_note_outlined,
    },
    {
      'type': 'Comedy Sketches',
      'description': 'Humorous and entertaining short videos',
      'icon': Icons.sentiment_very_satisfied_outlined,
    },
    {
      'type': 'Gaming Content',
      'description': 'Gameplay, reviews, and gaming culture',
      'icon': Icons.sports_esports_outlined,
    },
    {
      'type': 'Live Streams',
      'description': 'Real-time broadcasts and events',
      'icon': Icons.live_tv_outlined,
    },
    {
      'type': 'Documentaries',
      'description': 'In-depth explorations of real subjects',
      'icon': Icons.movie_filter_outlined,
    },
    {
      'type': 'Podcasts',
      'description': 'Audio discussions and interviews',
      'icon': Icons.mic_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedContentTypes = List.from(widget.selectedContentTypes);
  }

  void _toggleContentType(String type) {
    setState(() {
      if (_selectedContentTypes.contains(type)) {
        _selectedContentTypes.remove(type);
      } else {
        _selectedContentTypes.add(type);
      }
      widget.onContentTypesChanged(_selectedContentTypes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected count
        Text(
          'Selected: ${_selectedContentTypes.length} content types',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 16),

        // Content type cards
        ..._contentTypes.asMap().entries.map((entry) {
          final index = entry.key;
          final contentType = entry.value;
          return _buildContentTypeCard(
            type: contentType['type'],
            description: contentType['description'],
            icon: contentType['icon'],
            index: index,
          );
        }).toList(),

        const SizedBox(height: 16),

        // Tip box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Selecting diverse content types helps us provide you with a well-rounded feed experience.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeCard({
    required String type,
    required String description,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedContentTypes.contains(type);

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _toggleContentType(type),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryLight
                      : Colors.grey.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? AppColors.primaryLight
                          : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected
                                ? AppColors.primaryLight
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleContentType(type),
                    activeColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (50 * index).ms)
        .slideY(begin: 0.05, end: 0);
  }
}
