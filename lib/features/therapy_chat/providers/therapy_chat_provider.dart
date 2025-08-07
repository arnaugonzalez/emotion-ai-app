import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import 'package:emotion_ai/features/auth/auth_provider.dart';
import 'package:emotion_ai/shared/providers/user_limitations_provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String selectedAgent;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.selectedAgent = 'therapy',
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? selectedAgent,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedAgent: selectedAgent ?? this.selectedAgent,
    );
  }
}

class TherapyChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  TherapyChatNotifier(this._ref) : super(ChatState()) {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Simply add initial greeting message
    final initialMessages = [
      ChatMessage(
        text:
            "Hello, I'm here to help you process your emotions and reflect on your well-being. How can I support you today?",
        type: MessageType.therapist,
      ),
    ];

    state = state.copyWith(messages: initialMessages);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, type: MessageType.user);

    // Add user message to state for UI update
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Send message to backend API
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.sendChatMessage(
        text,
        agentType: state.selectedAgent,
      );

      // Handle crisis detection if present
      if (response.crisisDetected && response.crisisResources != null) {
        final crisisMessage = ChatMessage(
          text:
              '⚠️ CRISIS SUPPORT AVAILABLE:\n${response.crisisResources!.message}\nHotline: ${response.crisisResources!.hotline}',
          type: MessageType.therapist,
        );

        state = state.copyWith(messages: [...state.messages, crisisMessage]);
      }

      // Add therapist response to UI state
      final therapistMessage = ChatMessage(
        text: response.message,
        type: MessageType.therapist,
      );

      state = state.copyWith(
        messages: [...state.messages, therapistMessage],
        isLoading: false,
      );

      // Refresh user limitations after successful message
      _ref.read(userLimitationsProvider.notifier).refreshLimitations();
    } catch (e) {
      logger.e('Error sending message: $e');

      // Handle rate limiting specifically
      if (e.toString().contains('Rate limit') || e.toString().contains('429')) {
        state = state.copyWith(
          isLoading: false,
          error:
              'You have reached your daily usage limit. Please try again tomorrow.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get response. Please try again.',
        );
      }

      // Refresh limitations to get updated status
      _ref.read(userLimitationsProvider.notifier).refreshLimitations();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void changeAgent(String agentType) {
    // Update selected agent and clear messages for fresh start
    final greetingText =
        agentType == 'wellness'
            ? "Hello! I'm your wellness assistant. I'm here to help you with mindfulness, breathing exercises, and general wellness tips. How can I support your well-being today?"
            : "Hello, I'm here to help you process your emotions and reflect on your well-being. How can I support you today?";

    final initialMessages = [
      ChatMessage(text: greetingText, type: MessageType.therapist),
    ];

    state = state.copyWith(selectedAgent: agentType, messages: initialMessages);
  }

  Future<void> clearConversationHistory() async {
    try {
      // Clear agent memory from backend
      final apiService = _ref.read(apiServiceProvider);
      await apiService.clearAgentMemory(state.selectedAgent);

      // Add initial greeting message after clearing
      final greetingText =
          state.selectedAgent == 'wellness'
              ? "Hello! I'm your wellness assistant. I'm here to help you with mindfulness, breathing exercises, and general wellness tips. How can I support your well-being today?"
              : "Hello, I'm here to help you process your emotions and reflect on your well-being. How can I support you today?";

      final initialMessages = [
        ChatMessage(text: greetingText, type: MessageType.therapist),
      ];

      state = state.copyWith(messages: initialMessages);
    } catch (e) {
      logger.e('Error clearing conversation history: $e');
      // Fallback to just clearing UI messages
      final greetingText =
          state.selectedAgent == 'wellness'
              ? "Hello! I'm your wellness assistant. I'm here to help you with mindfulness, breathing exercises, and general wellness tips. How can I support your well-being today?"
              : "Hello, I'm here to help you process your emotions and reflect on your well-being. How can I support you today?";

      final initialMessages = [
        ChatMessage(text: greetingText, type: MessageType.therapist),
      ];

      state = state.copyWith(messages: initialMessages);
    }
  }
}

// Providers
final therapyChatProvider =
    StateNotifierProvider<TherapyChatNotifier, ChatState>((ref) {
      return TherapyChatNotifier(ref);
    });
