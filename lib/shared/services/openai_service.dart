import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emotional_record.dart';
import '../models/user_profile.dart';
import '../models/therapy_message.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final logger = Logger();

class OpenAIService {
  // Initialize OpenAI with API key during service creation
  OpenAIService() {
    final key = apiKey;
    if (key != null && key.isNotEmpty) {
      OpenAI.apiKey = key;
      // Set 15-second timeout for OpenAI requests
      OpenAI.requestsTimeOut = const Duration(seconds: 15);
    }
  }

  String? get apiKey => dotenv.env['OPENAI_API_KEY'];

  String _formatEmotionalRecords(List<EmotionalRecord> records) {
    if (records.isEmpty) {
      return "No emotional records found.";
    }

    final buffer = StringBuffer();
    buffer.write("List of emotions and thoughts recorded from ");
    buffer.write("${records.first.date.toIso8601String().split('T')[0]} ");
    buffer.write("to ${records.last.date.toIso8601String().split('T')[0]}: ");

    for (final record in records) {
      final date = record.date.toIso8601String().split('T')[0];
      buffer.write("[$date]: ${record.emotion.name.toUpperCase()}: ");
      buffer.write("${record.description}; ");
    }

    return buffer.toString();
  }

  String _formatConversationHistory(List<TherapyMessage> messages) {
    if (messages.isEmpty) {
      return "No previous conversation history.";
    }

    final buffer = StringBuffer();
    buffer.write("Recent conversation history: \n");

    for (final message in messages) {
      final formattedDate =
          "${message.timestamp.month}/${message.timestamp.day}/${message.timestamp.year}";
      buffer.write(
        "[$formattedDate] ${message.role == 'user' ? 'Client' : 'Therapist'}: ${message.content}\n",
      );
    }

    return buffer.toString();
  }

  Future<String> getTherapyResponse({
    required UserProfile? userProfile,
    required List<EmotionalRecord> emotionalRecords,
    required String userMessage,
    List<TherapyMessage> conversationHistory = const [],
  }) async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw Exception(
        'API key not found. Please add your OpenAI API key to the .env file',
      );
    }

    try {
      final systemContext = """
You are a professional therapist helping a client understand their emotional patterns.
Be empathetic, supportive, and provide insightful observations based on the client's emotional records and conversation history.
Ask thoughtful questions. Provide actionable advice when appropriate.
Keep responses concise (3-4 paragraphs maximum).
Refer to past conversations when relevant, showing continuity in the therapeutic relationship.
""";

      final userContext =
          userProfile?.toContextString() ??
          "No user profile information provided.";

      final emotionalContext = _formatEmotionalRecords(emotionalRecords);
      final historyContext = _formatConversationHistory(conversationHistory);

      // Create system message
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(systemContext),
        ],
        role: OpenAIChatMessageRole.system,
      );

      // Create context message with user profile, emotional records, and conversation history
      final contextMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "$userContext\n\n$emotionalContext\n\n$historyContext",
          ),
        ],
        role: OpenAIChatMessageRole.user,
      );

      // Add previous messages from conversation history to maintain context
      final previousMessages =
          conversationHistory
              .map(
                (msg) => OpenAIChatCompletionChoiceMessageModel(
                  content: [
                    OpenAIChatCompletionChoiceMessageContentItemModel.text(
                      msg.content,
                    ),
                  ],
                  role:
                      msg.role == 'user'
                          ? OpenAIChatMessageRole.user
                          : OpenAIChatMessageRole.assistant,
                ),
              )
              .toList();

      // Create user message with the current query
      final currentUserMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
        ],
        role: OpenAIChatMessageRole.user,
      );

      // Combine all messages for the API request
      final messages = [
        systemMessage,
        contextMessage,
        ...previousMessages.length > 6
            ? previousMessages.sublist(previousMessages.length - 6)
            : previousMessages,
        currentUserMessage,
      ];

      // Use dart_openai package to make the request
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini", // Use gpt-4o-mini or appropriate model
        messages: messages,
        temperature: 0.7,
      );

      // Extract text content from the response, handling potential null case
      final content = chatCompletion.choices.first.message.content;
      if (content != null && content.isNotEmpty && content.first.text != null) {
        return content.first.text!;
      }
      return "No response received from the AI assistant.";
    } on RequestFailedException catch (e) {
      logger.e('OpenAI API error: ${e.message}');
      throw Exception('Failed to get response from OpenAI: ${e.message}');
    } on SocketException catch (e) {
      logger.e('Network connection error: $e');
      if (e.toString().contains('Failed host lookup')) {
        return "Network error: Unable to reach OpenAI servers. Please check your internet connection and make sure the API key is correctly set up.";
      }
      return "I'm unable to respond right now due to network connectivity issues. Please check your internet connection and try again.";
    } on TimeoutException catch (e) {
      logger.e('Connection timed out: $e');
      return "I'm unable to respond right now because the connection timed out. Please try again later.";
    } catch (e) {
      logger.e('Error getting therapy response: $e');
      return "I'm sorry, I encountered an unexpected error. Please try again later.";
    }
  }
}

// Provider for OpenAIService
final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});
