import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/emotional_record.dart';
import '../models/breathing_session_data.dart';
import '../models/breathing_pattern.dart';
import '../models/custom_emotion.dart';
import 'package:logger/logger.dart';
import '../models/daily_token_usage.dart';

final logger = Logger();

// Isolate functions
Future<List<EmotionalRecord>> _processEmotionalRecordsInIsolate(
  List<Map<String, dynamic>> maps,
) async {
  return maps.map((map) => EmotionalRecord.fromMap(map)).toList();
}

Future<List<BreathingSessionData>> _processBreathingSessionsInIsolate(
  List<Map<String, dynamic>> maps,
) async {
  return maps.map((map) => BreathingSessionData.fromMap(map)).toList();
}

Future<List<BreathingPattern>> _processBreathingPatternsInIsolate(
  List<Map<String, dynamic>> maps,
) async {
  return maps.map((map) => BreathingPattern.fromMap(map)).toList();
}

Future<List<CustomEmotion>> _processCustomEmotionsInIsolate(
  List<Map<String, dynamic>> maps,
) async {
  return List.generate(maps.length, (i) => CustomEmotion.fromMap(maps[i]));
}

class SQLiteHelper {
  static final SQLiteHelper _instance = SQLiteHelper._internal();
  factory SQLiteHelper() => _instance;

  SQLiteHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emotion_ai.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    logger.i('Initializing database at path: $path');

    return await openDatabase(
      path,
      version: 9, // Increment version for new tables
      onCreate: (db, version) async {
        logger.i('Creating database tables for version $version');

        await db.execute('''
          CREATE TABLE emotional_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            source TEXT,
            description TEXT,
            emotion TEXT,
            color TEXT,
            customEmotionName TEXT,
            customEmotionColor INTEGER,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE breathing_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            pattern TEXT,
            rating REAL,
            comment TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE breathing_patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            inhaleSeconds INTEGER,
            holdSeconds INTEGER,
            exhaleSeconds INTEGER,
            cycles INTEGER,
            restSeconds INTEGER,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE custom_emotions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            color INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE ai_conversation_memories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            conversationId TEXT,
            summary TEXT,
            context TEXT,
            tokensUsed INTEGER
          )
        ''');
        logger.i('Creating token_usage table');
        await db.execute('''
          CREATE TABLE token_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            model TEXT,
            promptTokens INTEGER,
            completionTokens INTEGER,
            costInCents REAL
          )
        ''');
        logger.i('Creating daily_token_usage table');
        await db.execute('''
          CREATE TABLE daily_token_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            date TEXT NOT NULL,
            promptTokens INTEGER NOT NULL DEFAULT 0,
            completionTokens INTEGER NOT NULL DEFAULT 0,
            costInCents REAL NOT NULL DEFAULT 0,
            UNIQUE(userId, date)
          )
        ''');
        logger.i('Daily token usage table created successfully');

        // Insert preset breathing patterns
        await _insertPresetBreathingPatterns(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        logger.i('Upgrading database from version $oldVersion to $newVersion');

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS custom_emotions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              color INTEGER
            )
          ''');
        }
        if (oldVersion < 7) {
          // Add new columns for custom emotions
          await db.execute('''
            ALTER TABLE emotional_records
            ADD COLUMN customEmotionName TEXT;
          ''');
          await db.execute('''
            ALTER TABLE emotional_records
            ADD COLUMN customEmotionColor INTEGER;
          ''');
        }
        if (oldVersion < 8) {
          logger.i(
            'Upgrading to version 8: Adding AI memory and token usage tables',
          );
          // Add new tables for AI memory and token usage
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ai_conversation_memories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT,
              conversationId TEXT,
              summary TEXT,
              context TEXT,
              tokensUsed INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS token_usage (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT,
              model TEXT,
              promptTokens INTEGER,
              completionTokens INTEGER,
              costInCents REAL
            )
          ''');
          logger.i('AI memory and token usage tables created successfully');
        }
        if (oldVersion < 9) {
          logger.i('Upgrading to version 9: Adding daily token usage table');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS daily_token_usage (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId TEXT NOT NULL,
              date TEXT NOT NULL,
              promptTokens INTEGER NOT NULL DEFAULT 0,
              completionTokens INTEGER NOT NULL DEFAULT 0,
              costInCents REAL NOT NULL DEFAULT 0,
              UNIQUE(userId, date)
            )
          ''');
        }
      },
    );
  }

  Future<void> _insertPresetBreathingPatterns(Database db) async {
    // Define preset patterns
    final presets = [
      {
        'name': '4-7-8 Relaxation Breath',
        'inhaleSeconds': 4,
        'holdSeconds': 7,
        'exhaleSeconds': 8,
        'cycles': 4,
        'restSeconds': 2,
        'synced': 1,
      },
      {
        'name': 'Box Breathing',
        'inhaleSeconds': 4,
        'holdSeconds': 4,
        'exhaleSeconds': 4,
        'cycles': 4,
        'restSeconds': 4,
        'synced': 1,
      },
      {
        'name': 'Calm Breath',
        'inhaleSeconds': 3,
        'holdSeconds': 0,
        'exhaleSeconds': 6,
        'cycles': 5,
        'restSeconds': 1,
        'synced': 1,
      },
      {
        'name': 'Wim Hof Method',
        'inhaleSeconds': 2,
        'holdSeconds': 0,
        'exhaleSeconds': 2,
        'cycles': 30,
        'restSeconds': 0,
        'synced': 1,
      },
      {
        'name': 'Deep Yoga Breath',
        'inhaleSeconds': 5,
        'holdSeconds': 2,
        'exhaleSeconds': 5,
        'cycles': 10,
        'restSeconds': 1,
        'synced': 1,
      },
    ];

    // Insert each preset
    for (final pattern in presets) {
      await db.insert('breathing_patterns', pattern);
    }
  }

  // EmotionalRecord CRUD Operations
  Future<void> insertEmotionalRecord(EmotionalRecord record) async {
    final db = await database;
    await db.insert(
      'emotional_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EmotionalRecord>> getEmotionalRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('emotional_records');
    return compute(_processEmotionalRecordsInIsolate, maps);
  }

  Future<void> deleteAllEmotionalRecords() async {
    final db = await database;
    await db.delete('emotional_records');
  }

  Future<List<EmotionalRecord>> getUnsyncedEmotionalRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emotional_records',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return compute(_processEmotionalRecordsInIsolate, maps);
  }

  Future<void> markEmotionalRecordAsSynced(int id) async {
    final db = await database;
    await db.update(
      'emotional_records',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // BreathingSession CRUD Operations
  Future<void> insertBreathingSession(BreathingSessionData session) async {
    final db = await database;
    await db.insert(
      'breathing_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BreathingSessionData>> getBreathingSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'breathing_sessions',
    );
    return compute(_processBreathingSessionsInIsolate, maps);
  }

  Future<void> deleteAllBreathingSessions() async {
    final db = await database;
    await db.delete('breathing_sessions');
  }

  Future<List<BreathingSessionData>> getUnsyncedBreathingSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'breathing_sessions',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return compute(_processBreathingSessionsInIsolate, maps);
  }

  Future<void> markBreathingSessionAsSynced(int id) async {
    final db = await database;
    await db.update(
      'breathing_sessions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // BreathingPattern CRUD Operations
  Future<List<BreathingPattern>> getBreathingPatterns() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'breathing_patterns',
      );
      return compute(_processBreathingPatternsInIsolate, maps);
    } catch (e) {
      // Table may not exist yet if older version
      return [];
    }
  }

  Future<void> insertBreathingPattern(BreathingPattern pattern) async {
    final db = await database;

    // Check if table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='breathing_patterns'",
    );

    if (tables.isEmpty) {
      // Create table if it doesn't exist
      await db.execute('''
        CREATE TABLE breathing_patterns (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          inhaleSeconds INTEGER,
          holdSeconds INTEGER,
          exhaleSeconds INTEGER,
          cycles INTEGER,
          restSeconds INTEGER,
          synced INTEGER DEFAULT 0
        )
      ''');
    }

    await db.insert('breathing_patterns', {
      'name': pattern.name,
      'inhaleSeconds': pattern.inhaleSeconds,
      'holdSeconds': pattern.holdSeconds,
      'exhaleSeconds': pattern.exhaleSeconds,
      'cycles': pattern.cycles,
      'restSeconds': pattern.restSeconds,
      'synced': 0, // Not synced by default
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markBreathingPatternAsSynced(int id) async {
    final db = await database;
    await db.update(
      'breathing_patterns',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedBreathingPatterns() async {
    final db = await database;
    return await db.query(
      'breathing_patterns',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  // Custom Emotions CRUD Operations
  Future<int> insertCustomEmotion(CustomEmotion emotion) async {
    final db = await database;
    return await db.insert('custom_emotions', emotion.toMap());
  }

  Future<List<CustomEmotion>> getCustomEmotions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('custom_emotions');
    return compute(_processCustomEmotionsInIsolate, maps);
  }

  Future<int> updateCustomEmotion(CustomEmotion emotion) async {
    final db = await database;
    return await db.update(
      'custom_emotions',
      emotion.toMap(),
      where: 'id = ?',
      whereArgs: [emotion.id],
    );
  }

  Future<int> deleteCustomEmotion(int id) async {
    final db = await database;
    return await db.delete('custom_emotions', where: 'id = ?', whereArgs: [id]);
  }

  // Daily token usage methods
  Future<DailyTokenUsage> getDailyTokenUsage(
    String userId,
    DateTime date,
  ) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final result = await db.query(
      'daily_token_usage',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, dateStr],
    );

    if (result.isEmpty) {
      return DailyTokenUsage(
        userId: userId,
        date: date,
        promptTokens: 0,
        completionTokens: 0,
        costInCents: 0,
      );
    }

    return DailyTokenUsage.fromMap(result.first);
  }

  Future<void> updateDailyTokenUsage(DailyTokenUsage usage) async {
    final db = await database;
    await db.insert(
      'daily_token_usage',
      usage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addTokenUsage(
    String userId,
    int promptTokens,
    int completionTokens,
    double costInCents,
  ) async {
    final db = await database;
    final today = DateTime.now();
    final dateStr = today.toIso8601String().split('T')[0];

    // Use a transaction to ensure atomicity
    await db.transaction((txn) async {
      // Get current usage
      final result = await txn.query(
        'daily_token_usage',
        where: 'userId = ? AND date = ?',
        whereArgs: [userId, dateStr],
      );

      if (result.isEmpty) {
        // Create new record
        await txn.insert('daily_token_usage', {
          'userId': userId,
          'date': dateStr,
          'promptTokens': promptTokens,
          'completionTokens': completionTokens,
          'costInCents': costInCents,
        });
      } else {
        // Update existing record
        final current = DailyTokenUsage.fromMap(result.first);
        await txn.update(
          'daily_token_usage',
          {
            'promptTokens': current.promptTokens + promptTokens,
            'completionTokens': current.completionTokens + completionTokens,
            'costInCents': current.costInCents + costInCents,
          },
          where: 'userId = ? AND date = ?',
          whereArgs: [userId, dateStr],
        );
      }
    });
  }

  Future<void> cleanupOldTokenUsage(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final cutoffDateStr = cutoffDate.toIso8601String().split('T')[0];

    await db.delete(
      'daily_token_usage',
      where: 'date < ?',
      whereArgs: [cutoffDateStr],
    );
  }
}
