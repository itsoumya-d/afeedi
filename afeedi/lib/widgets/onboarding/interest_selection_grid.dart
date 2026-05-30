import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class InterestSelectionGrid extends StatefulWidget {
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsChanged;

  const InterestSelectionGrid({
    Key? key,
    required this.selectedInterests,
    required this.onInterestsChanged,
  }) : super(key: key);

  @override
  State<InterestSelectionGrid> createState() => _InterestSelectionGridState();
}

class _InterestSelectionGridState extends State<InterestSelectionGrid> {
  // Predefined list of interests with their icons
  final List<Map<String, dynamic>> _availableInterests = [
    {'name': 'Technology', 'icon': Icons.computer},
    {'name': 'Science', 'icon': Icons.science},
    {'name': 'Music', 'icon': Icons.music_note},
    {'name': 'Movies', 'icon': Icons.movie},
    {'name': 'Gaming', 'icon': Icons.sports_esports},
    {'name': 'Sports', 'icon': Icons.sports_basketball},
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Travel', 'icon': Icons.flight},
    {'name': 'Fashion', 'icon': Icons.shopping_bag},
    {'name': 'Art', 'icon': Icons.palette},
    {'name': 'Photography', 'icon': Icons.camera_alt},
    {'name': 'Books', 'icon': Icons.book},
    {'name': 'Fitness', 'icon': Icons.fitness_center},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Business', 'icon': Icons.business},
    {'name': 'Finance', 'icon': Icons.attach_money},
    {'name': 'Health', 'icon': Icons.health_and_safety},
    {'name': 'Beauty', 'icon': Icons.face},
    {'name': 'DIY', 'icon': Icons.build},
    {'name': 'Pets', 'icon': Icons.pets},
    {'name': 'Nature', 'icon': Icons.nature},
    {'name': 'Comedy', 'icon': Icons.sentiment_very_satisfied},
    {'name': 'News', 'icon': Icons.newspaper},
    {'name': 'Politics', 'icon': Icons.gavel},
  ];

  late List<String> _selectedInterests;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedInterests = List.from(widget.selectedInterests);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
      widget.onInterestsChanged(_selectedInterests);
    });
  }

  List<Map<String, dynamic>> get _filteredInterests {
    if (_searchQuery.isEmpty) {
      return _availableInterests;
    }
    return _availableInterests
        .where(
          (interest) => interest['name'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search interests',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),

        const SizedBox(height: 16),

        // Selected interests count
        Text(
          'Selected: ${_selectedInterests.length} interests',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 16),

        // Interests grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _filteredInterests.length,
          itemBuilder: (context, index) {
            final interest = _filteredInterests[index];
            final isSelected = _selectedInterests.contains(interest['name']);

            return _buildInterestItem(
              interest['name'],
              interest['icon'],
              isSelected,
              index,
            );
          },
        ),

        const SizedBox(height: 16),

        // Custom interest input
        _buildCustomInterestInput(),
      ],
    );
  }

  Widget _buildInterestItem(
    String name,
    IconData icon,
    bool isSelected,
    int index,
  ) {
    return InkWell(
          onTap: () => _toggleInterest(name),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryLight.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primaryLight : Colors.grey[600],
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primaryLight
                        : Colors.grey[800],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (50 * index).ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildCustomInterestInput() {
    final customInterestController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Don\'t see your interest?',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customInterestController,
                  decoration: InputDecoration(
                    hintText: 'Add custom interest',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final customInterest = customInterestController.text.trim();
                  if (customInterest.isNotEmpty) {
                    _toggleInterest(customInterest);
                    customInterestController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}
