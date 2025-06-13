import 'dart:io';
import 'dart:async';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emotional_record.dart';
import '../models/user_profile.dart';
import '../models/therapy_message.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/token_usage.dart';
import '../repositories/token_usage_repository.dart';
import '../providers/api_providers.dart';
import 'token_usage_isolate.dart';
import 'therapy_context_service.dart';
import 'token_usage_service.dart';

final logger = Logger();

class OpenAIService {
  final String apiKey;
  final TokenUsageRepository _tokenUsageRepository;
  final TherapyContextService _contextService;
  final TokenUsageService _tokenUsageService;
  static const String baseUrl = 'https://api.openai.com/v1';

  OpenAIService(
    this.apiKey,
    this._tokenUsageRepository,
    this._contextService,
    this._tokenUsageService,
  ) {
    if (apiKey.isEmpty) {
      throw ArgumentError('OpenAI API key cannot be empty');
    }
  }

  // Rough estimation of tokens based on text length
  int _estimateTokens(String text) {
    // OpenAI uses about 4 characters per token on average
    return (text.length / 4).ceil();
  }

  Future<String> getTherapyResponse({
    required UserProfile? userProfile,
    required List<EmotionalRecord> emotionalRecords,
    required String userMessage,
    List<TherapyMessage> conversationHistory = const [],
  }) async {
    if (apiKey.isEmpty) {
      throw Exception(
        'API key not found. Please add your OpenAI API key to the .env file',
      );
    }

    try {
      // Generate efficient context using the context service
      final context = _contextService.generateEfficientContext(
        userProfile: userProfile,
        emotionalRecords: emotionalRecords,
        conversationHistory: conversationHistory,
        currentMessage: userMessage,
      );

      // Estimate token usage
      final estimatedTokens = _estimateTokens(
        [
          context['system'],
          context['user_context'],
          context['emotional_context'],
          ...context['conversation'].map((m) => m['content']),
          context['current_message'],
        ].join(' '),
      );

      // Check if we have enough tokens
      final canProceed = await _tokenUsageService.canMakeRequest(
        estimatedTokens,
      );
      if (!canProceed) {
        return "I apologize, but you have reached your daily token usage limit. Please try again tomorrow or contact support if you need an increased limit.";
      }

      // Create system message with minimal prompt
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            context['system'],
          ),
        ],
        role: OpenAIChatMessageRole.system,
      );

      // Create context message with compressed user context and emotional context
      final contextMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "${context['user_context']}\n${context['emotional_context']}",
          ),
        ],
        role: OpenAIChatMessageRole.user,
      );

      // Convert compressed conversation history to OpenAI messages
      final previousMessages =
          (context['conversation'] as List<Map<String, String>>)
              .map(
                (msg) => OpenAIChatCompletionChoiceMessageModel(
                  content: [
                    OpenAIChatCompletionChoiceMessageContentItemModel.text(
                      msg['content']!,
                    ),
                  ],
                  role:
                      msg['role'] == 'user'
                          ? OpenAIChatMessageRole.user
                          : OpenAIChatMessageRole.assistant,
                ),
              )
              .toList();

      // Create user message with the current query
      final currentUserMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            context['current_message'],
          ),
        ],
        role: OpenAIChatMessageRole.user,
      );

      // Combine all messages for the API request
      final messages = [
        systemMessage,
        if (context['user_context'].isNotEmpty ||
            context['emotional_context'].isNotEmpty)
          contextMessage,
        ...previousMessages,
        currentUserMessage,
      ];

      // Use dart_openai package to make the request
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: messages,
        temperature: 0.7,
        maxTokens: 150, // Limit response length
      );

      // Extract text content from the response
      final content = chatCompletion.choices.first.message.content;
      if (content != null && content.isNotEmpty && content.first.text != null) {
        // Record token usage
        final usage = chatCompletion.usage;
        await _tokenUsageService.recordTokenUsage(
          usage.promptTokens,
          usage.completionTokens,
          TokenUsage.calculateCost(
            "gpt-3.5-turbo",
            usage.promptTokens,
            usage.completionTokens,
          ),
        );

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

  Future<Map<String, dynamic>> chatCompletion({
    required List<Map<String, String>> messages,
    String model = 'gpt-3.5-turbo',
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    try {
      // Estimate token usage
      final estimatedTokens = messages.fold<int>(
        0,
        (sum, msg) => sum + _estimateTokens(msg['content'] ?? ''),
      );

      // Check if we have enough tokens
      final canProceed = await _tokenUsageService.canMakeRequest(
        estimatedTokens,
      );
      if (!canProceed) {
        throw Exception('Daily token usage limit exceeded');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          if (maxTokens != null) 'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Process token usage in isolate
        final usage = data['usage'];
        final tokenUsageResult = await computeTokenUsageInIsolate(
          TokenUsageIsolateMessage(
            model: model,
            promptTokens: usage['prompt_tokens'],
            completionTokens: usage['completion_tokens'],
          ),
        );

        // Record token usage
        await _tokenUsageService.recordTokenUsage(
          usage['prompt_tokens'],
          usage['completion_tokens'],
          tokenUsageResult.costInCents,
        );

        return data;
      } else {
        final error = jsonDecode(response.body);
        logger.e('OpenAI API error: ${error['error']['message']}');
        throw Exception('OpenAI API error: ${error['error']['message']}');
      }
    } catch (e) {
      logger.e('Error in chat completion: $e');
      rethrow;
    }
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await chatCompletion(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      );

      return response['choices'][0]['message']['content'];
    } catch (e) {
      logger.e('Error generating response: $e');
      return 'Error: Unable to generate response';
    }
  }

  Future<String> continueConversation(
    List<Map<String, String>> conversation,
  ) async {
    try {
      final response = await chatCompletion(messages: conversation);

      return response['choices'][0]['message']['content'];
    } catch (e) {
      logger.e('Error continuing conversation: $e');
      return 'Error: Unable to continue conversation';
    }
  }
}

// Provider for OpenAIService
final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService(
    ref.read(apiKeyProvider),
    ref.read(tokenUsageRepositoryProvider),
    ref.read(therapyContextServiceProvider),
    ref.read(tokenUsageServiceProvider),
  );
});
