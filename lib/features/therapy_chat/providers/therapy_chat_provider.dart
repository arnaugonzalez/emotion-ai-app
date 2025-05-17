import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../../../shared/services/sqlite_helper.dart';
import '../../../shared/services/openai_service.dart';
import '../../../shared/services/user_profile_service.dart';
import '../../../shared/services/therapy_memory_service.dart';
import '../../../shared/models/therapy_message.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({this.messages = const [], this.isLoading = false, this.error});

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TherapyChatNotifier extends StateNotifier<ChatState> {
  final OpenAIService _openAIService;
  final SQLiteHelper _sqliteHelper;
  final UserProfileService _profileService;
  final TherapyMemoryService _memoryService;

  TherapyChatNotifier(
    this._openAIService,
    this._sqliteHelper,
    this._profileService,
    this._memoryService,
  ) : super(ChatState()) {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Load previous conversation history
    final history = await _memoryService.getConversationHistory();

    // If we have history, convert it to ChatMessages for UI display
    if (history.isNotEmpty) {
      final savedMessages =
          history.map((msg) {
            return ChatMessage(
              text: msg.content,
              type:
                  msg.role == 'user' ? MessageType.user : MessageType.therapist,
              timestamp: msg.timestamp,
            );
          }).toList();

      state = state.copyWith(messages: savedMessages);
      return;
    }

    // Otherwise, add initial greeting message for new users
    final initialMessages = [
      ChatMessage(
        text:
            "Hello, I'm here to help you process your emotions and reflect on your well-being. How can I support you today?",
        type: MessageType.therapist,
      ),
    ];

    state = state.copyWith(messages: initialMessages);

    // Save initial message to memory
    await _memoryService.addMessage(
      TherapyMessage(content: initialMessages.first.text, role: 'assistant'),
    );

    // Automatically send the initial question
    await sendMessage(
      "How do you see me lately? What can I improve in my day to day?",
    );
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

    // Save user message to persistent memory
    await _memoryService.addMessage(
      TherapyMessage(content: text, role: 'user'),
    );

    try {
      // Get user profile
      final userProfile = await _profileService.getProfile();

      // Get emotional records
      final emotionalRecords = await _sqliteHelper.getEmotionalRecords();

      // Sort records by date
      emotionalRecords.sort((a, b) => a.date.compareTo(b.date));

      // Get conversation history for context
      final conversationHistory = await _memoryService.getConversationHistory();

      // Get the therapy response with conversation history
      final response = await _openAIService.getTherapyResponse(
        userProfile: userProfile,
        emotionalRecords: emotionalRecords,
        userMessage: text,
        conversationHistory: conversationHistory,
      );

      // Add therapist response to UI state
      final therapistMessage = ChatMessage(
        text: response,
        type: MessageType.therapist,
      );

      state = state.copyWith(
        messages: [...state.messages, therapistMessage],
        isLoading: false,
      );

      // Save assistant response to persistent memory
      await _memoryService.addMessage(
        TherapyMessage(content: response, role: 'assistant'),
      );
    } catch (e) {
      logger.e('Error sending message: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get response. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> clearConversationHistory() async {
    await _memoryService.clearConversationHistory();

    // Add initial greeting message after clearing
    final initialMessages = [
      ChatMessage(
        text:
            "Hello, I'm here to help you process your emotions and reflect on your well-being. How can I support you today?",
        type: MessageType.therapist,
      ),
    ];

    state = state.copyWith(messages: initialMessages);

    // Save initial message to memory
    await _memoryService.addMessage(
      TherapyMessage(content: initialMessages.first.text, role: 'assistant'),
    );
  }
}

// Providers
final therapyChatProvider =
    StateNotifierProvider<TherapyChatNotifier, ChatState>((ref) {
      final openAIService = ref.watch(openAIServiceProvider);
      final sqliteHelper = SQLiteHelper();
      final profileService = ref.watch(userProfileServiceProvider);
      final memoryService = ref.watch(therapyMemoryServiceProvider);

      return TherapyChatNotifier(
        openAIService,
        sqliteHelper,
        profileService,
        memoryService,
      );
    });
