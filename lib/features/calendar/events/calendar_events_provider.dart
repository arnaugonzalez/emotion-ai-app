import 'package:flutter/foundation.dart';
import 'package:emotion_ai/data/models/breathing_session.dart';
import 'package:emotion_ai/data/models/emotional_record.dart';
import 'package:emotion_ai/config/api_config.dart';
import 'package:emotion_ai/utils/data_validator.dart';
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
      record.createdAt.year,
      record.createdAt.month,
      record.createdAt.day,
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
      session.createdAt.year,
      session.createdAt.month,
      session.createdAt.day,
    );
    events[normalizedDate] = events[normalizedDate] ?? [];
    events[normalizedDate]!.add(session);
  }
  return events;
}

// Isolate function for parsing JSON data with validation
Future<List<T>> _parseJsonDataInIsolate<T>(Map<String, dynamic> data) async {
  final List<dynamic> jsonData = data['data'];
  final String type = data['type'];

  try {
    if (type == 'emotional') {
      final validatedData = DataValidator.validateApiResponseList(
        jsonData,
        'EmotionalRecord',
      );
      return validatedData
              .map((item) => EmotionalRecord.fromJson(item))
              .toList()
          as List<T>;
    } else {
      final validatedData = DataValidator.validateApiResponseList(
        jsonData,
        'BreathingSession',
      );
      return validatedData
              .map((item) => BreathingSessionData.fromJson(item))
              .toList()
          as List<T>;
    }
  } catch (e) {
    logger.e('Error parsing $type data: $e');
    // Return empty list instead of crashing
    return <T>[];
  }
}

class CalendarEventsProvider extends ChangeNotifier {
  CalendarLoadState state = CalendarLoadState.loading;
  Map<DateTime, List<EmotionalRecord>> emotionalEvents = {};
  Map<DateTime, List<BreathingSessionData>> breathingEvents = {};
  String? errorMessage;

  /// Fetch events with comprehensive validation and error handling
  Future<void> fetchEvents() async {
    state = CalendarLoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      logger.i('Fetching calendar events from backend...');

      final emotionalResponse = await http
          .get(Uri.parse(ApiConfig.emotionalRecordsUrl()))
          .timeout(const Duration(seconds: 5));
      final breathingResponse = await http
          .get(Uri.parse(ApiConfig.breathingSessionsUrl()))
          .timeout(const Duration(seconds: 5));

      logger.i(
        'API responses - Emotional: ${emotionalResponse.statusCode}, Breathing: ${breathingResponse.statusCode}',
      );

      if (emotionalResponse.statusCode == 200 &&
          breathingResponse.statusCode == 200) {
        // Validate response bodies
        final emotionalBody = emotionalResponse.body;
        final breathingBody = breathingResponse.body;

        logger.i(
          'Response bodies - Emotional length: ${emotionalBody.length}, Breathing length: ${breathingBody.length}',
        );

        if (emotionalBody.isEmpty || breathingBody.isEmpty) {
          throw Exception('Empty response from backend');
        }

        dynamic emotionalJson;
        dynamic breathingJson;

        try {
          emotionalJson = jsonDecode(emotionalBody);
          breathingJson = jsonDecode(breathingBody);
        } catch (e) {
          throw Exception('Invalid JSON response from backend: $e');
        }

        // Ensure responses are lists
        if (emotionalJson is! List) {
          throw Exception(
            'Expected list response for emotional records, got: ${emotionalJson.runtimeType}',
          );
        }
        if (breathingJson is! List) {
          throw Exception(
            'Expected list response for breathing sessions, got: ${breathingJson.runtimeType}',
          );
        }

        logger.i('Parsing emotional records: ${emotionalJson.length} items');
        logger.i('Parsing breathing sessions: ${breathingJson.length} items');

        // Backend returns array directly, not wrapped in "data" field
        final emotionalData = await compute(
          _parseJsonDataInIsolate<EmotionalRecord>,
          {'data': emotionalJson, 'type': 'emotional'},
        );
        final breathingData = await compute(
          _parseJsonDataInIsolate<BreathingSessionData>,
          {'data': breathingJson, 'type': 'breathing'},
        );

        logger.i(
          'Successfully parsed - Emotional: ${emotionalData.length}, Breathing: ${breathingData.length}',
        );

        emotionalEvents = await compute(
          _processEmotionalRecordsInIsolate,
          emotionalData,
        );
        breathingEvents = await compute(
          _processBreathingSessionsInIsolate,
          breathingData,
        );

        logger.i('Calendar events processed successfully');
        state = CalendarLoadState.loaded;
        notifyListeners();
      } else {
        final error =
            'Backend error - Emotional: ${emotionalResponse.statusCode}, Breathing: ${breathingResponse.statusCode}';
        logger.e(error);
        throw Exception(error);
      }
    } catch (e) {
      logger.e('Error fetching calendar events: $e');
      errorMessage = e.toString();
      state = CalendarLoadState.error;

      // Provide fallback empty data to prevent UI crashes
      emotionalEvents = {};
      breathingEvents = {};

      notifyListeners();
    }
  }
}
