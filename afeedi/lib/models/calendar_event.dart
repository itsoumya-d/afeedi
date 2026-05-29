class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? description;
  final String? location;
  final bool isAllDay;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.description,
    this.location,
    this.isAllDay = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final startMap = json['start'] as Map<String, dynamic>?;
    final endMap = json['end'] as Map<String, dynamic>?;
    final isAllDay = startMap?['date'] != null;

    DateTime parseDate(String? date, String? dateTime) {
      if (dateTime != null) return DateTime.parse(dateTime).toLocal();
      if (date != null) return DateTime.parse(date);
      return DateTime.now();
    }

    return CalendarEvent(
      id: json['id'] as String? ?? '',
      title: json['summary'] as String? ?? '(No title)',
      start: parseDate(startMap?['date'] as String?, startMap?['dateTime'] as String?),
      end: endMap != null
          ? parseDate(endMap['date'] as String?, endMap['dateTime'] as String?)
          : null,
      description: json['description'] as String?,
      location: json['location'] as String?,
      isAllDay: isAllDay,
    );
  }
}
