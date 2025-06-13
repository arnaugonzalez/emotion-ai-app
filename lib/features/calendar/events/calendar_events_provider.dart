import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:emotion_ai/shared/models/emotional_record.dart';
import 'package:emotion_ai/shared/models/breathing_session_data.dart';
import 'package:emotion_ai/shared/services/sqlite_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

final logger = Logger();

enum CalendarLoadState { loading, loaded, error }

// Isolate function for processing emotional records
Future<Map<DateTime, List<EmotionalRecord>>> _processEmotionalRecordsInIsolate(
  List<EmotionalRecord> records,
) async {
  final Map<DateTime, List<EmotionalRecord>> events = {};
  for (var record in records) {
    final normalizedDate = DateTime(
      record.date.year,
      record.date.month,
      record.date.day,
    );
    events[normalizedDate] = events[normalizedDate] ?? [];
    events[normalizedDate]!.add(record);
  }
  return events;
}

// Isolate function for processing breathing sessions
Future<Map<DateTime, List<BreathingSessionData>>>
_processBreathingSessionsInIsolate(List<BreathingSessionData> sessions) async {
  final Map<DateTime, List<BreathingSessionData>> events = {};
  for (var session in sessions) {
    final normalizedDate = DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
    );
    events[normalizedDate] = events[normalizedDate] ?? [];
    events[normalizedDate]!.add(session);
  }
  return events;
}

// Isolate function for parsing JSON data
Future<List<T>> _parseJsonDataInIsolate<T>(Map<String, dynamic> data) async {
  final List<dynamic> jsonData = data['data'];
  final String type = data['type'];

  if (type == 'emotional') {
    return jsonData.map((item) => EmotionalRecord.fromMap(item)).toList()
        as List<T>;
  } else {
    return jsonData.map((item) => BreathingSessionData.fromMap(item)).toList()
        as List<T>;
  }
}

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
        // Parse JSON data in isolates
        final emotionalData = await compute(
          _parseJsonDataInIsolate<EmotionalRecord>,
          {'data': jsonDecode(emotionalResponse.body), 'type': 'emotional'},
        );
        final breathingData = await compute(
          _parseJsonDataInIsolate<BreathingSessionData>,
          {'data': jsonDecode(breathingResponse.body), 'type': 'breathing'},
        );

        // Process records in isolates
        emotionalEvents = await compute(
          _processEmotionalRecordsInIsolate,
          emotionalData,
        );
        breathingEvents = await compute(
          _processBreathingSessionsInIsolate,
          breathingData,
        );

        state = CalendarLoadState.loaded;
        notifyListeners();
        return;
      } else {
        throw Exception('Failed to fetch from backend');
      }
    } catch (e) {
      logger.w('Backend connection failed: $e. Loading from local storage.');

      if (onBackendError != null) {
        onBackendError('No connection with backend. Loading local data.');
      }

      try {
        final emotionalRecords = await sqliteHelper.getEmotionalRecords();
        final breathingSessions = await sqliteHelper.getBreathingSessions();

        // Process local data in isolates
        emotionalEvents = await compute(
          _processEmotionalRecordsInIsolate,
          emotionalRecords,
        );
        breathingEvents = await compute(
          _processBreathingSessionsInIsolate,
          breathingSessions,
        );

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
}
