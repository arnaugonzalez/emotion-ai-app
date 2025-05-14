import 'dart:convert';
import 'breathing_pattern.dart';

class BreathingSessionData {
  final int? id; // Add this field
  final DateTime date;
  final BreathingPattern pattern;
  final double rating;
  final String comment;

  BreathingSessionData({
    this.id, // Add this parameter
    required this.date,
    required this.pattern,
    required this.rating,
    required this.comment,
  });

  // Convert to SQLite-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include id
      'date': date.toIso8601String(),
      'pattern': jsonEncode(pattern.toMap()), // Store pattern as JSON string
      'rating': rating,
      'comment': comment,
    };
  }

  // Create an instance from SQLite Map
  factory BreathingSessionData.fromMap(Map<String, dynamic> map) {
    return BreathingSessionData(
      id: map['id'] as int?, // Map the id
      date: DateTime.parse(map['date']),
      pattern: BreathingPattern.fromMap(jsonDecode(map['pattern'])),
      rating: map['rating'] as double,
      comment: map['comment'] as String,
    );
  }
}
