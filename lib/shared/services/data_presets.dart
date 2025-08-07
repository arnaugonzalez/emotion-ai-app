import 'package:flutter/material.dart';
import 'package:emotion_ai/data/models/emotional_record.dart';
import 'package:emotion_ai/data/models/breathing_session.dart';
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
        source: "Testing",
        description: "Feeling energized about the app progress",
        emotion: "excited",
        color: Colors.yellow.toARGB32(),
        createdAt: now,
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Morning meditation brought peace",
        emotion: "tender",
        color: Colors.pink.toARGB32(),
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    );

    // Yesterday's records
    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Relaxed evening with friends",
        emotion: "happy",
        color: Colors.green.toARGB32(),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Upset about work deadline being moved up",
        emotion: "angry",
        color: Colors.red.toARGB32(),
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      ),
    );

    // Records from the past week
    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Worried about upcoming presentation",
        emotion: "anxious",
        color: Colors.orange.toARGB32(),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Proud of finishing difficult project",
        emotion: "happy",
        color: Colors.green.toARGB32(),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Morning anxiety about traffic",
        emotion: "anxious",
        color: Colors.orange.toARGB32(),
        createdAt: now.subtract(const Duration(days: 3, hours: 12)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Disappointed with test results",
        emotion: "sad",
        color: Colors.blue.toARGB32(),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Excited about weekend plans",
        emotion: "excited",
        color: Colors.yellow.toARGB32(),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Scared after watching horror movie",
        emotion: "scared",
        color: Colors.purple.toARGB32(),
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Frustrated with slow progress",
        emotion: "angry",
        color: Colors.red.toARGB32(),
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    );

    // Records from 2 weeks ago
    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Proud of fitness achievements",
        emotion: "excited",
        color: Colors.yellow.toARGB32(),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Supported friend through difficult time",
        emotion: "tender",
        color: Colors.pink.toARGB32(),
        createdAt: now.subtract(const Duration(days: 11)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Nervous about doctor's appointment",
        emotion: "anxious",
        color: Colors.orange.toARGB32(),
        createdAt: now.subtract(const Duration(days: 12)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Happy about surprise gift",
        emotion: "happy",
        color: Colors.green.toARGB32(),
        createdAt: now.subtract(const Duration(days: 13)),
      ),
    );

    // Multiple emotions on the same day (two weeks ago)
    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Sad about missed opportunity",
        emotion: "sad",
        color: Colors.blue.toARGB32(),
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Happy about surprise visit",
        emotion: "happy",
        color: Colors.green.toARGB32(),
        createdAt: now.subtract(const Duration(days: 14, hours: 6)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Anxious about tomorrow's meeting",
        emotion: "anxious",
        color: Colors.orange.toARGB32(),
        createdAt: now.subtract(const Duration(days: 14, hours: 12)),
      ),
    );

    // Records from 3-4 weeks ago
    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Excited about new opportunity",
        emotion: "excited",
        color: Colors.yellow.toARGB32(),
        createdAt: now.subtract(const Duration(days: 18)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Terrified of spider in room",
        emotion: "scared",
        color: Colors.purple.toARGB32(),
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Furious after argument",
        emotion: "angry",
        color: Colors.red.toARGB32(),
        createdAt: now.subtract(const Duration(days: 22)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Overwhelmed with workload",
        emotion: "anxious",
        color: Colors.orange.toARGB32(),
        createdAt: now.subtract(const Duration(days: 25)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Melancholic about old memories",
        emotion: "sad",
        color: Colors.blue.toARGB32(),
        createdAt: now.subtract(const Duration(days: 27)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "In love with new project",
        emotion: "tender",
        color: Colors.pink.toARGB32(),
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    );

    // Older records (from past months)
    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Happy after great workout",
        emotion: "happy",
        color: Colors.green.toARGB32(),
        createdAt: now.subtract(const Duration(days: 40)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Felt connected during deep conversation",
        emotion: "tender",
        color: Colors.pink.toARGB32(),
        createdAt: now.subtract(const Duration(days: 45)),
      ),
    );

    records.add(
      EmotionalRecord(
        source: "Testing",
        description: "Thrilled about successful project launch",
        emotion: "excited",
        color: Colors.yellow.toARGB32(),
        createdAt: now.subtract(const Duration(days: 60)),
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

    // Extract pattern names from the list of BreathingPattern objects
    final patternNames = patterns.map((p) => p.name).toList();

    // Find different pattern names
    final boxBreathingName =
        patternNames.contains('Box Breathing')
            ? 'Box Breathing'
            : (patterns.isNotEmpty ? patterns.first.name : '');

    final relaxationBreathName =
        patternNames.contains('4-7-8 Relaxation Breath')
            ? '4-7-8 Relaxation Breath'
            : (patterns.isNotEmpty ? patterns.first.name : '');

    final calmBreathName =
        patternNames.contains('Calm Breath')
            ? 'Calm Breath'
            : (patterns.isNotEmpty ? patterns.first.name : '');

    final wimHofName =
        patternNames.contains('Wim Hof Method')
            ? 'Wim Hof Method'
            : (patterns.isNotEmpty ? patterns.first.name : '');

    final yogaBreathName =
        patternNames.contains('Deep Yoga Breath')
            ? 'Deep Yoga Breath'
            : (patterns.isNotEmpty ? patterns.first.name : '');

    final sessions = <BreathingSessionData>[];

    // Today's sessions
    sessions.add(
      BreathingSessionData(
        pattern: boxBreathingName,
        rating: 4.0,
        comment: "Felt refreshed after this session",
        createdAt: now,
      ),
    );

    // Sessions from the past week
    sessions.add(
      BreathingSessionData(
        pattern: relaxationBreathName,
        rating: 5.0,
        comment: "Really helped with anxiety before presentation",
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: calmBreathName,
        rating: 3.5,
        comment: "Helped a little but still felt stressed",
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: relaxationBreathName,
        rating: 5.0,
        comment: "Really helped with anxiety",
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: yogaBreathName,
        rating: 4.0,
        comment: "Good morning session",
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: boxBreathingName,
        rating: 3.5,
        comment: "Was distracted during session",
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    );

    // Sessions from 2 weeks ago
    sessions.add(
      BreathingSessionData(
        pattern: wimHofName,
        rating: 4.8,
        comment: "Intense but energizing experience",
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: calmBreathName,
        rating: 4.2,
        comment: "Helped calm nerves before interview",
        createdAt: now.subtract(const Duration(days: 12)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: relaxationBreathName,
        rating: 4.0,
        comment: "Combined with meditation, very effective",
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    );

    // Sessions from past month
    sessions.add(
      BreathingSessionData(
        pattern: boxBreathingName,
        rating: 3.7,
        comment: "Decent session but room was too hot",
        createdAt: now.subtract(const Duration(days: 16)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: yogaBreathName,
        rating: 4.5,
        comment: "Perfect end to yoga practice",
        createdAt: now.subtract(const Duration(days: 21)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: wimHofName,
        rating: 5.0,
        comment: "Amazing energy boost",
        createdAt: now.subtract(const Duration(days: 25)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: relaxationBreathName,
        rating: 4.3,
        comment: "Helped with insomnia",
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    );

    // Older sessions
    sessions.add(
      BreathingSessionData(
        pattern: calmBreathName,
        rating: 3.8,
        comment: "Good but noisy environment",
        createdAt: now.subtract(const Duration(days: 40)),
      ),
    );

    sessions.add(
      BreathingSessionData(
        pattern: boxBreathingName,
        rating: 4.7,
        comment: "Perfect focus during session",
        createdAt: now.subtract(const Duration(days: 50)),
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
