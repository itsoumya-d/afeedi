import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_event.dart';

class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._();
  factory GoogleCalendarService() => _instance;
  static GoogleCalendarService get instance => _instance;
  GoogleCalendarService._();

  static const _cacheKey = 'google_calendar_events_cache';
  static const _cacheTimeKey = 'google_calendar_cache_time';
  static const _cacheTtlMinutes = 15;

  final _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar.readonly'],
  );

  GoogleSignInAccount? _account;

  bool get isConnected => _account != null;
  String? get userEmail => _account?.email;

  Future<void> initialize() async {
    try {
      _account = await _googleSignIn.signInSilently();
    } catch (_) {}
  }

  Future<bool> connect() async {
    try {
      _account = await _googleSignIn.signIn();
      return _account != null;
    } catch (e) {
      debugPrint('Google Calendar sign-in error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _account = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
    } catch (e) {
      debugPrint('Google Calendar sign-out error: $e');
    }
  }

  Future<List<CalendarEvent>> getUpcomingEvents({int maxResults = 50}) async {
    if (_account == null) return [];

    // Return cached events if fresh
    final cached = await _loadCache();
    if (cached != null) return cached;

    try {
      final auth = await _account!.authentication;
      final token = auth.accessToken;
      if (token == null) return [];

      final now = DateTime.now().toUtc().toIso8601String();
      final uri = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events'
        '?maxResults=$maxResults'
        '&orderBy=startTime'
        '&singleEvents=true'
        '&timeMin=$now',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Calendar API error: ${response.statusCode} ${response.body}',
        );
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      final events = items
          .map((item) => CalendarEvent.fromJson(item as Map<String, dynamic>))
          .toList();

      await _saveCache(events);
      return events;
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      return [];
    }
  }

  Future<List<CalendarEvent>?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt(_cacheTimeKey);
      if (cacheTime == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
      if (age > _cacheTtlMinutes * 60 * 1000) return null;
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => CalendarEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(List<CalendarEvent> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = events
          .map(
            (e) => {
              'id': e.id,
              'summary': e.title,
              'start': e.isAllDay
                  ? {'date': e.start.toIso8601String().split('T').first}
                  : {'dateTime': e.start.toIso8601String()},
              'end': e.end == null
                  ? null
                  : e.isAllDay
                  ? {'date': e.end!.toIso8601String().split('T').first}
                  : {'dateTime': e.end!.toIso8601String()},
              'description': e.description,
              'location': e.location,
            },
          )
          .toList();
      await prefs.setString(_cacheKey, jsonEncode(list));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}
