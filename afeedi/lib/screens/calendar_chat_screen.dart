import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';
import '../services/analytics_service.dart';
import '../services/content_service.dart';
import '../services/notification_service.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

enum _IntentType { schedule, query, cancel, suggest, unknown }

class _ParsedIntent {
  final _IntentType type;
  final DateTime? date;
  final TimeOfDay? time;
  final String? category;
  final String? rawText;

  const _ParsedIntent({
    required this.type,
    this.date,
    this.time,
    this.category,
    this.rawText,
  });
}

class ScheduledItem {
  final String id;
  final String contentId;
  final String title;
  final String platform;
  final String? thumbnailUrl;
  final DateTime scheduledAt;
  final String? category;

  ScheduledItem({
    required this.id,
    required this.contentId,
    required this.title,
    required this.platform,
    this.thumbnailUrl,
    required this.scheduledAt,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contentId': contentId,
    'title': title,
    'platform': platform,
    'thumbnailUrl': thumbnailUrl,
    'scheduledAt': scheduledAt.toIso8601String(),
    'category': category,
  };

  factory ScheduledItem.fromJson(Map<String, dynamic> j) => ScheduledItem(
    id: j['id'] as String,
    contentId: j['contentId'] as String,
    title: j['title'] as String,
    platform: j['platform'] as String,
    thumbnailUrl: j['thumbnailUrl'] as String?,
    scheduledAt: DateTime.parse(j['scheduledAt'] as String),
    category: j['category'] as String?,
  );
}

class _ChatMessage {
  final String text;
  final bool isBot;
  final DateTime ts;
  final List<String> chips;
  final List<ScheduledItem>? cards;

  const _ChatMessage({
    required this.text,
    required this.isBot,
    required this.ts,
    this.chips = const [],
    this.cards,
  });
}

// ─── Intent parser (rule-based, no external API needed) ──────────────────────

class _IntentParser {
  static final _scheduleVerbs = RegExp(
    r'\b(schedule|add|set|book|plan|put|remind|watch|save)\b',
    caseSensitive: false,
  );
  static final _queryVerbs = RegExp(
    r'\b(what|show|list|get|find|search|tell|when|do i have|whats)\b',
    caseSensitive: false,
  );
  static final _cancelVerbs = RegExp(
    r'\b(cancel|delete|remove|clear|unschedule)\b',
    caseSensitive: false,
  );

  static final _dayNames = {
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 7,
    'mon': 1,
    'tue': 2,
    'wed': 3,
    'thu': 4,
    'fri': 5,
    'sat': 6,
    'sun': 7,
  };

  static final _timeWords = {
    'morning': const TimeOfDay(hour: 9, minute: 0),
    'noon': const TimeOfDay(hour: 12, minute: 0),
    'afternoon': const TimeOfDay(hour: 14, minute: 0),
    'evening': const TimeOfDay(hour: 19, minute: 0),
    'night': const TimeOfDay(hour: 21, minute: 0),
    'midnight': const TimeOfDay(hour: 0, minute: 0),
  };

  static final _categories = [
    'gaming',
    'tech',
    'music',
    'fitness',
    'food',
    'travel',
    'comedy',
    'fashion',
    'education',
    'sports',
    'art',
    'news',
    'finance',
    'science',
  ];

  _ParsedIntent parse(String text) {
    final lower = text.toLowerCase();

    final type = _scheduleVerbs.hasMatch(lower)
        ? _IntentType.schedule
        : _cancelVerbs.hasMatch(lower)
        ? _IntentType.cancel
        : _queryVerbs.hasMatch(lower)
        ? _IntentType.query
        : _IntentType.suggest;

    final date = _extractDate(lower);
    final time = _extractTime(lower);
    final category = _extractCategory(lower);

    return _ParsedIntent(
      type: type,
      date: date,
      time: time,
      category: category,
      rawText: text,
    );
  }

  DateTime? _extractDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (text.contains('today')) return today;
    if (text.contains('tomorrow')) return today.add(const Duration(days: 1));
    if (text.contains('yesterday')) {
      return today.subtract(const Duration(days: 1));
    }
    if (text.contains('next week')) return today.add(const Duration(days: 7));
    if (text.contains('this weekend') || text.contains('weekend')) {
      final daysToSat = (6 - now.weekday) % 7;
      return today.add(Duration(days: daysToSat == 0 ? 7 : daysToSat));
    }

    // "in N days"
    final inDays = RegExp(r'in (\d+) days?').firstMatch(text);
    if (inDays != null) {
      return today.add(Duration(days: int.parse(inDays.group(1)!)));
    }

    // Day names: "on friday", "this friday", "next monday"
    for (final entry in _dayNames.entries) {
      if (text.contains(entry.key)) {
        final targetWeekday = entry.value;
        var diff = targetWeekday - now.weekday;
        if (diff <= 0) diff += 7;
        if (text.contains('next')) diff += 7;
        return today.add(Duration(days: diff));
      }
    }

    // "December 15" / "Dec 15" / "15th"
    final monthDay = RegExp(
      r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]* ?(\d{1,2})',
    ).firstMatch(text);
    if (monthDay != null) {
      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final m = months[monthDay.group(1)]!;
      final d = int.parse(monthDay.group(2)!);
      var year = now.year;
      if (m < now.month || (m == now.month && d < now.day)) year++;
      return DateTime(year, m, d);
    }

    return null;
  }

  TimeOfDay? _extractTime(String text) {
    for (final entry in _timeWords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }

    // "8pm", "3:30 pm", "14:00"
    final t12 = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)').firstMatch(text);
    if (t12 != null) {
      var h = int.parse(t12.group(1)!);
      final m = int.tryParse(t12.group(2) ?? '0') ?? 0;
      final ap = t12.group(3)!;
      if (ap == 'pm' && h != 12) h += 12;
      if (ap == 'am' && h == 12) h = 0;
      return TimeOfDay(hour: h, minute: m);
    }
    final t24 = RegExp(r'\b(\d{2}):(\d{2})\b').firstMatch(text);
    if (t24 != null) {
      return TimeOfDay(
        hour: int.parse(t24.group(1)!),
        minute: int.parse(t24.group(2)!),
      );
    }
    return null;
  }

  String? _extractCategory(String text) {
    for (final cat in _categories) {
      if (text.contains(cat)) return cat;
    }
    return null;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CalendarChatScreen extends StatefulWidget {
  const CalendarChatScreen({super.key});

  @override
  State<CalendarChatScreen> createState() => _CalendarChatScreenState();
}

class _CalendarChatScreenState extends State<CalendarChatScreen>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFF0D0D1A);
  static const _card = Color(0xFF1A1A2E);
  static const _cyan = Color(0xFF00D4FF);
  static const _purple = Color(0xFF7C3AED);

  // Calendar state
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  Map<String, List<ScheduledItem>> _scheduled = {}; // key: yyyy-MM-dd

  // Chat state
  final List<_ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isTyping = false;

  final _parser = _IntentParser();
  List<Content> _allContent = [];
  bool _contentLoaded = false;

  late AnimationController _dotAnim;

  @override
  void initState() {
    super.initState();
    _dotAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _loadScheduled();
    _loadContent();
    _addBot(_timeAwareGreeting(), chips: _timeAwareChips());
    AnalyticsService.instance.trackUserInteraction(
      action: 'calendar_chat_opened',
      screen: 'calendar_chat',
    );
  }

  @override
  void dispose() {
    _dotAnim.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ─── Persistence ────────────────────────────────────────────────────────────

  static const _prefsKey = 'calendar_chat_scheduled_v2';

  Future<void> _loadScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ScheduledItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final map = <String, List<ScheduledItem>>{};
      for (final item in list) {
        final key = _dateKey(item.scheduledAt);
        map.putIfAbsent(key, () => []).add(item);
      }
      if (mounted) setState(() => _scheduled = map);
    } catch (_) {}
  }

  Future<void> _saveScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    final all = _scheduled.values.expand((e) => e).toList();
    await prefs.setString(
      _prefsKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ─── Content ────────────────────────────────────────────────────────────────

  Future<void> _loadContent() async {
    try {
      final content = await ContentService.instance
          .getOnboardingBasedRecommendations(limit: 50);
      if (mounted)
        setState(() {
          _allContent = content;
          _contentLoaded = true;
        });
    } catch (_) {}
  }

  // ─── Chat logic ─────────────────────────────────────────────────────────────

  void _addBot(
    String text, {
    List<String> chips = const [],
    List<ScheduledItem>? cards,
  }) {
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isBot: true,
          ts: DateTime.now(),
          chips: chips,
          cards: cards,
        ),
      );
    });
    _scrollBottom();
  }

  void _addUser(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false, ts: DateTime.now()));
      _isTyping = true;
    });
    _scrollBottom();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? override]) async {
    final text = (override ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    _addUser(text);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isTyping = false);

    final intent = _parser.parse(text);
    await _respond(intent);
  }

  Future<void> _respond(_ParsedIntent intent) async {
    if (!_contentLoaded) {
      _addBot(
        'Still loading your personalised content library — try again in a moment!',
        chips: ['Try again'],
      );
      return;
    }

    switch (intent.type) {
      case _IntentType.schedule:
        await _handleSchedule(intent);
      case _IntentType.query:
        await _handleQuery(intent);
      case _IntentType.cancel:
        await _handleCancel(intent);
      case _IntentType.suggest:
      case _IntentType.unknown:
        await _handleSuggest(intent);
    }
  }

  Future<void> _handleSchedule(_ParsedIntent intent) async {
    final targetDate = intent.date ?? _selectedDate;
    final targetTime =
        intent.time ?? const TimeOfDay(hour: 19, minute: 0); // default 7pm

    // Pick content matching the category
    final pool = intent.category != null
        ? _allContent
              .where(
                (c) =>
                    c.tags.any(
                      (t) => t.toLowerCase().contains(intent.category!),
                    ) ||
                    c.categories.any(
                      (cat) => cat.toLowerCase().contains(intent.category!),
                    ),
              )
              .toList()
        : _allContent;

    if (pool.isEmpty) {
      _addBot(
        'I couldn\'t find any ${intent.category ?? ''} content right now. '
        'Try a different topic?',
        chips: ['Gaming', 'Tech', 'Music', 'Fitness'],
      );
      return;
    }

    // Pick up to 3 items that aren't already scheduled for that slot
    final alreadyScheduled = (_scheduled[_dateKey(targetDate)] ?? [])
        .map((s) => s.contentId)
        .toSet();
    final picks = pool
        .where((c) => !alreadyScheduled.contains(c.id))
        .take(3)
        .toList();

    if (picks.isEmpty) {
      _addBot(
        'You\'ve already scheduled all available ${intent.category ?? ''} content '
        'for ${_friendlyDate(targetDate)}. Want me to find something different?',
        chips: ['Different topic', 'Show schedule'],
      );
      return;
    }

    final dt = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      targetTime.hour,
      targetTime.minute,
    );

    final newItems = picks.map((c) {
      return ScheduledItem(
        id: '${c.id}_${dt.millisecondsSinceEpoch}',
        contentId: c.id,
        title: c.title ?? 'Untitled',
        platform: c.platform.name,
        thumbnailUrl: c.thumbnailUrl,
        scheduledAt: dt,
        category: intent.category,
      );
    }).toList();

    setState(() {
      for (final item in newItems) {
        _scheduled.putIfAbsent(_dateKey(dt), () => []).add(item);
      }
      _selectedDate = targetDate;
      _focusedMonth = DateTime(targetDate.year, targetDate.month);
    });
    await _saveScheduled();

    // Schedule a local notification 5 min before each item fires
    for (final item in newItems) {
      NotificationService.instance.scheduleCalendarReminder(
        id: item.id,
        title: item.title,
        platform: item.platform,
        scheduledAt: item.scheduledAt,
      );
    }

    HapticFeedback.lightImpact();

    _addBot(
      '✅ Scheduled ${picks.length} ${intent.category ?? 'personalised'} '
      '${picks.length == 1 ? 'video' : 'videos'} for '
      '${_friendlyDate(targetDate)} at ${_formatTime(targetTime)}:',
      cards: newItems,
      chips: ['Add more', 'Show full schedule', 'Different day'],
    );

    AnalyticsService.instance.trackUserInteraction(
      action: 'calendar_chat_scheduled',
      screen: 'calendar_chat',
      additionalData: {
        'category': intent.category,
        'count': picks.length,
        'date': _dateKey(dt),
      },
    );
  }

  Future<void> _handleQuery(_ParsedIntent intent) async {
    final targetDate = intent.date ?? _selectedDate;

    // "what's scheduled for X"
    final dayItems = _scheduled[_dateKey(targetDate)] ?? [];

    if (dayItems.isEmpty) {
      final pool = intent.category != null
          ? _allContent
                .where(
                  (c) => c.tags.any(
                    (t) => t.toLowerCase().contains(intent.category!),
                  ),
                )
                .take(3)
                .toList()
          : _allContent.take(3).toList();

      _addBot(
        'Nothing scheduled for ${_friendlyDate(targetDate)} yet. '
        'Want me to schedule some ${intent.category ?? 'personalised'} content?',
        chips: [
          'Schedule ${intent.category ?? 'something'} then',
          'Try another day',
          'Show this week',
        ],
      );
      return;
    }

    // Summarise the week if "this week" / "weekend" detected
    if (intent.rawText?.toLowerCase().contains('week') == true ||
        intent.rawText?.toLowerCase().contains('weekend') == true) {
      final weekItems = <ScheduledItem>[];
      for (var i = 0; i < 7; i++) {
        final d = _selectedDate.add(Duration(days: i));
        weekItems.addAll(_scheduled[_dateKey(d)] ?? []);
      }
      if (weekItems.isEmpty) {
        _addBot(
          'Your schedule is empty this week. Shall I fill it with personalised content?',
          chips: ['Fill my week', 'Schedule for tomorrow', 'Schedule weekend'],
        );
        return;
      }
      _addBot(
        'You have ${weekItems.length} items scheduled this week 📅',
        cards: weekItems.take(5).toList(),
        chips: ['Add more', 'Clear a day', 'Show today'],
      );
      return;
    }

    setState(() {
      _selectedDate = targetDate;
      _focusedMonth = DateTime(targetDate.year, targetDate.month);
    });

    _addBot(
      'Here\'s what\'s scheduled for ${_friendlyDate(targetDate)} '
      '(${dayItems.length} ${dayItems.length == 1 ? 'item' : 'items'}):',
      cards: dayItems,
      chips: ['Add more', 'Clear this day', 'Next day'],
    );
  }

  Future<void> _handleCancel(_ParsedIntent intent) async {
    final targetDate = intent.date ?? _selectedDate;
    final key = _dateKey(targetDate);
    final had = (_scheduled[key] ?? []).length;

    if (had == 0) {
      _addBot(
        'Nothing scheduled for ${_friendlyDate(targetDate)} to cancel.',
        chips: ['Show upcoming', 'Schedule something'],
      );
      return;
    }

    final cancelledItems = _scheduled[key] ?? [];
    setState(() => _scheduled.remove(key));
    await _saveScheduled();

    // Cancel any pending notifications for the removed items
    for (final item in cancelledItems) {
      NotificationService.instance.cancelCalendarReminder(item.id);
    }

    HapticFeedback.lightImpact();

    _addBot(
      'Cleared $had ${had == 1 ? 'item' : 'items'} from ${_friendlyDate(targetDate)}. '
      'The calendar has been updated.',
      chips: ['Schedule new content', 'Show this week'],
    );
  }

  Future<void> _handleSuggest(_ParsedIntent intent) async {
    // Proactive suggestion: find the next free slot this week and suggest content
    final now = DateTime.now();
    DateTime? freeSlot;
    for (var i = 0; i < 7; i++) {
      final d = DateTime(now.year, now.month, now.day + i);
      if ((_scheduled[_dateKey(d)] ?? []).isEmpty) {
        freeSlot = d;
        break;
      }
    }

    final picks = _allContent.take(3).toList();
    final slotLabel = freeSlot != null ? _friendlyDate(freeSlot) : 'today';

    _addBot(
      'Your next free slot is $slotLabel. Here are my top picks for you:',
      cards: picks
          .map(
            (c) => ScheduledItem(
              id: 'suggest_${c.id}',
              contentId: c.id,
              title: c.title ?? 'Untitled',
              platform: c.platform.name,
              thumbnailUrl: c.thumbnailUrl,
              scheduledAt: freeSlot ?? now,
              category: c.tags.isNotEmpty ? c.tags.first : null,
            ),
          )
          .toList(),
      chips: [
        'Schedule these',
        'Show me gaming',
        'Show me tech',
        'Different picks',
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _friendlyDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff == -1) return 'yesterday';
    if (diff > 0 && diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    }
    return '${d.day}/${d.month}';
  }

  String _timeAwareGreeting() {
    final hour = DateTime.now().hour;
    final todayItems = _scheduled[_dateKey(DateTime.now())] ?? [];
    final hasToday = todayItems.isNotEmpty;

    if (hour < 12) {
      return hasToday
          ? 'Good morning! ☀️ You have ${todayItems.length} '
                '${todayItems.length == 1 ? 'video' : 'videos'} scheduled today. '
                'Tell me what else you\'d like to plan.'
          : 'Good morning! ☀️ Your schedule is clear today — '
                'want me to fill it with content you\'ll love?';
    } else if (hour < 17) {
      return hasToday
          ? 'Good afternoon! 🌤 ${todayItems.length} '
                '${todayItems.length == 1 ? 'item' : 'items'} on today\'s list. '
                'Need to add or change anything?'
          : 'Good afternoon! 🌤 Nothing scheduled yet today. '
                'I can find fresh content for this evening — just ask.';
    } else if (hour < 21) {
      return hasToday
          ? 'Good evening! 🌙 Time to unwind. You have '
                '${todayItems.length} ${todayItems.length == 1 ? 'video' : 'videos'} '
                'queued for tonight. Enjoy!'
          : 'Good evening! 🌙 Relax time — want me to curate '
                'your perfect evening watch list?';
    } else {
      return 'Still up? 🌙 Tell me what you\'d like to schedule for tomorrow '
          'and I\'ll have it ready when you wake up.';
    }
  }

  List<String> _timeAwareChips() {
    final hour = DateTime.now().hour;
    final todayItems = _scheduled[_dateKey(DateTime.now())] ?? [];

    if (hour < 12) {
      return [
        'Fill my day',
        'Show today\'s schedule',
        'Schedule for this evening',
        'Find morning content',
      ];
    } else if (hour < 17) {
      return [
        'What\'s on tonight?',
        if (todayItems.isEmpty) 'Schedule something for today',
        'Find trending now',
        'Plan my weekend',
      ];
    } else if (hour < 21) {
      return [
        if (todayItems.isNotEmpty) 'Show tonight\'s schedule',
        'Gaming content now',
        'Schedule for tomorrow',
        'What\'s trending?',
      ];
    } else {
      return [
        'Plan tomorrow',
        'Schedule for the weekend',
        'Find something relaxing',
        'Show this week',
      ];
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  Color _platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'tiktok':
        return const Color(0xFF69C9D0);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'facebook':
        return const Color(0xFF1877F2);
      default:
        return _cyan;
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Compact calendar ──────────────────────────────────────────────
          _buildMiniCalendar(),
          const Divider(color: Colors.white12, height: 1),
          // ── Chat ──────────────────────────────────────────────────────────
          Expanded(child: _buildChatList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_cyan, _purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Calendar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Schedule & discover content',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Clear chat',
          icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
          onPressed: () {
            setState(() => _messages.clear());
            _addBot(
              'Fresh start! What would you like to schedule?',
              chips: [
                'Schedule for today',
                'Find gaming content',
                'Show this week',
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── Mini calendar ───────────────────────────────────────────────────────────

  Widget _buildMiniCalendar() {
    return Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          _buildMonthHeader(),
          const SizedBox(height: 6),
          _buildWeekdayLabels(),
          const SizedBox(height: 4),
          _buildDayGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white54, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => setState(
            () => _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month - 1,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.chevron_right,
            color: Colors.white54,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => setState(
            () => _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month + 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: labels
          .map(
            (l) => Expanded(
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayGrid() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startPad = first.weekday % 7; // Sunday=0
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final totalCells = startPad + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - startPad + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 36));
            }
            final date = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              dayNum,
            );
            final key = _dateKey(date);
            final hasContent = (_scheduled[key] ?? []).isNotEmpty;
            final isSelected =
                date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = date);
                  final items = _scheduled[key] ?? [];
                  if (items.isNotEmpty) {
                    _addBot(
                      '${_friendlyDate(date).capitalize()}: ${items.length} item${items.length > 1 ? 's' : ''} scheduled',
                      cards: items,
                      chips: ['Add more', 'Clear this day'],
                    );
                  } else {
                    _addBot(
                      'Nothing scheduled for ${_friendlyDate(date)} yet. '
                      'Want me to suggest something?',
                      chips: [
                        'Schedule something',
                        'Gaming content',
                        'Tech content',
                      ],
                    );
                  }
                },
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _cyan
                        : isToday
                        ? _cyan.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: _cyan.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : isToday
                              ? _cyan
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasContent)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black54 : _cyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // ─── Chat list ───────────────────────────────────────────────────────────────

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (_isTyping && i == _messages.length) return _buildTypingIndicator();
        return _buildBubble(_messages[i]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _dotAnim,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Opacity(
                      opacity: ((_dotAnim.value + i * 0.33) % 1.0).clamp(
                        0.2,
                        1.0,
                      ),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: msg.isBot
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: msg.isBot
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              if (msg.isBot) ...[_botAvatar(), const SizedBox(width: 8)],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: msg.isBot
                        ? null
                        : const LinearGradient(
                            colors: [_cyan, Color(0xFF00A8CC)],
                          ),
                    color: msg.isBot ? _card : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isBot ? 4 : 16),
                      bottomRight: Radius.circular(msg.isBot ? 16 : 4),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isBot ? Colors.white : Colors.black,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Scheduled item cards
          if (msg.cards != null && msg.cards!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 44),
                itemCount: msg.cards!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _buildItemCard(msg.cards![i]),
              ),
            ),
          ],
          // Quick-reply chips
          if (msg.chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: msg.isBot ? 44 : 0),
                itemCount: msg.chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _buildChip(msg.chips[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(ScheduledItem item) {
    final color = _platformColor(item.platform);
    final timeStr = _formatTime(
      TimeOfDay(hour: item.scheduledAt.hour, minute: item.scheduledAt.minute),
    );
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: item.thumbnailUrl != null
                ? Image.network(
                    item.thumbnailUrl!,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbFallback(color, 60, 80),
                  )
                : _thumbFallback(color, 60, 80),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.platform.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _thumbFallback(Color color, double w, double h) => Container(
    width: w,
    height: h,
    color: color.withValues(alpha: 0.15),
    child: Icon(Icons.play_circle_filled, color: color, size: 24),
  );

  Widget _buildChip(String label) {
    return GestureDetector(
      onTap: () => _handleSend(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _cyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cyan.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _cyan,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _botAvatar() => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_cyan, _purple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
  );

  // ─── Input bar ───────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        (MediaQuery.of(context).viewInsets.bottom > 0
                ? MediaQuery.of(context).viewInsets.bottom
                : MediaQuery.of(context).padding.bottom) +
            8,
      ),
      decoration: BoxDecoration(
        color: _card,
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _input,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Schedule, find, or ask anything…',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _handleSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_cyan, _purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── String extension ─────────────────────────────────────────────────────────

extension _StringCap on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
