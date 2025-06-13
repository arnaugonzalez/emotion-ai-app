import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/ai_conversation_memory.dart';
import '../repositories/ai_memory_repository.dart';
import 'sqlite_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SQLiteAIMemoryRepository implements AIMemoryRepository {
  final SQLiteHelper _sqliteHelper;
  final String _openAIApiKey;

  SQLiteAIMemoryRepository(this._sqliteHelper, this._openAIApiKey);

  @override
  Future<void> saveMemory(AIConversationMemory memory) async {
    final db = await _sqliteHelper.database;
    await db.insert(
      'ai_conversation_memories',
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AIConversationMemory>> getMemoriesForConversation(
    String conversationId,
  ) async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_conversation_memories',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return AIConversationMemory.fromMap(maps[i]);
    });
  }

  @override
  Future<List<AIConversationMemory>> getAllMemories() async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_conversation_memories',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return AIConversationMemory.fromMap(maps[i]);
    });
  }

  @override
  Future<void> deleteMemory(int id) async {
    final db = await _sqliteHelper.database;
    await db.delete(
      'ai_conversation_memories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAllMemories() async {
    final db = await _sqliteHelper.database;
    await db.delete('ai_conversation_memories');
  }

  @override
  Future<String> generateConversationSummary(List<String> messages) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Please provide a brief summary of the following conversation.',
            },
            {'role': 'user', 'content': messages.join('\n')},
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        logger.e('Failed to generate summary: ${response.statusCode}');
        return 'Failed to generate summary';
      }
    } catch (e) {
      logger.e('Error generating summary: $e');
      return 'Error generating summary';
    }
  }
}
