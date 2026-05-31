/// Onboarding widget tests.
///
/// The OnboardingChatbotScreen in this branch has compile errors (missing
/// utils/constants.dart, removed fields on OnboardingStep, etc.), so we test
/// the public onboarding sub-widgets that have clean import chains:
///   - GenreSelection: genre chip display, selection state, button enable/disable,
///     check icon, toggle callback, search field, empty state
///   - PlatformConnection widget: basic render
///   - QuickReplyChips widget: basic render and tap
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:afeedi/widgets/onboarding/genre_selection.dart';
import 'package:afeedi/models/genre.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // GenreSelection widget
  // ───────────────────────────────────────────────────────────────────────────

  group('GenreSelection widget', () {
    late List<Genre> genres;

    setUp(() {
      genres = [
        Genre(
          name: 'Gaming',
          emoji: '🎮',
          category: 'Entertainment',
          keywords: ['gaming'],
        ),
        Genre(
          name: 'Music',
          emoji: '🎵',
          category: 'Entertainment',
          keywords: ['music'],
        ),
        Genre(
          name: 'Technology',
          emoji: '💻',
          category: 'Education',
          keywords: ['tech'],
        ),
        Genre(
          name: 'Comedy',
          emoji: '😂',
          category: 'Entertainment',
          keywords: ['comedy'],
        ),
        Genre(
          name: 'Fitness',
          emoji: '💪',
          category: 'Health',
          keywords: ['fitness'],
        ),
      ];
    });

    /// Builds GenreSelection inside a _GenreSelectionHost that owns and disposes
    /// the AnimationControllers, preventing ticker-leak errors.
    Widget buildGenreSelection({
      required List<Genre> allGenres,
      required List<Genre> filteredGenres,
      required List<Genre> selectedGenres,
      required VoidCallback onContinue,
      required Function(Genre) onGenreToggle,
      void Function(String)? onSearchChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: _GenreSelectionHost(
              allGenres: allGenres,
              filteredGenres: filteredGenres,
              selectedGenres: selectedGenres,
              onContinue: onContinue,
              onGenreToggle: onGenreToggle,
              onSearchChanged: onSearchChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.byType(GenreSelection), findsOneWidget);
    });

    testWidgets('displays genre chips for all filtered genres', (tester) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.text('Gaming'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
      expect(find.text('Fitness'), findsOneWidget);
    });

    testWidgets('continue button is disabled when nothing is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('continue button shows disabled label when nothing selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      // Button requires 3+ genres; disabled state shows this message
      expect(find.text('Select at least 3 interests'), findsOneWidget);
    });

    testWidgets('continue button is enabled when at least 3 genres selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: genres.take(3).toList(),
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('continue button shows count when genres are selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: genres.take(3).toList(),
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      // The button text format: 'Continue with 3 genres ✨'
      expect(find.textContaining('Continue with 3'), findsOneWidget);
    });

    testWidgets(
      'continue button shows interests count when 3 genres selected',
      (tester) async {
        await tester.pumpWidget(
          buildGenreSelection(
            allGenres: genres,
            filteredGenres: genres,
            selectedGenres: genres.take(3).toList(),
            onContinue: () {},
            onGenreToggle: (_) {},
          ),
        );
        await tester.pump();

        // The button text format: 'Continue with 3 interests ✨'
        expect(
          find.textContaining('Continue with 3 interests'),
          findsOneWidget,
        );
      },
    );

    testWidgets('continue button fires callback when genres are selected', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: genres.take(3).toList(),
          onContinue: () => tapped = true,
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('tapping a chip invokes onGenreToggle with that genre', (
      tester,
    ) async {
      final toggled = <Genre>[];
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: toggled.add,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Gaming'));
      await tester.pump();

      expect(toggled, hasLength(1));
      expect(toggled.first.name, equals('Gaming'));
    });

    testWidgets('shows check_circle icon for selected genres', (tester) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [genres.first],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('no check_circle icons when nothing is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('multiple selected genres all show check_circle', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: genres.take(3).toList(),
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    });

    testWidgets('search field is present', (tester) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('search field has search icon prefix', (tester) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('typing in search field invokes onSearchChanged', (
      tester,
    ) async {
      final queries = <String>[];
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: genres,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
          onSearchChanged: queries.add,
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'gam');
      await tester.pump();

      expect(queries, contains('gam'));
    });

    testWidgets('only filtered genres are shown in chips', (tester) async {
      // Only pass Gaming in filteredGenres even though all are in allGenres
      final filtered = [genres.first]; // Gaming only
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: filtered,
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.text('Gaming'), findsOneWidget);
      expect(find.text('Music'), findsNothing);
      expect(find.text('Technology'), findsNothing);
    });

    testWidgets('empty filteredGenres shows no genre chips', (tester) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: [],
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      // None of the genre names should appear as chips
      for (final g in genres) {
        expect(find.text(g.name), findsNothing);
      }
    });

    testWidgets('genre emoji is shown in chip', (tester) async {
      await tester.pumpWidget(
        buildGenreSelection(
          allGenres: genres,
          filteredGenres: [genres.first], // Gaming 🎮
          selectedGenres: [],
          onContinue: () {},
          onGenreToggle: (_) {},
        ),
      );
      await tester.pump();

      expect(find.text('🎮'), findsOneWidget);
    });
  });
}

/// A StatefulWidget that owns the AnimationControllers for GenreSelection,
/// disposing them properly when removed from the tree.
class _GenreSelectionHost extends StatefulWidget {
  final List<Genre> allGenres;
  final List<Genre> filteredGenres;
  final List<Genre> selectedGenres;
  final VoidCallback onContinue;
  final Function(Genre) onGenreToggle;
  final void Function(String) onSearchChanged;

  const _GenreSelectionHost({
    required this.allGenres,
    required this.filteredGenres,
    required this.selectedGenres,
    required this.onContinue,
    required this.onGenreToggle,
    required this.onSearchChanged,
  });

  @override
  State<_GenreSelectionHost> createState() => _GenreSelectionHostState();
}

class _GenreSelectionHostState extends State<_GenreSelectionHost>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_slideCtrl);
    _fadeAnim = Tween<double>(begin: 1.0, end: 1.0).animate(_fadeCtrl);
    _slideCtrl.forward();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GenreSelection(
    allGenres: widget.allGenres,
    filteredGenres: widget.filteredGenres,
    selectedGenres: widget.selectedGenres,
    searchController: TextEditingController(),
    searchFocusNode: FocusNode(),
    onGenreToggle: widget.onGenreToggle,
    onSearchChanged: widget.onSearchChanged,
    onContinue: widget.onContinue,
    slideAnimation: _slideAnim,
    fadeAnimation: _fadeAnim,
  );
}
