import 'dart:isolate';
import '../models/token_usage.dart';

class TokenUsageIsolateMessage {
  final String model;
  final int promptTokens;
  final int completionTokens;

  TokenUsageIsolateMessage({
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
  });
}

class TokenUsageResult {
  final double costInCents;
  final int totalTokens;

  TokenUsageResult({required this.costInCents, required this.totalTokens});
}

Future<TokenUsageResult> computeTokenUsageInIsolate(
  TokenUsageIsolateMessage message,
) async {
  return await Isolate.run(() {
    final cost = TokenUsage.calculateCost(
      message.model,
      message.promptTokens,
      message.completionTokens,
    );

    return TokenUsageResult(
      costInCents: cost,
      totalTokens: message.promptTokens + message.completionTokens,
    );
  });
}

Future<List<TokenUsage>> batchProcessTokenUsage(
  List<TokenUsageIsolateMessage> messages,
) async {
  return await Isolate.run(() {
    return messages.map((msg) {
      final cost = TokenUsage.calculateCost(
        msg.model,
        msg.promptTokens,
        msg.completionTokens,
      );

      return TokenUsage(
        timestamp: DateTime.now(),
        model: msg.model,
        promptTokens: msg.promptTokens,
        completionTokens: msg.completionTokens,
        costInCents: cost,
      );
    }).toList();
  });
}
