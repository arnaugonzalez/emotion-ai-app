import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final String? email;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyContactToJson(this);

  EmergencyContact copyWith({
    String? name,
    String? relationship,
    String? phone,
    String? email,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}

@JsonSerializable()
class MedicalInfo {
  final List<String> conditions;
  final List<String> medications;
  final List<String> allergies;

  MedicalInfo({
    this.conditions = const [],
    this.medications = const [],
    this.allergies = const [],
  });

  factory MedicalInfo.fromJson(Map<String, dynamic> json) =>
      _$MedicalInfoFromJson(json);

  Map<String, dynamic> toJson() => _$MedicalInfoToJson(this);

  MedicalInfo copyWith({
    List<String>? conditions,
    List<String>? medications,
    List<String>? allergies,
  }) {
    return MedicalInfo(
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
    );
  }
}

@JsonSerializable()
class TherapyPreferences {
  final String? communicationStyle;
  final String? sessionFrequency;
  final List<String> focusAreas;
  final String? goals;

  TherapyPreferences({
    this.communicationStyle,
    this.sessionFrequency,
    this.focusAreas = const [],
    this.goals,
  });

  factory TherapyPreferences.fromJson(Map<String, dynamic> json) =>
      _$TherapyPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$TherapyPreferencesToJson(this);

  TherapyPreferences copyWith({
    String? communicationStyle,
    String? sessionFrequency,
    List<String>? focusAreas,
    String? goals,
  }) {
    return TherapyPreferences(
      communicationStyle: communicationStyle ?? this.communicationStyle,
      sessionFrequency: sessionFrequency ?? this.sessionFrequency,
      focusAreas: focusAreas ?? this.focusAreas,
      goals: goals ?? this.goals,
    );
  }
}

@JsonSerializable()
class UserProfile {
  final String id;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? address;
  final String? occupation;
  final EmergencyContact? emergencyContact;
  final MedicalInfo? medicalInfo;
  final TherapyPreferences? therapyPreferences;
  final Map<String, dynamic>? userProfileData;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.phoneNumber,
    this.address,
    this.occupation,
    this.emergencyContact,
    this.medicalInfo,
    this.therapyPreferences,
    this.userProfileData,
    required this.isProfileComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle field name mapping from backend (snake_case) to Flutter (camelCase)
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      dateOfBirth:
          json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'] as String)
              : null,
      phoneNumber: json['phone_number'] as String?,
      address: json['address'] as String?,
      occupation: json['occupation'] as String?,
      emergencyContact:
          json['emergency_contact'] != null
              ? EmergencyContact.fromJson(
                json['emergency_contact'] as Map<String, dynamic>,
              )
              : null,
      medicalInfo:
          json['medical_info'] != null
              ? MedicalInfo.fromJson(
                json['medical_info'] as Map<String, dynamic>,
              )
              : null,
      therapyPreferences:
          json['therapy_preferences'] != null
              ? TherapyPreferences.fromJson(
                json['therapy_preferences'] as Map<String, dynamic>,
              )
              : null,
      userProfileData: json['user_profile_data'] as Map<String, dynamic>?,
      isProfileComplete: (json['is_profile_complete'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'phone_number': phoneNumber,
      'address': address,
      'occupation': occupation,
      'emergency_contact': emergencyContact?.toJson(),
      'medical_info': medicalInfo?.toJson(),
      'therapy_preferences': therapyPreferences?.toJson(),
      'user_profile_data': userProfileData,
      'is_profile_complete': isProfileComplete,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? address,
    String? occupation,
    EmergencyContact? emergencyContact,
    MedicalInfo? medicalInfo,
    TherapyPreferences? therapyPreferences,
    Map<String, dynamic>? userProfileData,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      therapyPreferences: therapyPreferences ?? this.therapyPreferences,
      userProfileData: userProfileData ?? this.userProfileData,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (username != null) {
      return username!;
    } else {
      return email.split('@')[0];
    }
  }

  bool get hasBasicInfo => firstName != null && lastName != null;
  bool get hasContactInfo => phoneNumber != null;
  bool get hasEmergencyContact => emergencyContact != null;
}
