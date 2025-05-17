import '../models/emotional_record.dart';
import '../models/breathing_session_data.dart';
import '../services/sqlite_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Service class for generating and loading preset data for testing
class DataPresetService {
  final SQLiteHelper _sqliteHelper;

  DataPresetService(this._sqliteHelper);

  /// Generate preset emotional records for calendar testing
  Future<List<EmotionalRecord>> generatePresetEmotionalRecords() async {
    final now = DateTime.now();
    final records = <EmotionalRecord>[];

    // Today's records
    records.add(
      EmotionalRecord(
        date: now,
        source: "Testing",
        description: "Feeling energized about the app progress",
        emotion: Emotion.excited,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(hours: 6)),
        source: "Testing",
        description: "Morning meditation brought peace",
        emotion: Emotion.tender,
      ),
    );

    // Yesterday's records
    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 1)),
        source: "Testing",
        description: "Relaxed evening with friends",
        emotion: Emotion.happy,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 1, hours: 8)),
        source: "Testing",
        description: "Upset about work deadline being moved up",
        emotion: Emotion.angry,
      ),
    );

    // Records from the past week
    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 2)),
        source: "Testing",
        description: "Worried about upcoming presentation",
        emotion: Emotion.anxious,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 3)),
        source: "Testing",
        description: "Proud of finishing difficult project",
        emotion: Emotion.happy,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 3, hours: 12)),
        source: "Testing",
        description: "Morning anxiety about traffic",
        emotion: Emotion.anxious,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 4)),
        source: "Testing",
        description: "Disappointed with test results",
        emotion: Emotion.sad,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 5)),
        source: "Testing",
        description: "Excited about weekend plans",
        emotion: Emotion.excited,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 6)),
        source: "Testing",
        description: "Scared after watching horror movie",
        emotion: Emotion.scared,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 7)),
        source: "Testing",
        description: "Frustrated with slow progress",
        emotion: Emotion.angry,
      ),
    );

    // Records from 2 weeks ago
    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 10)),
        source: "Testing",
        description: "Proud of fitness achievements",
        emotion: Emotion.excited,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 11)),
        source: "Testing",
        description: "Supported friend through difficult time",
        emotion: Emotion.tender,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 12)),
        source: "Testing",
        description: "Nervous about doctor's appointment",
        emotion: Emotion.anxious,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 13)),
        source: "Testing",
        description: "Happy about surprise gift",
        emotion: Emotion.happy,
      ),
    );

    // Multiple emotions on the same day (two weeks ago)
    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 14)),
        source: "Testing",
        description: "Sad about missed opportunity",
        emotion: Emotion.sad,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 14, hours: 6)),
        source: "Testing",
        description: "Happy about surprise visit",
        emotion: Emotion.happy,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 14, hours: 12)),
        source: "Testing",
        description: "Anxious about tomorrow's meeting",
        emotion: Emotion.anxious,
      ),
    );

    // Records from 3-4 weeks ago
    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 18)),
        source: "Testing",
        description: "Excited about new opportunity",
        emotion: Emotion.excited,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 20)),
        source: "Testing",
        description: "Terrified of spider in room",
        emotion: Emotion.scared,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 22)),
        source: "Testing",
        description: "Furious after argument",
        emotion: Emotion.angry,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 25)),
        source: "Testing",
        description: "Overwhelmed with workload",
        emotion: Emotion.anxious,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 27)),
        source: "Testing",
        description: "Melancholic about old memories",
        emotion: Emotion.sad,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 30)),
        source: "Testing",
        description: "In love with new project",
        emotion: Emotion.tender,
      ),
    );

    // Older records (from past months)
    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 40)),
        source: "Testing",
        description: "Happy after great workout",
        emotion: Emotion.happy,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 45)),
        source: "Testing",
        description: "Felt connected during deep conversation",
        emotion: Emotion.tender,
      ),
    );

    records.add(
      EmotionalRecord(
        date: now.subtract(const Duration(days: 60)),
        source: "Testing",
        description: "Thrilled about successful project launch",
        emotion: Emotion.excited,
      ),
    );

    return records;
  }

  /// Generate preset breathing sessions for calendar testing
  Future<List<BreathingSessionData>> generatePresetBreathingSessions() async {
    final now = DateTime.now();
    final patterns = await _sqliteHelper.getBreathingPatterns();

    if (patterns.isEmpty) {
      logger.w("No breathing patterns found for preset sessions");
      return [];
    }

    // Find different patterns by name
    final boxBreathing = patterns.firstWhere(
      (p) => p.name == 'Box Breathing',
      orElse: () => patterns.first,
    );

    final relaxationBreath = patterns.firstWhere(
      (p) => p.name == '4-7-8 Relaxation Breath',
      orElse: () => patterns.first,
    );

    final calmBreath = patterns.firstWhere(
      (p) => p.name == 'Calm Breath',
      orElse: () => patterns.first,
    );

    final wimHof = patterns.firstWhere(
      (p) => p.name == 'Wim Hof Method',
      orElse: () => patterns.first,
    );

    final yogaBreath = patterns.firstWhere(
      (p) => p.name == 'Deep Yoga Breath',
      orElse: () => patterns.first,
    );

    final sessions = <BreathingSessionData>[];

    // Today's sessions
    sessions.add(
      BreathingSessionData(
        date: now,
        pattern: boxBreathing,
        rating: 4.5,
        comment: "Felt refreshed after this session",
      ),
    );

    // Sessions from the past week
    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 1)),
        pattern: relaxationBreath,
        rating: 5.0,
        comment: "Really helped with anxiety before presentation",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 2)),
        pattern: calmBreath,
        rating: 3.5,
        comment: "Helped a little but still felt stressed",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 3)),
        pattern: relaxationBreath,
        rating: 5.0,
        comment: "Really helped with anxiety",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 5)),
        pattern: yogaBreath,
        rating: 4.0,
        comment: "Good morning session",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 7)),
        pattern: boxBreathing,
        rating: 3.5,
        comment: "Was distracted during session",
      ),
    );

    // Sessions from 2 weeks ago
    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 10)),
        pattern: wimHof,
        rating: 4.8,
        comment: "Intense but energizing experience",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 12)),
        pattern: calmBreath,
        rating: 4.2,
        comment: "Helped calm nerves before interview",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 14)),
        pattern: relaxationBreath,
        rating: 4.0,
        comment: "Combined with meditation, very effective",
      ),
    );

    // Sessions from past month
    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 16)),
        pattern: boxBreathing,
        rating: 3.7,
        comment: "Decent session but room was too hot",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 21)),
        pattern: yogaBreath,
        rating: 4.5,
        comment: "Perfect end to yoga practice",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 25)),
        pattern: wimHof,
        rating: 5.0,
        comment: "Amazing energy boost",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 30)),
        pattern: relaxationBreath,
        rating: 4.3,
        comment: "Helped with insomnia",
      ),
    );

    // Older sessions
    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 40)),
        pattern: calmBreath,
        rating: 3.8,
        comment: "Good but noisy environment",
      ),
    );

    sessions.add(
      BreathingSessionData(
        date: now.subtract(const Duration(days: 50)),
        pattern: boxBreathing,
        rating: 4.7,
        comment: "Perfect focus during session",
      ),
    );

    return sessions;
  }

  /// Load all preset data into SQLite
  Future<void> loadAllPresetData() async {
    try {
      // Generate preset data
      final emotionalRecords = await generatePresetEmotionalRecords();
      final breathingSessions = await generatePresetBreathingSessions();

      // Insert emotional records
      for (final record in emotionalRecords) {
        await _sqliteHelper.insertEmotionalRecord(record);
        logger.i("Inserted preset emotional record: ${record.description}");
      }

      // Insert breathing sessions
      for (final session in breathingSessions) {
        await _sqliteHelper.insertBreathingSession(session);
        logger.i(
          "Inserted preset breathing session with rating: ${session.rating}",
        );
      }

      logger.i(
        "Successfully loaded all preset data: ${emotionalRecords.length} emotional records, ${breathingSessions.length} breathing sessions",
      );
    } catch (e) {
      logger.e("Failed to load preset data: $e");
      rethrow;
    }
  }
}
