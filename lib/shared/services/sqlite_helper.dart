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
      version: 4, // Increment version for schema changes
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
      },
    );
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
    final List<Map<String, dynamic>> maps = await db.query(
      'breathing_patterns',
    );
    return maps.map((map) => BreathingPattern.fromMap(map)).toList();
  }
}
