import 'package:flutter/foundation.dart';

class AIConversationMemory {
  final int? id;
  final DateTime timestamp;
  final String conversationId;
  final String summary;
  final Map<String, dynamic> context;
  final int tokensUsed;

  AIConversationMemory({
    this.id,
    required this.timestamp,
    required this.conversationId,
    required this.summary,
    required this.context,
    required this.tokensUsed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'conversationId': conversationId,
      'summary': summary,
      'context': context.toString(), // Store as string for SQLite
      'tokensUsed': tokensUsed,
    };
  }

  factory AIConversationMemory.fromMap(Map<String, dynamic> map) {
    return AIConversationMemory(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp']),
      conversationId: map['conversationId'],
      summary: map['summary'],
      context: _parseContext(map['context']),
      tokensUsed: map['tokensUsed'],
    );
  }

  static Map<String, dynamic> _parseContext(String contextString) {
    try {
      // Basic string to map conversion - you might want to use a proper JSON parser
      final cleanString = contextString
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll(' ', '');
      final pairs = cleanString.split(',');
      final map = <String, dynamic>{};

      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          map[keyValue[0]] = keyValue[1];
        }
      }

      return map;
    } catch (e) {
      debugPrint('Error parsing context: $e');
      return {};
    }
  }
}
