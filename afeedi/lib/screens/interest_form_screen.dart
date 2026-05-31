import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/navigation_service.dart';

class InterestFormScreen extends StatefulWidget {
  const InterestFormScreen({super.key});

  @override
  State<InterestFormScreen> createState() => _InterestFormScreenState();
}

class _InterestFormScreenState extends State<InterestFormScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  Set<String> _selectedInterests = {};
  String? _selectedLanguage;
  bool _isFormValid = false;

  final List<Map<String, dynamic>> _interestCategories = [
    {
      'id': 'technology',
      'name': 'Technology',
      'icon': Icons.computer,
      'color': Color(0xFF2196F3),
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': Color(0xFFE91E63),
    },
    {
      'id': 'sports',
      'name': 'Sports',
      'icon': Icons.sports_soccer,
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'music',
      'name': 'Music',
      'icon': Icons.music_note,
      'color': Color(0xFF9C27B0),
    },
    {
      'id': 'food',
      'name': 'Food & Cooking',
      'icon': Icons.restaurant,
      'color': Color(0xFFFF9800),
    },
    {
      'id': 'travel',
      'name': 'Travel',
      'icon': Icons.flight,
      'color': Color(0xFF00BCD4),
    },
    {
      'id': 'fitness',
      'name': 'Fitness & Health',
      'icon': Icons.fitness_center,
      'color': Color(0xFF8BC34A),
    },
    {
      'id': 'education',
      'name': 'Education',
      'icon': Icons.school,
      'color': Color(0xFF3F51B5),
    },
    {
      'id': 'art',
      'name': 'Art & Design',
      'icon': Icons.palette,
      'color': Color(0xFFE91E63),
    },
    {
      'id': 'gaming',
      'name': 'Gaming',
      'icon': Icons.games,
      'color': Color(0xFF673AB7),
    },
    {
      'id': 'news',
      'name': 'News & Politics',
      'icon': Icons.newspaper,
      'color': Color(0xFF607D8B),
    },
    {
      'id': 'lifestyle',
      'name': 'Lifestyle',
      'icon': Icons.favorite,
      'color': Color(0xFFFF5722),
    },
  ];

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Hindi',
    'Russian',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _nameController.addListener(_validateForm);
    _ageController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _formKey.currentState?.validate() == true &&
          _selectedInterests.isNotEmpty &&
          _selectedLanguage != null;
    });
  }

  void _toggleInterest(String interestId) {
    setState(() {
      if (_selectedInterests.contains(interestId)) {
        _selectedInterests.remove(interestId);
      } else {
        _selectedInterests.add(interestId);
      }
    });
    _validateForm();
  }

  void _continue() {
    if (_isFormValid) {
      // Save user preferences
      NavigationService.pushNamed(AppRoutes.onboardingChatbot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0B1E), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPersonalInfoSection(),
                          const SizedBox(height: 32),
                          _buildInterestsSection(),
                          const SizedBox(height: 32),
                          _buildLanguageSection(),
                          const SizedBox(height: 40),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Step 2 of 4',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress indicator
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5, // 50% progress
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryCyan, AppTheme.primaryPink],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tell us about yourself',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Help us personalize your content experience',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ageController,
          label: 'Age',
          hint: 'Enter your age',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your age';
            }
            final age = int.tryParse(value);
            if (age == null || age < 13 || age > 120) {
              return 'Please enter a valid age (13-120)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryCyan,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What interests you?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least 3 categories to get personalized content',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _interestCategories.map((category) {
            final isSelected = _selectedInterests.contains(category['id']);
            return GestureDetector(
              onTap: () => _toggleInterest(category['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category['color'].withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? category['color']
                        : Colors.white.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'],
                      color: isSelected ? category['color'] : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? category['color'] : Colors.white,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedInterests.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${_selectedInterests.length} interests selected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Language',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred language for content',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              hint: Text(
                'Select a language',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF2D1B69),
              style: const TextStyle(color: Colors.white),
              items: _languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
                _validateForm();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isFormValid ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid
                    ? AppTheme.primaryCyan
                    : Colors.grey.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                elevation: _isFormValid ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Skip for now
              NavigationService.pushNamed(AppRoutes.onboardingChatbot);
            },
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
