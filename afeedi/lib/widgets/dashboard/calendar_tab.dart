import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/enhanced_calendar_service.dart';
import '../../services/analytics_service.dart';
import '../../services/content_service.dart';
import '../../services/google_calendar_service.dart';
import '../../models/calendar_event.dart';
import '../../l10n/app_localizations.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'month'; // 'month', 'week', 'day'
  String _selectedFilter = 'all'; // 'all', 'entertainment', 'education', 'study'
  bool _isFilterExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<String> _filterOrder = ['all', 'entertainment', 'education', 'study'];

  // Google Calendar state
  bool _gcalConnecting = false;
  bool _gcalConnectionError = false;
  List<CalendarEvent> _gcalEvents = [];
  
  // Enhanced calendar functionality (fields removed - unused)
  
  // Percentage-based filtering
  double _educationPercentage = 50.0;
  double _entertainmentPercentage = 50.0;
  bool _isPercentageFilterActive = false;
  String _selectedPercentagePreset = 'custom'; // 'custom', '50-50', '80-20', '20-80'
  
  // Advanced search categories (fields removed - unused)
  
  late AnimationController _calendarAnimationController;
  late Animation<double> _calendarAnimation;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  
  final List<Map<String, dynamic>> _scheduledContent = [];
  
  @override
  void initState() {
    super.initState();
    _initGoogleCalendar();
    _loadScheduledContentFromService();
    _loadContentForSelectedDate();
    _calendarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _calendarAnimation = CurvedAnimation(
      parent: _calendarAnimationController,
      curve: Curves.easeInOut,
    );
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    
    _calendarAnimationController.forward();
  }
  
  @override
  void dispose() {
    _calendarAnimationController.dispose();
    _filterAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  /// Populates _scheduledContent with real content from ContentService,
  /// distributed across 7 days starting today (3 items per day).
  Future<void> _loadScheduledContentFromService() async {
    try {
      final allContent = await ContentService.instance.getFeedContent(limit: 21);
      final now = DateTime.now();
      // Time slots to distribute content across the day
      const timeSlots = ['08:00', '14:30', '20:00'];
      final newItems = <Map<String, dynamic>>[];
      for (int i = 0; i < 7; i++) {
        final day = DateTime(now.year, now.month, now.day + i);
        final dayItems = allContent.skip(i * 3).take(3).toList();
        for (int j = 0; j < dayItems.length; j++) {
          final c = dayItems[j];
          final durationMinutes = c.durationSeconds != null
              ? (c.durationSeconds! / 60).round()
              : 30;
          final platform = c.platform.name[0].toUpperCase() +
              c.platform.name.substring(1);
          // Determine category from tags/categories
          String category = 'entertainment';
          final allTags = [...c.tags.map((t) => t.toLowerCase()),
                           ...c.categories.map((cat) => cat.toLowerCase())];
          if (allTags.any((t) => t.contains('education') || t.contains('tutorial') || t.contains('study') || t.contains('learn'))) {
            category = 'education';
          } else if (allTags.any((t) => t.contains('fitness') || t.contains('workout') || t.contains('health') || t.contains('meditation'))) {
            category = 'health';
          }
          newItems.add({
            'id': 'feed_${c.id}_day$i',
            'title': c.title ?? 'Untitled',
            'time': timeSlots[j % timeSlots.length],
            'duration': durationMinutes,
            'platform': platform,
            'creator': c.creatorName ?? 'Unknown',
            'thumbnail': c.thumbnailUrl ?? '',
            'type': 'scheduled',
            'category': category,
            'keywords': c.tags.take(3).toList(),
            'educationValue': category == 'education' ? 80 : category == 'health' ? 50 : 20,
            'entertainmentValue': category == 'education' ? 20 : category == 'health' ? 50 : 80,
            'date': day,
          });
        }
      }
      if (mounted) {
        setState(() {
          _scheduledContent
            ..clear()
            ..addAll(newItems);
        });
      }
    } catch (e) {
      debugPrint('_loadScheduledContentFromService error: $e');
    }
  }

  Future<void> _initGoogleCalendar() async {
    await GoogleCalendarService.instance.initialize();
    if (GoogleCalendarService.instance.isConnected && mounted) {
      final events = await GoogleCalendarService.instance.getUpcomingEvents();
      if (mounted) setState(() => _gcalEvents = events);
    }
  }

  Future<void> _connectGoogleCalendar() async {
    setState(() => _gcalConnecting = true);
    final connected = await GoogleCalendarService.instance.connect();
    if (connected && mounted) {
      final events = await GoogleCalendarService.instance.getUpcomingEvents();
      setState(() {
        _gcalEvents = events;
        _gcalConnecting = false;
      });
    } else if (mounted) {
      setState(() {
        _gcalConnecting = false;
        _gcalConnectionError = true;
      });
    }
  }

  Future<void> _disconnectGoogleCalendar() async {
    await GoogleCalendarService.instance.disconnect();
    if (mounted) setState(() => _gcalEvents = []);
  }

  // Enhanced calendar methods
  Future<void> _loadContentForSelectedDate() async {
    try {
      final content = await EnhancedCalendarService.instance.getContentForDate(
        _selectedDate,
        categoryFilter: _selectedFilter,
        educationPercentage: _isPercentageFilterActive ? _educationPercentage : null,
        entertainmentPercentage: _isPercentageFilterActive ? _entertainmentPercentage : null,
      );

      final scheduled = await EnhancedCalendarService.instance.getScheduledContent(
        _selectedDate,
        _selectedDate.add(const Duration(days: 1)),
      );

      setState(() {});
      
      // Track calendar date selection
      await AnalyticsService.instance.trackUserInteraction(
        action: 'calendar_date_selected',
        screen: 'calendar',
        additionalData: {
          'selected_date': _selectedDate.toIso8601String(),
          'content_count': content.length,
          'scheduled_count': scheduled.length,
        },
      );
    } catch (error) {
      
      await AnalyticsService.instance.trackError(
        errorType: 'calendar_content_load_error',
        errorMessage: error.toString(),
        screen: 'calendar',
      );
    }
  }
  
  void _onFilterChanged() {
    _loadContentForSelectedDate();
  }
  
  final List<Map<String, dynamic>> _aiRecommendations = [
    {
      'id': 'ai1',
      'title': 'Based on your interests',
      'subtitle': 'New Flutter 3.0 Features',
      'time': '16:00',
      'confidence': 0.92,
      'thumbnail': 'https://picsum.photos/60/60?random=4',
      'educationValue': 85,
      'entertainmentValue': 15,
    },
    {
      'id': 'ai2',
      'title': 'Trending in Tech',
      'subtitle': 'AI Revolution 2024',
      'time': '18:30',
      'confidence': 0.87,
      'thumbnail': 'https://picsum.photos/60/60?random=5',
      'educationValue': 70,
      'entertainmentValue': 30,
    },
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildGoogleCalendarSection(),
          _buildHeader(),
          if (_isFilterExpanded) _buildFilterCategories(),
          _buildViewModeSelector(),
          _buildCalendarView(),
          _buildAIRecommendations(),
        ],
      ),
    );
  }
  
  Widget _buildGoogleCalendarSection() {
    final isConnected = GoogleCalendarService.instance.isConnected;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A2A4A), const Color(0xFF1A1A2E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF00D4FF).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: isConnected
          ? _buildConnectedCalendar()
          : _gcalConnectionError
              ? _buildConnectionErrorState()
              : _buildConnectButton(),
    );
  }

  Widget _buildConnectButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF4285F4), size: 20),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)?.googleCalendar ?? 'Google Calendar',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildConnectStep(Icons.lock_outline, AppLocalizations.of(context)?.readOnlyAccess ?? 'Read-only access', AppLocalizations.of(context)?.readOnlyAccessHint ?? 'We only read events, never modify them'),
        _buildConnectStep(Icons.event, AppLocalizations.of(context)?.seeEventsInApp ?? 'See events in-app', AppLocalizations.of(context)?.seeEventsInAppHint ?? 'Your calendar appears alongside your content schedule'),
        _buildConnectStep(Icons.privacy_tip_outlined, AppLocalizations.of(context)?.privateAndLocal ?? 'Private & local', AppLocalizations.of(context)?.privateAndLocalHint ?? 'Data stays on-device; we never share it'),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _gcalConnecting ? null : _connectGoogleCalendar,
            icon: _gcalConnecting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.login, size: 18),
            label: Text(_gcalConnecting ? (AppLocalizations.of(context)?.connecting ?? 'Connecting...') : (AppLocalizations.of(context)?.connectWithGoogle ?? 'Connect with Google')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionErrorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Could not connect to Google Calendar',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Check your permissions and internet connection, then try again.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() => _gcalConnectionError = false);
              _connectGoogleCalendar();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _gcalConnectionError = false),
          child: const Text('Dismiss', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildConnectStep(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4285F4), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$title  ', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  TextSpan(text: subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF4285F4), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Google Calendar • ${GoogleCalendarService.instance.userEmail ?? ""}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: _disconnectGoogleCalendar,
              child: Text(AppLocalizations.of(context)?.disconnect ?? 'Disconnect', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
        if (_gcalEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(AppLocalizations.of(context)?.noUpcomingEvents ?? 'No upcoming events', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          )
        else ...[
          const SizedBox(height: 10),
          ..._gcalEvents.take(5).map((event) => _buildCalendarEventTile(event)),
        ],
      ],
    );
  }

  Widget _buildCalendarEventTile(CalendarEvent event) {
    final time = event.isAllDay
        ? (AppLocalizations.of(context)?.allDay ?? 'All day')
        : TimeOfDay.fromDateTime(event.start).format(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.only(top: 2),
            child: Text(time, style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.location != null)
                  Text(event.location!, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCategories() {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _filterAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: AppTheme.primaryCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.contentCategories ?? 'Content Categories',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter Type Toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isPercentageFilterActive = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: !_isPercentageFilterActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.categoryFilter ?? 'Category Filter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: !_isPercentageFilterActive ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isPercentageFilterActive = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _isPercentageFilterActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.percentageFilter ?? 'Percentage Filter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: _isPercentageFilterActive ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter Content
                _isPercentageFilterActive
                    ? _buildPercentageFilter()
                    : _buildCategoryFilter(),
                const SizedBox(height: 12),
                _buildSearchField(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOrder.length,
        itemBuilder: (context, index) {
          final filter = _filterOrder[index];
          final displayName = filter == 'all' ? 'All' : 
              filter[0].toUpperCase() + filter.substring(1);
          final icon = filter == 'all' ? Icons.apps :
              filter == 'entertainment' ? Icons.movie :
              filter == 'education' ? Icons.school : Icons.book;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Draggable<String>(
              data: filter,
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.1,
                  child: _buildFilterChip(displayName, filter, icon),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: _buildFilterChip(displayName, filter, icon),
              ),
              child: DragTarget<String>(
                onAccept: (draggedFilter) {
                  setState(() {
                    final draggedIndex = _filterOrder.indexOf(draggedFilter);
                    final targetIndex = _filterOrder.indexOf(filter);
                    if (draggedIndex != -1 && targetIndex != -1) {
                      _filterOrder.removeAt(draggedIndex);
                      _filterOrder.insert(targetIndex, draggedFilter);
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return _buildFilterChip(displayName, filter, icon);
                },
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPercentageFilter() {
    return Column(
      children: [
        // Preset buttons
        Row(
          children: [
            _buildPresetButton('50-50', '50/50'),
            const SizedBox(width: 8),
            _buildPresetButton('80-20', '80/20'),
            const SizedBox(width: 8),
            _buildPresetButton('20-80', '20/80'),
          ],
        ),
        const SizedBox(height: 12),
        // Custom slider
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)?.educationPct(_educationPercentage.round()) ?? 'Education: ${_educationPercentage.round()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  AppLocalizations.of(context)?.entertainmentPct(_entertainmentPercentage.round()) ?? 'Entertainment: ${_entertainmentPercentage.round()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.2),
                trackHeight: 2,
              ),
              child: Slider(
                value: _educationPercentage,
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: _updatePercentages,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPresetButton(String preset, String label) {
    final isSelected = _selectedPercentagePreset == preset;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setPercentagePreset(preset),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        _onFilterChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryCyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryCyan
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? AppTheme.primaryCyan
                  : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? AppTheme.primaryCyan
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.searchContent ?? 'Search content...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.calendar ?? 'Calendar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)?.personalizedContentSchedule ?? 'Your personalized content schedule',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildQuickCalendarStats(),
              const SizedBox(width: 8),
              _buildFilterButton(),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFilterExpanded = !_isFilterExpanded;
          if (_isFilterExpanded) {
            _filterAnimationController.forward();
          } else {
            _filterAnimationController.reverse();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isFilterExpanded 
              ? AppTheme.primaryCyan.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFilterExpanded 
                ? AppTheme.primaryCyan.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2)
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFilterExpanded ? Icons.filter_list : Icons.tune,
              color: _isFilterExpanded ? AppTheme.primaryCyan : Colors.white,
              size: 20,
            ),
            if (_isFilterExpanded) ...[
               const SizedBox(width: 8),
               Text(
                 AppLocalizations.of(context)?.filter ?? 'Filter',
                 style: TextStyle(
                   color: AppTheme.primaryCyan,
                   fontSize: 14,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ]
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickCalendarStats() {
    final todayCount = _getContentForDate(DateTime.now()).length;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            todayCount.toString(),
            style: TextStyle(
              color: AppTheme.primaryPink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            AppLocalizations.of(context)?.today ?? 'Today',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildViewModeButton(AppLocalizations.of(context)?.monthView ?? 'Month', 'month'),
          _buildViewModeButton(AppLocalizations.of(context)?.weekView ?? 'Week', 'week'),
          _buildViewModeButton(AppLocalizations.of(context)?.dayView ?? 'Day', 'day'),
        ],
      ),
    );
  }
  
  Widget _buildViewModeButton(String label, String mode) {
    final isSelected = _viewMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryCyan.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected 
                  ? AppTheme.primaryCyan
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCalendarView() {
    return AnimatedBuilder(
      animation: _calendarAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildCalendarHeader(),
              const SizedBox(height: 16),
              SizedBox(
                height: _viewMode == 'month' ? 350 : 400,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _viewMode == 'month'
                      ? _buildMonthView()
                      : _viewMode == 'week'
                          ? _buildWeekView()
                          : _buildDayView(),
                ),
              ),
              // Selected date content panel — shown below month grid
              if (_viewMode == 'month') ...[
                const SizedBox(height: 16),
                _buildSelectedDatePanel(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedDatePanel() {
    final items = _getContentForDate(_selectedDate);
    final label = DateFormat.yMMMd().format(_selectedDate);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note, color: AppTheme.primaryCyan, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.length} item${items.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.25), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.noContentScheduled ?? 'No content scheduled for this day',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map((item) => _buildSelectedDateItem(item)),
        ],
      ),
    );
  }

  Widget _buildSelectedDateItem(Map<String, dynamic> item) {
    final thumbnail = item['thumbnail']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              thumbnail,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
                child: Icon(Icons.play_circle_outline, color: Colors.white38, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['time'] ?? ''} · ${item['creator'] ?? ''} · ${item['duration'] ?? 0} min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            _calendarAnimationController.reset();
            setState(() {
              if (_viewMode == 'month') {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
              } else if (_viewMode == 'week') {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
              } else {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              }
            });
            _calendarAnimationController.forward();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chevron_left,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _getHeaderText(),
                key: ValueKey(_getHeaderText()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            _calendarAnimationController.reset();
            setState(() {
              if (_viewMode == 'month') {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
              } else if (_viewMode == 'week') {
                _selectedDate = _selectedDate.add(const Duration(days: 7));
              } else {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              }
            });
            _calendarAnimationController.forward();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
  
  String _getHeaderText() {
    if (_viewMode == 'month') {
      return DateFormat.yMMMM().format(_selectedDate);
    } else if (_viewMode == 'week') {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${startOfWeek.day}–${endOfWeek.day} ${DateFormat.MMMM().format(_selectedDate)}';
    } else {
      return DateFormat.yMMMMd().format(_selectedDate);
    }
  }
  
  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final totalCells = ((daysInMonth + firstWeekday - 1) / 7).ceil() * 7;

    // Check if this month has any scheduled content
    final monthHasContent = List.generate(daysInMonth, (i) => i + 1).any((day) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      return _getContentForDate(date).isNotEmpty;
    });

    return Column(
      key: ValueKey('month_${_selectedDate.month}_${_selectedDate.year}'),
      children: [
        // Weekday headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - firstWeekday + 2;
              final isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;
              
              if (!isValidDay) {
                return Container(); // Empty cell for days outside current month
              }
              
              final currentDate = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
              final hasContent = _getContentForDate(currentDate).isNotEmpty;
              final contentCount = _getContentForDate(currentDate).length;
              
              final isToday = dayNumber == DateTime.now().day && 
                             _selectedDate.month == DateTime.now().month &&
                             _selectedDate.year == DateTime.now().year;
              final isSelected = dayNumber == _selectedDate.day;
              
              return Semantics(
                label: isToday
                    ? 'Today, $dayNumber${hasContent ? ", has content" : ""}'
                    : '$dayNumber${hasContent ? ", has content" : ""}',
                selected: isSelected,
                button: true,
                child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryCyan.withValues(alpha: 0.3)
                        : isToday
                            ? AppTheme.primaryPink.withValues(alpha: 0.2)
                            : hasContent
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppTheme.primaryCyan, width: 2)
                        : isToday
                            ? Border.all(color: AppTheme.primaryPink, width: 1.5)
                            : hasContent
                                ? Border.all(color: Colors.white.withValues(alpha: 0.2))
                                : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            color: isSelected 
                                ? AppTheme.primaryCyan
                                : isToday
                                    ? AppTheme.primaryPink
                                    : Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasContent)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(currentDate),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              contentCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        ),
        if (!monthHasContent)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white.withValues(alpha: 0.25),
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  'No content scheduled this month',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _getContentForDate(DateTime date) {
    try {
      // Check Google Calendar events for this date
      final gcalEventsForDate = _gcalEvents.where((event) {
        return event.start.year == date.year &&
            event.start.month == date.month &&
            event.start.day == date.day;
      }).toList();

      // Check scheduled content items that have a 'date' field matching this date
      final scheduledForDate = _getFilteredContent().where((content) {
        final rawDate = content['date'];
        if (rawDate == null) return false;
        final contentDate = rawDate is DateTime ? rawDate : null;
        if (contentDate == null) return false;
        return contentDate.year == date.year &&
            contentDate.month == date.month &&
            contentDate.day == date.day;
      }).toList();

      // Combine: if Google Calendar events exist for this date, show them as entries
      if (gcalEventsForDate.isNotEmpty) {
        final gcalItems = gcalEventsForDate.map((e) => {
          'id': e.id,
          'title': e.title,
          'time': e.isAllDay ? (AppLocalizations.of(context)?.allDay ?? 'All day') :
              TimeOfDay.fromDateTime(e.start).format(context),
          'duration': e.end != null ? e.end!.difference(e.start).inMinutes : 60,
          'platform': 'Google Calendar',
          'creator': e.location ?? '',
          'thumbnail': null,
          'type': 'calendar',
          'category': 'all',
          'keywords': <String>[],
          'educationValue': 50,
          'entertainmentValue': 50,
          'date': e.start,
        }).toList();
        return [...gcalItems, ...scheduledForDate];
      }
      return scheduledForDate;
    } catch (e) {
      debugPrint('Error in _getContentForDate: $e');
      return [];
    }
  }
  
  List<Map<String, dynamic>> _getFilteredContent() {
    try {
      var filtered = List<Map<String, dynamic>>.from(_scheduledContent);
      
      // Apply percentage-based filter if active
      if (_isPercentageFilterActive) {
        filtered = filtered.where((content) {
          try {
            final educationValue = content['educationValue'] as int? ?? 50;
            final entertainmentValue = content['entertainmentValue'] as int? ?? 50;
            
            // Check if content matches the desired percentage range (±10% tolerance)
            final educationMatch = (educationValue >= _educationPercentage - 10) && 
                                  (educationValue <= _educationPercentage + 10);
            final entertainmentMatch = (entertainmentValue >= _entertainmentPercentage - 10) && 
                                      (entertainmentValue <= _entertainmentPercentage + 10);
            
            return educationMatch || entertainmentMatch;
          } catch (e) {
            debugPrint('Error filtering by percentage: $e');
            return false;
          }
        }).toList();
      }
      // Apply category filter if percentage filter is not active
      else if (_selectedFilter != 'all') {
        filtered = filtered.where((content) {
          try {
            return content['category']?.toString().toLowerCase() == _selectedFilter;
          } catch (e) {
            debugPrint('Error filtering by category: $e');
            return false;
          }
        }).toList();
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((content) {
          try {
            final title = (content['title'] ?? '').toString().toLowerCase();
            final creator = (content['creator'] ?? '').toString().toLowerCase();
            final keywords = (content['keywords'] as List<dynamic>? ?? [])
                .map((k) => k.toString())
                .join(' ')
                .toLowerCase();
            
            return title.contains(_searchQuery) ||
                   creator.contains(_searchQuery) ||
                   keywords.contains(_searchQuery);
          } catch (e) {
            debugPrint('Error filtering by search query: $e');
            return false;
          }
        }).toList();
      }
      
      return filtered;
    } catch (e) {
      debugPrint('Error in _getFilteredContent: $e');
      return [];
    }
  }
  
  void _setPercentagePreset(String preset) {
    setState(() {
      _selectedPercentagePreset = preset;
      switch (preset) {
        case '50-50':
          _educationPercentage = 50.0;
          _entertainmentPercentage = 50.0;
          break;
        case '80-20':
          _educationPercentage = 80.0;
          _entertainmentPercentage = 20.0;
          break;
        case '20-80':
          _educationPercentage = 20.0;
          _entertainmentPercentage = 80.0;
          break;
        default:
          // Keep current custom values
          break;
      }
    });
  }
  
  void _updatePercentages(double education) {
    setState(() {
      _educationPercentage = education;
      _entertainmentPercentage = 100.0 - education;
      _selectedPercentagePreset = 'custom';
    });
  }
  
  Color _getCategoryColor(dynamic input) {
    try {
      if (input is DateTime) {
        final content = _getContentForDate(input);
        if (content.isEmpty) return AppTheme.primaryPink;
        
        final categories = content.map((c) => c['category']?.toString() ?? '').toSet();
        if (categories.contains('education')) return AppTheme.primaryCyan;
        if (categories.contains('study')) return const Color(0xFF4CAF50);
        return AppTheme.primaryPink; // entertainment
      } else if (input is String) {
        switch (input.toLowerCase()) {
          case 'education':
            return AppTheme.primaryCyan;
          case 'study':
            return const Color(0xFF4CAF50);
          case 'entertainment':
          default:
            return AppTheme.primaryPink;
        }
      }
      return AppTheme.primaryPink;
    } catch (e) {
      debugPrint('Error in _getCategoryColor: $e');
      return AppTheme.primaryPink;
    }
  }
  
  Widget _buildWeekView() {
    final filteredContent = _getFilteredContent();
    
    if (filteredContent.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      key: ValueKey('week_${_selectedDate.millisecondsSinceEpoch}_$_selectedFilter'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredContent.length,
      itemBuilder: (context, index) {
        final content = filteredContent[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          child: _buildContentItem(content),
        );
      },
    );
  }
  
  Widget _buildDayView() {
    final filteredContent = _getContentForDate(_selectedDate);

    if (filteredContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_available_outlined,
              color: Colors.white30,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nothing scheduled for this day',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Content from your feed appears here automatically',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      key: ValueKey('day_${_selectedDate.millisecondsSinceEpoch}_$_selectedFilter'),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.today,
                color: AppTheme.primaryCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.itemsScheduled(filteredContent.length) ?? '${filteredContent.length} items scheduled',
                style: TextStyle(
                  color: AppTheme.primaryCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredContent.length,
            itemBuilder: (context, index) {
              final content = filteredContent[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 200 + (index * 50)),
                child: _buildContentItem(content, showTime: true, showCategory: true),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == 'all' 
                ? Icons.event_busy
                : _selectedFilter == 'entertainment'
                    ? Icons.movie_outlined
                    : _selectedFilter == 'education'
                        ? Icons.school_outlined
                        : Icons.book_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? (AppLocalizations.of(context)?.noContentScheduled ?? 'No content scheduled')
                : (AppLocalizations.of(context)?.noFilterContent(_selectedFilter) ?? 'No $_selectedFilter content'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.tryDifferentFilter ?? 'Try selecting a different filter or date',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentItem(Map<String, dynamic> content, {bool showTime = false, bool showCategory = false}) {
    final educationValue = content['educationValue'] as int? ?? 50;
    final entertainmentValue = content['entertainmentValue'] as int? ?? 50;
    final categoryColor = _getCategoryColor(content['category']);
    
    return Draggable<Map<String, dynamic>>(
      data: content,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 0.9,
          child: Opacity(
            opacity: 0.8,
            child: _buildContentCard(content, showTime, showCategory, educationValue, entertainmentValue, categoryColor),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildContentCard(content, showTime, showCategory, educationValue, entertainmentValue, categoryColor),
      ),
      child: DragTarget<Map<String, dynamic>>(
        onAccept: (draggedContent) {
          _handleContentDrop(draggedContent, content);
        },
        builder: (context, candidateData, rejectedData) {
          return _buildContentCard(content, showTime, showCategory, educationValue, entertainmentValue, categoryColor);
        },
      ),
    );
  }
  
  Widget _buildContentCard(Map<String, dynamic> content, bool showTime, bool showCategory, int educationValue, int entertainmentValue, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  content['thumbnail'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            content['title']?.toString() ?? (AppLocalizations.of(context)?.unknownTitle ?? 'Unknown Title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showCategory) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(content['category']).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getCategoryColor(content['category']).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              content['category'].toString().toUpperCase(),
                              style: TextStyle(
                                color: _getCategoryColor(content['category']),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content['creator']?.toString() ?? (AppLocalizations.of(context)?.unknownCreator ?? 'Unknown Creator'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    if (showTime) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppTheme.primaryCyan,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${content['time'] ?? '--:--'} • ${content['duration'] ?? 0} min',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (content['keywords'] != null && content['keywords'].isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: (content['keywords'] as List<String>).take(3).map((keyword) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              keyword,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 9,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.more_vert,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
          // Education/Entertainment values
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: Colors.blue,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)?.education ?? 'Education',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${educationValue}%',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.movie,
                            color: Colors.orange,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)?.entertainment ?? 'Entertainment',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${entertainmentValue}%',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _handleContentDrop(Map<String, dynamic> draggedContent, Map<String, dynamic> targetContent) {
    // This could be used to swap positions or change categories
    // For now, we'll show a snackbar indicating the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.movedNear(draggedContent['title']?.toString() ?? '', targetContent['title']?.toString() ?? '') ?? 'Moved "${draggedContent['title']}" near "${targetContent['title']}"',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  Widget _buildAIRecommendations() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryPink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.aiRecommendations ?? 'AI Recommendations',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_aiRecommendations.map((rec) => _buildRecommendationCard(rec)).toList()),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              recommendation['thumbnail'] ?? '',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryPink.withValues(alpha: 0.5),
                    size: 16,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'],
                  style: TextStyle(
                    color: AppTheme.primaryPink,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  recommendation['subtitle'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)?.suggestedFor(recommendation['time']?.toString() ?? '') ?? 'Suggested for ${recommendation['time']}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(recommendation['confidence'] * 100).toInt()}%',
              style: TextStyle(
                color: AppTheme.primaryPink,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}