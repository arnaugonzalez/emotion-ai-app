import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_ai/data/models/breathing_session.dart';
import 'package:emotion_ai/data/models/emotional_record.dart';
import 'package:emotion_ai/shared/services/offline_data_service.dart';
import 'package:emotion_ai/shared/services/sqlite_helper.dart';
import 'package:emotion_ai/shared/services/data_presets.dart';
import 'package:logger/logger.dart';

final logger = Logger();

enum CalendarLoadState { loading, loaded, error }

class CalendarState {
  final CalendarLoadState state;
  final Map<DateTime, List<EmotionalRecord>> emotionalEvents;
  final Map<DateTime, List<BreathingSessionData>> breathingEvents;
  final String? errorMessage;
  final ConnectivityStatus connectivityStatus;
  final bool isFromCache;
  final DateTime? lastSync;

  const CalendarState({
    required this.state,
    required this.emotionalEvents,
    required this.breathingEvents,
    this.errorMessage,
    required this.connectivityStatus,
    required this.isFromCache,
    this.lastSync,
  });

  CalendarState copyWith({
    CalendarLoadState? state,
    Map<DateTime, List<EmotionalRecord>>? emotionalEvents,
    Map<DateTime, List<BreathingSessionData>>? breathingEvents,
    String? errorMessage,
    ConnectivityStatus? connectivityStatus,
    bool? isFromCache,
    DateTime? lastSync,
  }) {
    return CalendarState(
      state: state ?? this.state,
      emotionalEvents: emotionalEvents ?? this.emotionalEvents,
      breathingEvents: breathingEvents ?? this.breathingEvents,
      errorMessage: errorMessage ?? this.errorMessage,
      connectivityStatus: connectivityStatus ?? this.connectivityStatus,
      isFromCache: isFromCache ?? this.isFromCache,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class OfflineCalendarNotifier extends StateNotifier<CalendarState> {
  final OfflineDataService _dataService = OfflineDataService();

  OfflineCalendarNotifier()
    : super(
        const CalendarState(
          state: CalendarLoadState.loading,
          emotionalEvents: {},
          breathingEvents: {},
          connectivityStatus: ConnectivityStatus.unknown,
          isFromCache: false,
        ),
      ) {
    _initialize();
  }

  void _initialize() {
    // Listen to connectivity changes
    _dataService.connectivityStream.listen((connectivityStatus) {
      state = state.copyWith(connectivityStatus: connectivityStatus);
    });

    // Initial fetch
    fetchEvents();
  }

  /// Fetch events using offline-first approach
  Future<void> fetchEvents({
    DataSource preferredSource = DataSource.hybrid,
  }) async {
    state = state.copyWith(
      state: CalendarLoadState.loading,
      errorMessage: null,
    );

    try {
      logger.i('Fetching calendar events...');

      // Get both emotional records and breathing sessions concurrently
      final results = await Future.wait([
        _dataService.getEmotionalRecords(preferredSource: preferredSource),
        _dataService.getBreathingSessions(preferredSource: preferredSource),
      ]);

      final emotionalResult = results[0] as DataResult<List<EmotionalRecord>>;
      final breathingResult =
          results[1] as DataResult<List<BreathingSessionData>>;

      // Process emotional records
      Map<DateTime, List<EmotionalRecord>> emotionalEvents = {};
      String? errorMessage;

      if (emotionalResult.hasData) {
        emotionalEvents = await compute(
          _processEmotionalRecordsInIsolate,
          emotionalResult.data!,
        );
        logger.i('Processed ${emotionalResult.data!.length} emotional records');
      } else {
        if (emotionalResult.hasError) {
          errorMessage ??= emotionalResult.error;
        }
      }

      // Process breathing sessions
      Map<DateTime, List<BreathingSessionData>> breathingEvents = {};
      if (breathingResult.hasData) {
        breathingEvents = await compute(
          _processBreathingSessionsInIsolate,
          breathingResult.data!,
        );
        logger.i(
          'Processed ${breathingResult.data!.length} breathing sessions',
        );
      } else {
        if (breathingResult.hasError) {
          errorMessage ??= breathingResult.error;
        }
      }

      // Determine final state
      if (emotionalResult.hasData || breathingResult.hasData) {
        state = state.copyWith(
          state: CalendarLoadState.loaded,
          emotionalEvents: emotionalEvents,
          breathingEvents: breathingEvents,
          connectivityStatus: emotionalResult.connectivityStatus,
          isFromCache: emotionalResult.isFromCache,
          lastSync: emotionalResult.lastSync,
          errorMessage: null,
        );
        logger.i('Calendar events loaded successfully');
      } else {
        state = state.copyWith(
          state: CalendarLoadState.error,
          emotionalEvents: {},
          breathingEvents: {},
          errorMessage: errorMessage ?? 'No data available',
        );
      }
    } catch (e) {
      logger.e('Error fetching calendar events: $e');
      state = state.copyWith(
        state: CalendarLoadState.error,
        emotionalEvents: {},
        breathingEvents: {},
        errorMessage: e.toString(),
      );
    }
  }

  /// Retry fetching data (prefer remote if available)
  Future<void> retryFetch() async {
    await fetchEvents(preferredSource: DataSource.hybrid);
  }

  /// Force sync with backend
  Future<void> forceSyncAll() async {
    try {
      final syncSuccessful = await _dataService.forceSyncAll();
      if (syncSuccessful) {
        // Refresh data after successful sync
        await fetchEvents(preferredSource: DataSource.remote);
      } else {
        // Just refresh with local data
        await fetchEvents(preferredSource: DataSource.local);
      }
    } catch (e) {
      logger.e('Error during force sync: $e');
      // Fallback to local data
      await fetchEvents(preferredSource: DataSource.local);
    }
  }

  /// Add preset data and refresh calendar
  Future<void> addPresetData() async {
    try {
      final sqliteHelper = SQLiteHelper();
      final presetService = DataPresetService(sqliteHelper);

      await presetService.loadAllPresetData();
      logger.i('Preset data loaded successfully');

      // Refresh calendar with local data (since we just added local data)
      await fetchEvents(preferredSource: DataSource.local);
    } catch (e) {
      logger.e('Error loading preset data: $e');
      state = state.copyWith(
        state: CalendarLoadState.error,
        errorMessage: 'Failed to load preset data: $e',
      );
    }
  }

  /// Get total event count for a specific date
  int getEventCountForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);

    final emotionalCount = state.emotionalEvents.entries
        .where(
          (entry) =>
              entry.key.year == normalizedDay.year &&
              entry.key.month == normalizedDay.month &&
              entry.key.day == normalizedDay.day,
        )
        .fold(0, (count, entry) => count + entry.value.length);

    final breathingCount = state.breathingEvents.entries
        .where(
          (entry) =>
              entry.key.year == normalizedDay.year &&
              entry.key.month == normalizedDay.month &&
              entry.key.day == normalizedDay.day,
        )
        .fold(0, (count, entry) => count + entry.value.length);

    return emotionalCount + breathingCount;
  }

  /// Check if there are any events for a specific day
  bool hasEventsForDay(DateTime day) {
    return getEventCountForDay(day) > 0;
  }
}

// Provider for the calendar notifier
final offlineCalendarProvider =
    StateNotifierProvider<OfflineCalendarNotifier, CalendarState>((ref) {
      return OfflineCalendarNotifier();
    });

// Isolate functions for processing data
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
