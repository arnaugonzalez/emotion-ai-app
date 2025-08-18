import 'package:json_annotation/json_annotation.dart';

part 'therapy_context.g.dart';

@JsonSerializable()
class TherapyContext {
  final Map<String, dynamic>? therapyContext;
  final Map<String, dynamic>? aiInsights;
  final DateTime lastUpdated;
  final String? contextSummary;

  TherapyContext({
    this.therapyContext,
    this.aiInsights,
    required this.lastUpdated,
    this.contextSummary,
  });

  factory TherapyContext.fromJson(Map<String, dynamic> json) =>
      _$TherapyContextFromJson(json);

  Map<String, dynamic> toJson() => _$TherapyContextToJson(this);

  TherapyContext copyWith({
    Map<String, dynamic>? therapyContext,
    Map<String, dynamic>? aiInsights,
    DateTime? lastUpdated,
    String? contextSummary,
  }) {
    return TherapyContext(
      therapyContext: therapyContext ?? this.therapyContext,
      aiInsights: aiInsights ?? this.aiInsights,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      contextSummary: contextSummary ?? this.contextSummary,
    );
  }

  // Helper methods for common context data
  String? get moodPatterns => therapyContext?['mood_patterns'] as String?;

  String? get stressTriggers => therapyContext?['stress_triggers'] as String?;

  String? get copingStrategies => aiInsights?['coping_strategies'] as String?;

  String? get progressAreas => aiInsights?['progress_areas'] as String?;

  bool get hasContext => therapyContext != null || aiInsights != null;
}

@JsonSerializable()
class ProfileStatus {
  final bool hasProfile;
  final double profileCompleteness;
  final List<String> missingFields;
  final DateTime? lastUpdated;

  ProfileStatus({
    required this.hasProfile,
    required this.profileCompleteness,
    required this.missingFields,
    this.lastUpdated,
  });

  factory ProfileStatus.fromJson(Map<String, dynamic> json) =>
      _$ProfileStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileStatusToJson(this);

  ProfileStatus copyWith({
    bool? hasProfile,
    double? profileCompleteness,
    List<String>? missingFields,
    DateTime? lastUpdated,
  }) {
    return ProfileStatus(
      hasProfile: hasProfile ?? this.hasProfile,
      profileCompleteness: profileCompleteness ?? this.profileCompleteness,
      missingFields: missingFields ?? this.missingFields,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper methods
  bool get isComplete => profileCompleteness >= 100.0;
  bool get isPartiallyComplete =>
      profileCompleteness > 0.0 && profileCompleteness < 100.0;
  String get completenessText =>
      '${profileCompleteness.toStringAsFixed(0)}% Complete';
}
