import 'package:flutter/material.dart';
import 'package:emotion_ai/shared/models/emotional_record.dart';
import 'package:emotion_ai/shared/models/breathing_session_data.dart';
import 'package:emotion_ai/shared/services/sqlite_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

final logger = Logger();

enum CalendarLoadState { loading, loaded, error }

class CalendarEventsProvider extends ChangeNotifier {
  CalendarLoadState state = CalendarLoadState.loading;
  Map<DateTime, List<EmotionalRecord>> emotionalEvents = {};
  Map<DateTime, List<BreathingSessionData>> breathingEvents = {};
  String? errorMessage;

  /// Normalizes a DateTime to midnight to ensure consistent date comparison
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Pass a callback to show a SnackBar if backend is unreachable
  Future<void> fetchEvents({void Function(String)? onBackendError}) async {
    state = CalendarLoadState.loading;
    notifyListeners();

    final sqliteHelper = SQLiteHelper();

    try {
      // Try backend first with timeout
      final emotionalResponse = await http
          .get(Uri.parse('http://10.0.2.2:8000/emotional_records/'))
          .timeout(const Duration(seconds: 2));
      final breathingResponse = await http
          .get(Uri.parse('http://10.0.2.2:8000/breathing_sessions/'))
          .timeout(const Duration(seconds: 2));

      if (emotionalResponse.statusCode == 200 &&
          breathingResponse.statusCode == 200) {
        final List<dynamic> emotionalData = jsonDecode(emotionalResponse.body);
        final List<dynamic> breathingData = jsonDecode(breathingResponse.body);

        _processEmotionalRecords(
          emotionalData.map((item) => EmotionalRecord.fromMap(item)).toList(),
        );
        _processBreathingSessions(
          breathingData
              .map((item) => BreathingSessionData.fromMap(item))
              .toList(),
        );

        state = CalendarLoadState.loaded;
        notifyListeners();
        return;
      } else {
        throw Exception('Failed to fetch from backend');
      }
    } catch (e) {
      logger.w('Backend connection failed: $e. Loading from local storage.');

      // Show a SnackBar if callback is provided
      if (onBackendError != null) {
        onBackendError('No connection with backend. Loading local data.');
      }

      // Fallback to SQLite
      try {
        final emotionalRecords = await sqliteHelper.getEmotionalRecords();
        final breathingSessions = await sqliteHelper.getBreathingSessions();

        logger.i(
          'Loaded ${emotionalRecords.length} emotional records and ${breathingSessions.length} breathing sessions from SQLite',
        );

        _processEmotionalRecords(emotionalRecords);
        _processBreathingSessions(breathingSessions);

        state = CalendarLoadState.loaded;
        notifyListeners();
      } catch (err) {
        logger.e('Error loading from SQLite: $err');
        errorMessage = err.toString();
        state = CalendarLoadState.error;
        notifyListeners();
      }
    }
  }

  /// Process emotional records into the events map
  void _processEmotionalRecords(List<EmotionalRecord> records) {
    emotionalEvents = {};
    for (var record in records) {
      final normalizedDate = _normalizeDate(record.date);
      emotionalEvents[normalizedDate] = emotionalEvents[normalizedDate] ?? [];
      emotionalEvents[normalizedDate]!.add(record);
    }
    logger.i('Processed ${records.length} emotional records for calendar');
  }

  /// Process breathing sessions into the events map
  void _processBreathingSessions(List<BreathingSessionData> sessions) {
    breathingEvents = {};
    for (var session in sessions) {
      final normalizedDate = _normalizeDate(session.date);
      breathingEvents[normalizedDate] = breathingEvents[normalizedDate] ?? [];
      breathingEvents[normalizedDate]!.add(session);
    }
    logger.i('Processed ${sessions.length} breathing sessions for calendar');
  }
}
