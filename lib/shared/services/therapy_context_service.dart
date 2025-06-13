import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/therapy_message.dart';
import '../models/emotional_record.dart';
import '../models/user_profile.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TherapyContextService {
  static const int _maxContextMessages = 6;
  static const int _maxEmotionalRecords = 5;

  String generateSystemPrompt(String? historyPreference) {
    final buffer = StringBuffer();

    // Core system prompt - kept minimal
    buffer.write(
      """You are a professional therapist. Be concise (1-2 paragraphs). Focus on actionable guidance.
Key rules:
1. Only address mental health topics
2. Be empathetic but direct
3. Prioritize recent context
4. Give specific, actionable advice
5. Reference past insights when relevant""",
    );

    // Add context preference
    if (historyPreference == "No history needed") {
      buffer.write("\nFocus only on current conversation.");
    } else if (historyPreference == "Last week") {
      buffer.write("\nReference patterns from past week.");
    } else if (historyPreference == "Last month") {
      buffer.write("\nConsider monthly patterns.");
    }

    return buffer.toString();
  }

  String compressUserContext(UserProfile? profile) {
    if (profile == null) return "";

    final buffer = StringBuffer();
    // Only include essential profile information
    if (profile.name != null) buffer.write("Name: ${profile.name}. ");
    if (profile.age != null) buffer.write("Age: ${profile.age}. ");
    if (profile.personalityType != null)
      buffer.write("Type: ${profile.personalityType}. ");

    return buffer.toString();
  }

  String compressEmotionalRecords(
    List<EmotionalRecord> records,
    String? historyPreference,
  ) {
    if (records.isEmpty) return "";

    final now = DateTime.now();
    final filteredRecords =
        records.where((record) {
          if (historyPreference == "Last week") {
            return now.difference(record.date).inDays <= 7;
          } else if (historyPreference == "Last month") {
            return now.difference(record.date).inDays <= 30;
          }
          return false;
        }).toList();

    if (historyPreference == "No history needed" || filteredRecords.isEmpty) {
      return "";
    }

    // Sort by date and take most recent records
    filteredRecords.sort((a, b) => b.date.compareTo(a.date));
    final recentRecords = filteredRecords.take(_maxEmotionalRecords).toList();

    final buffer = StringBuffer("Recent emotions: ");
    for (final record in recentRecords) {
      buffer.write("${record.emotion.name} (${record.description}), ");
    }

    return buffer.toString();
  }

  List<Map<String, String>> compressConversationHistory(
    List<TherapyMessage> messages,
  ) {
    if (messages.isEmpty) return [];

    // Take only the most recent messages
    final recentMessages =
        messages.length > _maxContextMessages
            ? messages.sublist(messages.length - _maxContextMessages)
            : messages;

    return recentMessages.map((msg) {
      return {'role': msg.role, 'content': msg.content};
    }).toList();
  }

  Map<String, dynamic> generateEfficientContext({
    required UserProfile? userProfile,
    required List<EmotionalRecord> emotionalRecords,
    required List<TherapyMessage> conversationHistory,
    required String currentMessage,
  }) {
    final historyPreference = userProfile?.therapyChatHistoryPreference;

    return {
      'system': generateSystemPrompt(historyPreference),
      'user_context': compressUserContext(userProfile),
      'emotional_context': compressEmotionalRecords(
        emotionalRecords,
        historyPreference,
      ),
      'conversation': compressConversationHistory(conversationHistory),
      'current_message': currentMessage,
    };
  }

  int estimateTokenCount(String text) {
    // Rough estimation: ~4 characters per token
    return (text.length / 4).ceil();
  }

  bool shouldIncludeHistory(String? historyPreference, DateTime messageDate) {
    if (historyPreference == null || historyPreference == "No history needed") {
      return false;
    }

    final now = DateTime.now();
    final daysDifference = now.difference(messageDate).inDays;

    if (historyPreference == "Last week") {
      return daysDifference <= 7;
    } else if (historyPreference == "Last month") {
      return daysDifference <= 30;
    }

    return false;
  }
}

// Provider for TherapyContextService
final therapyContextServiceProvider = Provider<TherapyContextService>((ref) {
  return TherapyContextService();
});
