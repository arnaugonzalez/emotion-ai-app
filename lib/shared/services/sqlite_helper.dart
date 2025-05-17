import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/emotional_record.dart';
import '../models/breathing_session_data.dart';
import '../models/breathing_pattern.dart';

class SQLiteHelper {
  static final SQLiteHelper _instance = SQLiteHelper._internal();
  factory SQLiteHelper() => _instance;

  SQLiteHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'emotion_ai.db');

    return await openDatabase(
      path,
      version: 5, // Increment version for schema changes
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE emotional_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            source TEXT,
            description TEXT,
            emotion TEXT,
            color TEXT,
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

        // Insert preset breathing patterns
        await _insertPresetBreathingPatterns(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          // Add breathing_patterns table if upgrading from earlier version
          await db.execute('''
            CREATE TABLE IF NOT EXISTS breathing_patterns (
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

          // Insert preset patterns
          await _insertPresetBreathingPatterns(db);
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
    return maps.map((map) => EmotionalRecord.fromMap(map)).toList();
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
    return maps.map((map) => EmotionalRecord.fromMap(map)).toList();
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
    return maps.map((map) => BreathingSessionData.fromMap(map)).toList();
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
    return maps.map((map) => BreathingSessionData.fromMap(map)).toList();
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
      return maps.map((map) => BreathingPattern.fromMap(map)).toList();
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
}
