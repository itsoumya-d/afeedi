import 'package:flutter/material.dart';
import '../../services/locale_service.dart';

class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LanguageSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final current = LocaleService.instance.locale.languageCode;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: LocaleService.supportedLanguages.length,
                itemBuilder: (context, i) {
                  final lang = LocaleService.supportedLanguages[i];
                  final isSelected = lang['code'] == current;
                  return ListTile(
                    leading: Text(
                      lang['flag'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      lang['nativeName'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF00D4FF)
                            : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      lang['name'] as String,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF00D4FF),
                          )
                        : null,
                    onTap: () {
                      LocaleService.instance.setLocale(lang['code'] as String);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        );
      },
    );
  }
}
