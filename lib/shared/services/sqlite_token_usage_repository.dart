import 'package:sqflite/sqflite.dart';
import '../models/token_usage.dart';
import '../repositories/token_usage_repository.dart';
import 'sqlite_helper.dart';
import 'token_usage_isolate.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SQLiteTokenUsageRepository implements TokenUsageRepository {
  final SQLiteHelper _sqliteHelper;

  SQLiteTokenUsageRepository(this._sqliteHelper);

  @override
  Future<void> saveTokenUsage(TokenUsage usage) async {
    final db = await _sqliteHelper.database;
    await db.insert(
      'token_usage',
      usage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    logger.i('Token usage saved to database: ${usage.toMap()}');
  }

  @override
  Future<void> saveBatchTokenUsage(List<TokenUsage> usages) async {
    final db = await _sqliteHelper.database;
    final batch = db.batch();

    for (final usage in usages) {
      batch.insert(
        'token_usage',
        usage.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<List<TokenUsage>> getAllTokenUsage() async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'token_usage',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return TokenUsage.fromMap(maps[i]);
    });
  }

  @override
  Future<TokenUsage> getTotalUsage() async {
    try {
      final db = await _sqliteHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          COALESCE(MIN(timestamp), DATETIME('now')) as timestamp,
          'all' as model,
          COALESCE(SUM(promptTokens), 0) as promptTokens,
          COALESCE(SUM(completionTokens), 0) as completionTokens,
          COALESCE(SUM(costInCents), 0.0) as costInCents
        FROM token_usage
      ''');

      logger.i('Raw token usage query result: $result');

      if (result.isEmpty) {
        logger.w('No token usage records found, returning default values');
        return TokenUsage(
          timestamp: DateTime.now(),
          model: 'all',
          promptTokens: 0,
          completionTokens: 0,
          costInCents: 0,
        );
      }

      return TokenUsage.fromMap(result.first);
    } catch (e, stackTrace) {
      logger.e(
        'Error getting total token usage',
        error: e,
        stackTrace: stackTrace,
      );
      // Return default values instead of throwing
      return TokenUsage(
        timestamp: DateTime.now(),
        model: 'all',
        promptTokens: 0,
        completionTokens: 0,
        costInCents: 0,
      );
    }
  }

  @override
  Future<void> clearAllUsage() async {
    final db = await _sqliteHelper.database;
    await db.delete('token_usage');
  }

  @override
  Future<double> getTotalCostInCents() async {
    final db = await _sqliteHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(costInCents) as total FROM token_usage',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<bool> hasReachedLimit(bool isUnlimited) async {
    if (isUnlimited) {
      return false; // Never reached limit if unlimited
    }
    final totalTokens = await getTotalTokens();
    final limit = isUnlimited ? 2500000 : 200000;
    return totalTokens >= limit;
  }

  Future<int> getTotalTokens() async {
    final db = await _sqliteHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(promptTokens + completionTokens) as total FROM token_usage',
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> getRemainingTokens(bool isUnlimited) async {
    if (isUnlimited) {
      return 999999999; // Return a large number for unlimited
    }
    final totalTokens = await getTotalTokens();
    final limit = isUnlimited ? 2500000 : 200000;
    return limit - totalTokens;
  }
}
