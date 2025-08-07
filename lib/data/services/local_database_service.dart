import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../models/emotional_record.dart';

/// Local SQLite database service for offline storage and sync
class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;
  final Logger _logger = Logger();

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the local SQLite database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'emotionai_local.db');

    _logger.i('🗄️ Initializing local database at: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    _logger.i('📋 Creating local database tables...');

    // Emotional records table
    await db.execute('''
      CREATE TABLE emotional_records (
        id TEXT PRIMARY KEY,
        emotion TEXT NOT NULL,
        intensity INTEGER NOT NULL,
        triggers TEXT,
        notes TEXT,
        context_data TEXT,
        tags TEXT,
        tag_confidence REAL,
        processed_for_tags INTEGER DEFAULT 0,
        recorded_at TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        sync_attempts INTEGER DEFAULT 0,
        last_sync_attempt TEXT,
        local_only INTEGER DEFAULT 0
      )
    ''');

    // Breathing sessions table
    await db.execute('''
      CREATE TABLE breathing_sessions (
        id TEXT PRIMARY KEY,
        pattern_name TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        completed INTEGER DEFAULT 0,
        effectiveness_rating INTEGER,
        notes TEXT,
        session_data TEXT,
        tags TEXT,
        tag_confidence REAL,
        processed_for_tags INTEGER DEFAULT 0,
        started_at TEXT,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        sync_attempts INTEGER DEFAULT 0,
        last_sync_attempt TEXT,
        local_only INTEGER DEFAULT 0
      )
    ''');

    // Sync queue table for failed uploads
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER DEFAULT 0,
        last_attempt TEXT,
        error_message TEXT
      )
    ''');

    _logger.i('✅ Local database tables created successfully');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    _logger.i('🔄 Upgrading database from version $oldVersion to $newVersion');
    // Handle future schema migrations here
  }

  /// Save emotional record locally
  Future<String> saveEmotionalRecordLocal(EmotionalRecord record) async {
    final db = await database;

    try {
      final recordData = {
        'id': record.id,
        'emotion': record.emotion,
        'intensity': record.intensity,
        'triggers': record.triggers.join(','),
        'notes': record.notes,
        'context_data': record.contextData?.toString(),
        'tags': record.tags.join(','),
        'tag_confidence': record.tagConfidence,
        'processed_for_tags': record.processedForTags ? 1 : 0,
        'recorded_at': record.recordedAt?.toIso8601String(),
        'created_at': record.createdAt.toIso8601String(),
        'synced': 0, // Not synced yet
        'sync_attempts': 0,
        'local_only': 0,
      };

      await db.insert('emotional_records', recordData);
      _logger.i('💾 Saved emotional record locally: ${record.id}');

      return record.id ?? '';
    } catch (e) {
      _logger.e('❌ Failed to save emotional record locally: $e');
      rethrow;
    }
  }

  /// Get all unsynced emotional records
  Future<List<EmotionalRecord>> getUnsyncedEmotionalRecords() async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'emotional_records',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      return maps.map((map) => _mapToEmotionalRecord(map)).toList();
    } catch (e) {
      _logger.e('❌ Failed to get unsynced emotional records: $e');
      return [];
    }
  }

  /// Mark emotional record as synced
  Future<void> markEmotionalRecordSynced(String recordId) async {
    final db = await database;

    try {
      await db.update(
        'emotional_records',
        {'synced': 1, 'last_sync_attempt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [recordId],
      );

      _logger.i('✅ Marked emotional record as synced: $recordId');
    } catch (e) {
      _logger.e('❌ Failed to mark emotional record as synced: $e');
    }
  }

  /// Update sync attempt for emotional record
  Future<void> updateSyncAttempt(String recordId, String errorMessage) async {
    final db = await database;

    try {
      await db.rawUpdate(
        '''
        UPDATE emotional_records 
        SET sync_attempts = sync_attempts + 1,
            last_sync_attempt = ?
        WHERE id = ?
      ''',
        [DateTime.now().toIso8601String(), recordId],
      );

      _logger.w(
        '⚠️ Updated sync attempt for record: $recordId - $errorMessage',
      );
    } catch (e) {
      _logger.e('❌ Failed to update sync attempt: $e');
    }
  }

  /// Get all emotional records (local and synced)
  Future<List<EmotionalRecord>> getAllEmotionalRecords() async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'emotional_records',
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToEmotionalRecord(map)).toList();
    } catch (e) {
      _logger.e('❌ Failed to get all emotional records: $e');
      return [];
    }
  }

  /// Convert database map to EmotionalRecord
  EmotionalRecord _mapToEmotionalRecord(Map<String, dynamic> map) {
    return EmotionalRecord(
      id: map['id'],
      source: 'local', // Default source for local records
      description: map['notes'] ?? '', // Use notes as description fallback
      emotion: map['emotion'],
      color: 0, // Default color value
      intensity: map['intensity'],
      triggers: map['triggers']?.split(',') ?? [],
      notes: map['notes'],
      contextData:
          map['context_data'] != null ? {'raw': map['context_data']} : null,
      tags: map['tags']?.split(',') ?? [],
      tagConfidence: map['tag_confidence'],
      processedForTags: map['processed_for_tags'] == 1,
      recordedAt:
          map['recorded_at'] != null
              ? DateTime.parse(map['recorded_at'])
              : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final db = await database;

    try {
      final syncedCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM emotional_records WHERE synced = 1',
            ),
          ) ??
          0;

      final unsyncedCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM emotional_records WHERE synced = 0',
            ),
          ) ??
          0;

      final failedCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM emotional_records WHERE sync_attempts > 3',
            ),
          ) ??
          0;

      return {
        'synced': syncedCount,
        'unsynced': unsyncedCount,
        'failed': failedCount,
        'total': syncedCount + unsyncedCount,
      };
    } catch (e) {
      _logger.e('❌ Failed to get sync stats: $e');
      return {'synced': 0, 'unsynced': 0, 'failed': 0, 'total': 0};
    }
  }

  /// Clear old synced records (keep last 100)
  Future<void> cleanupOldRecords() async {
    final db = await database;

    try {
      await db.rawDelete('''
        DELETE FROM emotional_records 
        WHERE synced = 1 
        AND id NOT IN (
          SELECT id FROM emotional_records 
          WHERE synced = 1 
          ORDER BY created_at DESC 
          LIMIT 100
        )
      ''');

      _logger.i('🧹 Cleaned up old synced records');
    } catch (e) {
      _logger.e('❌ Failed to cleanup old records: $e');
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.i('🔒 Local database connection closed');
    }
  }
}
