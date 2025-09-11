import 'package:flutter/material.dart';
import '../../models/genre.dart';

class GenreSelection extends StatelessWidget {
  final List<Genre> allGenres;
  final List<Genre> filteredGenres;
  final List<Genre> selectedGenres;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(Genre) onGenreToggle;
  final Function(String) onSearchChanged;
  final VoidCallback onContinue;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const GenreSelection({
    super.key,
    required this.allGenres,
    required this.filteredGenres,
    required this.selectedGenres,
    required this.searchController,
    required this.searchFocusNode,
    required this.onGenreToggle,
    required this.onSearchChanged,
    required this.onContinue,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              const SizedBox(height: 16),
              _buildGenreGrid(),
              const SizedBox(height: 20),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        style: const TextStyle(color: Colors.white),
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search interests...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.6),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildGenreGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filteredGenres.map((genre) => _buildGenreChip(genre)).toList(),
    );
  }

  Widget _buildGenreChip(Genre genre) {
    final isSelected = selectedGenres.contains(genre);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onGenreToggle(genre),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF00D4FF).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF00D4FF)
                  : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                genre.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                genre.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00D4FF),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: selectedGenres.isEmpty ? null : onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedGenres.isEmpty 
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFF00D4FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          selectedGenres.isEmpty
              ? 'Select at least one genre'
              : 'Continue with ${selectedGenres.length} genre${selectedGenres.length == 1 ? '' : 's'} ✨',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}