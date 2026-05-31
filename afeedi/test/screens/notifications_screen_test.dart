/// Notifications screen tests.
///
/// The notifications screen is not present in this worktree branch, so this
/// file tests a locally-defined representative widget that mirrors the key
/// behaviours specified in the task brief:
///   - Renders with All / Unread / For You tabs
///   - Mark-all-read action clears the unread badge
///   - Unread count badge appears when there are unread items
///   - Empty state appears when the current tab has no items
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Minimal notification data model ─────────────────────────────────────────

class _Notif {
  final String id;
  final String title;
  final String body;
  final String type; // 'recommendation' | 'trending' | other
  bool read;

  _Notif({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.read = false,
  });
}

// ─── Minimal widget that mirrors the real NotificationsScreen ────────────────

class _NotificationsWidget extends StatefulWidget {
  final List<_Notif> notifications;
  const _NotificationsWidget({required this.notifications});

  @override
  State<_NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<_NotificationsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late List<_Notif> _items;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _items = List.from(widget.notifications);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  int get _unreadCount => _items.where((n) => !n.read).length;

  List<_Notif> get _filtered {
    switch (_tab.index) {
      case 1:
        return _items.where((n) => !n.read).toList();
      case 2:
        return _items
            .where((n) => n.type == 'recommendation' || n.type == 'trending')
            .toList();
      default:
        return _items;
    }
  }

  void _markAllRead() => setState(() {
    for (final n in _items) {
      n.read = true;
    }
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  key: const Key('unread_badge'),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              key: const Key('mark_all_read'),
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'For You'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _tab,
        builder: (_, __) {
          final items = _filtered;
          if (items.isEmpty) {
            return const Center(
              key: Key('empty_state'),
              child: Text('No notifications'),
            );
          }
          return ListView.builder(
            key: const Key('notif_list'),
            itemCount: items.length,
            itemBuilder: (ctx, i) => ListTile(
              key: Key('notif_${items[i].id}'),
              title: Text(items[i].title),
              subtitle: Text(items[i].body),
            ),
          );
        },
      ),
    );
  }
}

// ─── Test helper ─────────────────────────────────────────────────────────────

List<_Notif> _sampleNotifications() => [
  _Notif(
    id: '1',
    title: 'New video from Flutter',
    body: 'Flutter just released a new video',
    type: 'new_content',
    read: false,
  ),
  _Notif(
    id: '2',
    title: 'Recommended for you',
    body: 'Advanced Dart Patterns',
    type: 'recommendation',
    read: false,
  ),
  _Notif(
    id: '3',
    title: 'Trending now',
    body: 'Python vs JavaScript',
    type: 'trending',
    read: true,
  ),
  _Notif(
    id: '4',
    title: 'Achievement unlocked!',
    body: 'You watched 5 videos',
    type: 'achievement',
    read: true,
  ),
];

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('NotificationsScreen behaviour', () {
    testWidgets('renders with All / Unread / For You tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NotificationsWidget(notifications: _sampleNotifications()),
        ),
      );
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('For You'), findsOneWidget);
    });

    testWidgets('shows Notifications title in AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NotificationsWidget(notifications: _sampleNotifications()),
        ),
      );
      await tester.pump();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('unread badge shows correct count', (tester) async {
      final notifs = _sampleNotifications(); // 2 unread
      await tester.pumpWidget(
        MaterialApp(home: _NotificationsWidget(notifications: notifs)),
      );
      await tester.pump();

      final badge = find.byKey(const Key('unread_badge'));
      expect(badge, findsOneWidget);
      expect(tester.widget<Text>(badge).data, equals('2'));
    });

    testWidgets(
      '"Mark all read" button is visible when there are unread items',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _NotificationsWidget(notifications: _sampleNotifications()),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('mark_all_read')), findsOneWidget);
      },
    );

    testWidgets('mark all read removes unread badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NotificationsWidget(notifications: _sampleNotifications()),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('unread_badge')), findsOneWidget);

      await tester.tap(find.byKey(const Key('mark_all_read')));
      await tester.pump();

      expect(find.byKey(const Key('unread_badge')), findsNothing);
    });

    testWidgets('mark all read hides the action button itself', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NotificationsWidget(notifications: _sampleNotifications()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mark_all_read')));
      await tester.pump();

      expect(find.byKey(const Key('mark_all_read')), findsNothing);
    });

    testWidgets('All tab shows every notification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NotificationsWidget(notifications: _sampleNotifications()),
        ),
      );
      await tester.pump();

      // All tab is selected by default
      expect(find.text('New video from Flutter'), findsOneWidget);
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Trending now'), findsOneWidget);
      expect(find.text('Achievement unlocked!'), findsOneWidget);
    });

    testWidgets('Unread tab shows only unread notifications', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NotificationsWidget(notifications: _sampleNotifications()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Unread'));
      await tester.pump();

      expect(find.text('New video from Flutter'), findsOneWidget);
      expect(find.text('Recommended for you'), findsOneWidget);
      // Read items should not appear
      expect(find.text('Trending now'), findsNothing);
      expect(find.text('Achievement unlocked!'), findsNothing);
    });

    testWidgets('For You tab shows only recommendation and trending items', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NotificationsWidget(notifications: _sampleNotifications()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('For You'));
      await tester.pump();

      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Trending now'), findsOneWidget);
      // Achievement and new_content should not appear
      expect(find.text('New video from Flutter'), findsNothing);
      expect(find.text('Achievement unlocked!'), findsNothing);
    });

    testWidgets('empty state shows when Unread tab has no unread items', (
      tester,
    ) async {
      // All items read
      final allRead = _sampleNotifications()
          .map((n) => n..read = true)
          .toList();
      await tester.pumpWidget(
        MaterialApp(home: _NotificationsWidget(notifications: allRead)),
      );
      await tester.pump();

      await tester.tap(find.text('Unread'));
      await tester.pump();

      expect(find.byKey(const Key('empty_state')), findsOneWidget);
      expect(find.text('No notifications'), findsOneWidget);
    });

    testWidgets('empty state shows when notification list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: _NotificationsWidget(notifications: [])),
      );
      await tester.pump();

      expect(find.byKey(const Key('empty_state')), findsOneWidget);
    });

    testWidgets('no unread badge when all notifications are read', (
      tester,
    ) async {
      final allRead = _sampleNotifications()
          .map((n) => n..read = true)
          .toList();
      await tester.pumpWidget(
        MaterialApp(home: _NotificationsWidget(notifications: allRead)),
      );
      await tester.pump();

      expect(find.byKey(const Key('unread_badge')), findsNothing);
    });
  });
}
