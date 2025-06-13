class TokenUsage {
  final int? id;
  final DateTime timestamp;
  final String model; // e.g., 'gpt-4', 'gpt-3.5-turbo'
  final int promptTokens;
  final int completionTokens;
  final double costInCents;

  TokenUsage({
    this.id,
    required this.timestamp,
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
    required this.costInCents,
  });

  int get totalTokens => promptTokens + completionTokens;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
      'costInCents': costInCents,
    };
  }

  factory TokenUsage.fromMap(Map<String, dynamic> map) {
    return TokenUsage(
      id: map['id'] as int?,
      timestamp:
          map['timestamp'] != null
              ? DateTime.parse(map['timestamp'].toString())
              : DateTime.now(),
      model: map['model']?.toString() ?? 'all',
      promptTokens: (map['promptTokens'] as num?)?.toInt() ?? 0,
      completionTokens: (map['completionTokens'] as num?)?.toInt() ?? 0,
      costInCents: (map['costInCents'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static double calculateCost(
    String model,
    int promptTokens,
    int completionTokens,
  ) {
    // Costs in cents per 1K tokens as of March 2024
    const rates = {
      'gpt-4': {'prompt': 3.0, 'completion': 6.0},
      'gpt-3.5-turbo': {'prompt': 0.1, 'completion': 0.2},
    };

    if (!rates.containsKey(model)) {
      throw ArgumentError('Unknown model: $model');
    }

    final promptCost = (promptTokens / 1000) * rates[model]!['prompt']!;
    final completionCost =
        (completionTokens / 1000) * rates[model]!['completion']!;

    return promptCost + completionCost;
  }
}
