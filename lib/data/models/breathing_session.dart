// Import the legacy compatibility model
export 'breathing_session_data.dart';

class BreathingSession {
  final String? id;
  final String patternName;
  final int durationMinutes;
  final bool completed;
  final int? effectivenessRating; // 1-5 scale
  final String? notes;
  final Map<String, dynamic>? sessionData;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  // Enhanced backend-aligned fields
  final List<String> tags;
  final double? tagConfidence;
  final bool processedForTags;

  BreathingSession({
    this.id,
    required this.patternName,
    required this.durationMinutes,
    this.completed = false,
    this.effectivenessRating,
    this.notes,
    this.sessionData,
    required this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.tags = const [],
    this.tagConfidence,
    this.processedForTags = false,
  });

  factory BreathingSession.fromJson(Map<String, dynamic> json) {
    return BreathingSession(
      id: json['id']?.toString(),
      patternName: json['pattern_name'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 0,
      completed: json['completed'] ?? false,
      effectivenessRating: json['effectiveness_rating'],
      notes: json['notes'],
      sessionData: json['session_data'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      tags: List<String>.from(json['tags'] ?? []),
      tagConfidence: json['tag_confidence']?.toDouble(),
      processedForTags: json['processed_for_tags'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern_name': patternName,
      'duration_minutes': durationMinutes,
      'completed': completed,
      'effectiveness_rating': effectivenessRating,
      'notes': notes,
      'session_data': sessionData,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'tags': tags,
      'tag_confidence': tagConfidence,
      'processed_for_tags': processedForTags,
    };
  }

  // SQLite methods
  factory BreathingSession.fromMap(Map<String, dynamic> map) {
    return BreathingSession(
      id: map['id']?.toString(),
      patternName: map['patternName'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      completed: map['completed'] == 1,
      effectivenessRating: map['effectivenessRating'],
      notes: map['notes'],
      sessionData:
          map['sessionData'] != null
              ? Map<String, dynamic>.from(map['sessionData'])
              : null,
      startedAt: DateTime.parse(map['startedAt']),
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
      createdAt: DateTime.parse(map['createdAt']),
      tags: map['tags']?.split(',') ?? [],
      tagConfidence: map['tagConfidence']?.toDouble(),
      processedForTags: map['processedForTags'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patternName': patternName,
      'durationMinutes': durationMinutes,
      'completed': completed ? 1 : 0,
      'effectivenessRating': effectivenessRating,
      'notes': notes,
      'sessionData': sessionData,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'tags': tags.join(','),
      'tagConfidence': tagConfidence,
      'processedForTags': processedForTags ? 1 : 0,
      'synced': 0,
    };
  }

  BreathingSession copyWith({
    String? id,
    String? patternName,
    int? durationMinutes,
    bool? completed,
    int? effectivenessRating,
    String? notes,
    Map<String, dynamic>? sessionData,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    List<String>? tags,
    double? tagConfidence,
    bool? processedForTags,
  }) {
    return BreathingSession(
      id: id ?? this.id,
      patternName: patternName ?? this.patternName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completed: completed ?? this.completed,
      effectivenessRating: effectivenessRating ?? this.effectivenessRating,
      notes: notes ?? this.notes,
      sessionData: sessionData ?? this.sessionData,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      tagConfidence: tagConfidence ?? this.tagConfidence,
      processedForTags: processedForTags ?? this.processedForTags,
    );
  }

  // Helper methods
  Duration get duration => Duration(minutes: durationMinutes);

  Duration? get sessionDuration {
    if (completedAt != null) {
      return completedAt!.difference(startedAt);
    }
    return null;
  }

  bool get wasEffective =>
      effectivenessRating != null && effectivenessRating! >= 3;
}
