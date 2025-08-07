// Legacy compatibility model for BreathingSessionData
// This provides backward compatibility for the existing codebase

class BreathingSessionData {
  final String? id;
  final String pattern;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  BreathingSessionData({
    this.id,
    required this.pattern,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory BreathingSessionData.fromJson(Map<String, dynamic> json) {
    return BreathingSessionData(
      id: json['id']?.toString(),
      pattern: json['pattern'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // SQLite methods
  factory BreathingSessionData.fromMap(Map<String, dynamic> map) {
    return BreathingSessionData(
      id: map['id']?.toString(),
      pattern: map['pattern'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      comment: map['comment'] ?? '',
      createdAt: DateTime.parse(
        map['date'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': createdAt.toIso8601String(),
      'pattern': pattern,
      'rating': rating,
      'comment': comment,
      'synced': 0,
    };
  }
}
