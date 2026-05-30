import 'package:flutter/material.dart';

class _Language {
  final String name;
  final String flag;
  final String locale;

  const _Language({
    required this.name,
    required this.flag,
    required this.locale,
  });
}

const _languages = [
  _Language(name: 'English', flag: '🇺🇸', locale: 'en'),
  _Language(name: 'Hindi', flag: '🇮🇳', locale: 'hi'),
  _Language(name: 'Spanish', flag: '🇪🇸', locale: 'es'),
  _Language(name: 'Portuguese', flag: '🇧🇷', locale: 'pt'),
  _Language(name: 'French', flag: '🇫🇷', locale: 'fr'),
  _Language(name: 'German', flag: '🇩🇪', locale: 'de'),
  _Language(name: 'Arabic', flag: '🇸🇦', locale: 'ar'),
  _Language(name: 'Indonesian', flag: '🇮🇩', locale: 'id'),
  _Language(name: 'Japanese', flag: '🇯🇵', locale: 'ja'),
  _Language(name: 'Korean', flag: '🇰🇷', locale: 'ko'),
  _Language(name: 'Chinese', flag: '🇨🇳', locale: 'zh'),
  _Language(name: 'Russian', flag: '🇷🇺', locale: 'ru'),
];

class LanguageSelectionWidget extends StatefulWidget {
  final Function(String name, String locale) onLanguageSelected;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const LanguageSelectionWidget({
    super.key,
    required this.onLanguageSelected,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  State<LanguageSelectionWidget> createState() =>
      _LanguageSelectionWidgetState();
}

class _LanguageSelectionWidgetState extends State<LanguageSelectionWidget> {
  String? _selectedLocale;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.slideAnimation,
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select the language you prefer for content',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                ),
                itemCount: _languages.length,
                itemBuilder: (context, i) {
                  final lang = _languages[i];
                  final isSelected = _selectedLocale == lang.locale;
                  return _LanguageCard(
                    language: lang,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedLocale = lang.locale;
                      });
                      widget.onLanguageSelected(lang.name, lang.locale);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final _Language language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${language.name}${isSelected ? ', selected' : ''}',
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00D4FF)
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  language.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    language.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
