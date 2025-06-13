import 'package:flutter/foundation.dart';

class DailyTokenUsage {
  final int? id;
  final String userId;
  final DateTime date;
  final int promptTokens;
  final int completionTokens;
  final double costInCents;

  DailyTokenUsage({
    this.id,
    required this.userId,
    required this.date,
    required this.promptTokens,
    required this.completionTokens,
    required this.costInCents,
  });

  int get totalTokens => promptTokens + completionTokens;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String().split('T')[0], // Store only the date part
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
      'costInCents': costInCents,
    };
  }

  factory DailyTokenUsage.fromMap(Map<String, dynamic> map) {
    return DailyTokenUsage(
      id: map['id'] as int?,
      userId: map['userId'],
      date: DateTime.parse(map['date']),
      promptTokens: (map['promptTokens'] as num?)?.toInt() ?? 0,
      completionTokens: (map['completionTokens'] as num?)?.toInt() ?? 0,
      costInCents: (map['costInCents'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DailyTokenUsage copyWith({
    int? id,
    String? userId,
    DateTime? date,
    int? promptTokens,
    int? completionTokens,
    double? costInCents,
  }) {
    return DailyTokenUsage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      costInCents: costInCents ?? this.costInCents,
    );
  }

  @override
  String toString() {
    return 'DailyTokenUsage(id: $id, userId: $userId, date: $date, totalTokens: $totalTokens, costInCents: $costInCents)';
  }
}
