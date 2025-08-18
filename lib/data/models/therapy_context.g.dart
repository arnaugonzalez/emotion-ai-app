// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'therapy_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TherapyContext _$TherapyContextFromJson(Map<String, dynamic> json) =>
    TherapyContext(
      therapyContext: json['therapyContext'] as Map<String, dynamic>?,
      aiInsights: json['aiInsights'] as Map<String, dynamic>?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      contextSummary: json['contextSummary'] as String?,
    );

Map<String, dynamic> _$TherapyContextToJson(TherapyContext instance) =>
    <String, dynamic>{
      'therapyContext': instance.therapyContext,
      'aiInsights': instance.aiInsights,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'contextSummary': instance.contextSummary,
    };

ProfileStatus _$ProfileStatusFromJson(Map<String, dynamic> json) =>
    ProfileStatus(
      hasProfile: json['hasProfile'] as bool,
      profileCompleteness: (json['profileCompleteness'] as num).toDouble(),
      missingFields:
          (json['missingFields'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      lastUpdated:
          json['lastUpdated'] == null
              ? null
              : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$ProfileStatusToJson(ProfileStatus instance) =>
    <String, dynamic>{
      'hasProfile': instance.hasProfile,
      'profileCompleteness': instance.profileCompleteness,
      'missingFields': instance.missingFields,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
