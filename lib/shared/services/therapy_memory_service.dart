import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/therapy_message.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Service to manage persistent conversation history for therapy chats
class TherapyMemoryService {
  static const String _therapyHistoryKey = 'therapy_history';
  static const int _maxMessagesToKeep = 20; // Keep last 20 messages for context

  /// Save the conversation history to persistent storage
  Future<void> saveConversationHistory(List<TherapyMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Keep only the last _maxMessagesToKeep messages to prevent excessive memory usage
      final messagesToSave =
          messages.length > _maxMessagesToKeep
              ? messages.sublist(messages.length - _maxMessagesToKeep)
              : messages;

      final jsonList =
          messagesToSave.map((msg) => jsonEncode(msg.toMap())).toList();
      await prefs.setStringList(_therapyHistoryKey, jsonList);
      logger.i(
        'Therapy conversation history saved: ${jsonList.length} messages',
      );
    } catch (e) {
      logger.e('Failed to save therapy conversation history: $e');
      throw Exception('Failed to save therapy conversation history');
    }
  }

  /// Load the conversation history from persistent storage
  Future<List<TherapyMessage>> getConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_therapyHistoryKey);

      if (jsonList == null || jsonList.isEmpty) {
        logger.i('No therapy conversation history found');
        return [];
      }

      final messages =
          jsonList.map((jsonString) {
            final map = jsonDecode(jsonString) as Map<String, dynamic>;
            return TherapyMessage.fromMap(map);
          }).toList();

      logger.i('Loaded ${messages.length} therapy conversation messages');
      return messages;
    } catch (e) {
      logger.e('Failed to load therapy conversation history: $e');
      return [];
    }
  }

  /// Clear the conversation history
  Future<void> clearConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_therapyHistoryKey);
      logger.i('Therapy conversation history cleared');
    } catch (e) {
      logger.e('Failed to clear therapy conversation history: $e');
      throw Exception('Failed to clear therapy conversation history');
    }
  }

  /// Add a message to the conversation history and save
  Future<List<TherapyMessage>> addMessage(TherapyMessage message) async {
    final history = await getConversationHistory();
    history.add(message);
    await saveConversationHistory(history);
    return history;
  }
}

// Provider for TherapyMemoryService
final therapyMemoryServiceProvider = Provider<TherapyMemoryService>((ref) {
  return TherapyMemoryService();
});

// StateNotifierProvider for therapy conversation history
class TherapyMemoryNotifier extends StateNotifier<List<TherapyMessage>> {
  final TherapyMemoryService _service;

  TherapyMemoryNotifier(this._service) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _service.getConversationHistory();
    state = history;
  }

  Future<void> addUserMessage(String content) async {
    final message = TherapyMessage.fromUser(content);
    state = [...state, message];
    await _service.saveConversationHistory(state);
  }

  Future<void> addAssistantMessage(String content) async {
    final message = TherapyMessage.fromAssistant(content);
    state = [...state, message];
    await _service.saveConversationHistory(state);
  }

  Future<void> clearHistory() async {
    await _service.clearConversationHistory();
    state = [];
  }
}

final therapyMemoryProvider =
    StateNotifierProvider<TherapyMemoryNotifier, List<TherapyMessage>>((ref) {
      final service = ref.watch(therapyMemoryServiceProvider);
      return TherapyMemoryNotifier(service);
    });
