// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) =>
    EmergencyContact(
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$EmergencyContactToJson(EmergencyContact instance) =>
    <String, dynamic>{
      'name': instance.name,
      'relationship': instance.relationship,
      'phone': instance.phone,
      'email': instance.email,
    };

MedicalInfo _$MedicalInfoFromJson(Map<String, dynamic> json) => MedicalInfo(
  conditions:
      (json['conditions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  medications:
      (json['medications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  allergies:
      (json['allergies'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$MedicalInfoToJson(MedicalInfo instance) =>
    <String, dynamic>{
      'conditions': instance.conditions,
      'medications': instance.medications,
      'allergies': instance.allergies,
    };

TherapyPreferences _$TherapyPreferencesFromJson(Map<String, dynamic> json) =>
    TherapyPreferences(
      communicationStyle: json['communicationStyle'] as String?,
      sessionFrequency: json['sessionFrequency'] as String?,
      focusAreas:
          (json['focusAreas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      goals: json['goals'] as String?,
    );

Map<String, dynamic> _$TherapyPreferencesToJson(TherapyPreferences instance) =>
    <String, dynamic>{
      'communicationStyle': instance.communicationStyle,
      'sessionFrequency': instance.sessionFrequency,
      'focusAreas': instance.focusAreas,
      'goals': instance.goals,
    };

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  email: json['email'] as String,
  username: json['username'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  dateOfBirth:
      json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
  phoneNumber: json['phoneNumber'] as String?,
  address: json['address'] as String?,
  occupation: json['occupation'] as String?,
  emergencyContact:
      json['emergencyContact'] == null
          ? null
          : EmergencyContact.fromJson(
            json['emergencyContact'] as Map<String, dynamic>,
          ),
  medicalInfo:
      json['medicalInfo'] == null
          ? null
          : MedicalInfo.fromJson(json['medicalInfo'] as Map<String, dynamic>),
  therapyPreferences:
      json['therapyPreferences'] == null
          ? null
          : TherapyPreferences.fromJson(
            json['therapyPreferences'] as Map<String, dynamic>,
          ),
  isProfileComplete: json['isProfileComplete'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'phoneNumber': instance.phoneNumber,
      'address': instance.address,
      'occupation': instance.occupation,
      'emergencyContact': instance.emergencyContact,
      'medicalInfo': instance.medicalInfo,
      'therapyPreferences': instance.therapyPreferences,
      'isProfileComplete': instance.isProfileComplete,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
