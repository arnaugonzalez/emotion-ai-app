import 'package:flutter/material.dart';

enum Emotion { happy, excited, tender, scared, angry, sad, anxious }

extension EmotionExtension on Emotion {
  // Map each emotion to a specific color
  Color get color {
    switch (this) {
      case Emotion.happy:
        return Colors.yellow;
      case Emotion.excited:
        return Colors.orange;
      case Emotion.tender:
        return Colors.pink;
      case Emotion.scared:
        return Colors.purple;
      case Emotion.angry:
        return Colors.red;
      case Emotion.sad:
        return Colors.blue;
      case Emotion.anxious:
        return Colors.teal;
    }
  }

  // Convert Emotion to a string for DynamoDB
  String get name {
    return toString().split('.').last;
  }

  // Convert a string from DynamoDB to an Emotion
  static Emotion fromName(String name) {
    return Emotion.values.firstWhere((e) => e.name == name);
  }
}

class EmotionalRecord {
  final int? id;
  final DateTime date;
  final String source;
  final String description;
  final Emotion emotion;
  final String? customEmotionName;
  final int? customEmotionColor;

  EmotionalRecord({
    this.id,
    required this.date,
    required this.source,
    required this.description,
    required this.emotion,
    this.customEmotionName,
    this.customEmotionColor,
  });

  // Convert to DynamoDB-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'source': source,
      'description': description,
      'emotion': emotion.name,
      'customEmotionName': customEmotionName,
      'customEmotionColor': customEmotionColor,
      'color': emotion.color.toARGB32().toRadixString(16),
    };
  }

  // Create an instance from DynamoDB Map
  factory EmotionalRecord.fromMap(Map<String, dynamic> map) {
    return EmotionalRecord(
      id: map['id'] as int?,
      date: DateTime.parse(map['date']),
      source: map['source'],
      description: map['description'],
      emotion: EmotionExtension.fromName(map['emotion']),
      customEmotionName: map['customEmotionName'] as String?,
      customEmotionColor: map['customEmotionColor'] as int?,
    );
  }
}
