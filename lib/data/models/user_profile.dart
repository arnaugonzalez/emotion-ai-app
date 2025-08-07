class UserProfile {
  final String? id;
  final String? name;
  final int? age;
  final String? gender;
  final String? occupation;
  final String? country;
  final String? personalityType;
  final String? relaxationTime;
  final String? selfcareFrequency;
  final List<String> relaxationTools;
  final bool? hasPreviousMentalHealthAppExperience;
  final String? therapyChatHistoryPreference;

  // Backend-aligned fields for therapy/wellness
  final List<String> goals;
  final List<String> concerns;
  final List<String> preferredActivities;
  final List<String> therapyGoals;
  final List<String> wellnessGoals;
  final List<String> copingStrategies;
  final List<String> mindfulnessPractices;
  final String? communicationStyle;
  final String? timezone;
  final int? preferredSessionLength; // in minutes
  final List<Map<String, String>> crisisContacts;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    this.name,
    this.age,
    this.gender,
    this.occupation,
    this.country,
    this.personalityType,
    this.relaxationTime,
    this.selfcareFrequency,
    this.relaxationTools = const [],
    this.hasPreviousMentalHealthAppExperience,
    this.therapyChatHistoryPreference,
    this.goals = const [],
    this.concerns = const [],
    this.preferredActivities = const [],
    this.therapyGoals = const [],
    this.wellnessGoals = const [],
    this.copingStrategies = const [],
    this.mindfulnessPractices = const [],
    this.communicationStyle,
    this.timezone,
    this.preferredSessionLength,
    this.crisisContacts = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString(),
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      occupation: json['occupation'],
      country: json['country'],
      personalityType: json['personality_type'],
      relaxationTime: json['relaxation_time'],
      selfcareFrequency: json['selfcare_frequency'],
      relaxationTools: List<String>.from(json['relaxation_tools'] ?? []),
      hasPreviousMentalHealthAppExperience:
          json['has_previous_mental_health_app_experience'],
      therapyChatHistoryPreference: json['therapy_chat_history_preference'],
      goals: List<String>.from(json['goals'] ?? []),
      concerns: List<String>.from(json['concerns'] ?? []),
      preferredActivities: List<String>.from(
        json['preferred_activities'] ?? [],
      ),
      therapyGoals: List<String>.from(json['therapy_goals'] ?? []),
      wellnessGoals: List<String>.from(json['wellness_goals'] ?? []),
      copingStrategies: List<String>.from(json['coping_strategies'] ?? []),
      mindfulnessPractices: List<String>.from(
        json['mindfulness_practices'] ?? [],
      ),
      communicationStyle: json['communication_style'],
      timezone: json['timezone'],
      preferredSessionLength: json['preferred_session_length'],
      crisisContacts: List<Map<String, String>>.from(
        (json['crisis_contacts'] ?? []).map(
          (contact) => Map<String, String>.from(contact),
        ),
      ),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'occupation': occupation,
      'country': country,
      'personality_type': personalityType,
      'relaxation_time': relaxationTime,
      'selfcare_frequency': selfcareFrequency,
      'relaxation_tools': relaxationTools,
      'has_previous_mental_health_app_experience':
          hasPreviousMentalHealthAppExperience,
      'therapy_chat_history_preference': therapyChatHistoryPreference,
      'goals': goals,
      'concerns': concerns,
      'preferred_activities': preferredActivities,
      'therapy_goals': therapyGoals,
      'wellness_goals': wellnessGoals,
      'coping_strategies': copingStrategies,
      'mindfulness_practices': mindfulnessPractices,
      'communication_style': communicationStyle,
      'timezone': timezone,
      'preferred_session_length': preferredSessionLength,
      'crisis_contacts': crisisContacts,
    };
  }

  // SQLite methods
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString(),
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      occupation: map['occupation'],
      country: map['country'],
      personalityType: map['personalityType'],
      relaxationTime: map['relaxationTime'],
      selfcareFrequency: map['selfcareFrequency'],
      relaxationTools: map['relaxationTools']?.split(',') ?? [],
      hasPreviousMentalHealthAppExperience:
          map['hasPreviousMentalHealthAppExperience'] == 1,
      therapyChatHistoryPreference: map['therapyChatHistoryPreference'],
      goals: map['goals']?.split(',') ?? [],
      concerns: map['concerns']?.split(',') ?? [],
      preferredActivities: map['preferredActivities']?.split(',') ?? [],
      therapyGoals: map['therapyGoals']?.split(',') ?? [],
      wellnessGoals: map['wellnessGoals']?.split(',') ?? [],
      copingStrategies: map['copingStrategies']?.split(',') ?? [],
      mindfulnessPractices: map['mindfulnessPractices']?.split(',') ?? [],
      communicationStyle: map['communicationStyle'],
      timezone: map['timezone'],
      preferredSessionLength: map['preferredSessionLength'],
      crisisContacts: [], // Complex data stored as JSON string in practice
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'occupation': occupation,
      'country': country,
      'personalityType': personalityType,
      'relaxationTime': relaxationTime,
      'selfcareFrequency': selfcareFrequency,
      'relaxationTools': relaxationTools.join(','),
      'hasPreviousMentalHealthAppExperience':
          hasPreviousMentalHealthAppExperience == true ? 1 : 0,
      'therapyChatHistoryPreference': therapyChatHistoryPreference,
      'goals': goals.join(','),
      'concerns': concerns.join(','),
      'preferredActivities': preferredActivities.join(','),
      'therapyGoals': therapyGoals.join(','),
      'wellnessGoals': wellnessGoals.join(','),
      'copingStrategies': copingStrategies.join(','),
      'mindfulnessPractices': mindfulnessPractices.join(','),
      'communicationStyle': communicationStyle,
      'timezone': timezone,
      'preferredSessionLength': preferredSessionLength,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'synced': 0,
    };
  }

  bool isComplete() {
    return (goals.isNotEmpty ||
            therapyGoals.isNotEmpty ||
            wellnessGoals.isNotEmpty) &&
        (concerns.isNotEmpty || preferredActivities.isNotEmpty);
  }

  double getCompletenessScore() {
    int totalFields = 7;
    int completedFields = 0;

    if (goals.isNotEmpty) completedFields++;
    if (concerns.isNotEmpty) completedFields++;
    if (preferredActivities.isNotEmpty) completedFields++;
    if (therapyGoals.isNotEmpty) completedFields++;
    if (wellnessGoals.isNotEmpty) completedFields++;
    if (copingStrategies.isNotEmpty) completedFields++;
    if (mindfulnessPractices.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  List<String> getAllGoals() {
    return [...goals, ...therapyGoals, ...wellnessGoals];
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    String? occupation,
    String? country,
    String? personalityType,
    String? relaxationTime,
    String? selfcareFrequency,
    List<String>? relaxationTools,
    bool? hasPreviousMentalHealthAppExperience,
    String? therapyChatHistoryPreference,
    List<String>? goals,
    List<String>? concerns,
    List<String>? preferredActivities,
    List<String>? therapyGoals,
    List<String>? wellnessGoals,
    List<String>? copingStrategies,
    List<String>? mindfulnessPractices,
    String? communicationStyle,
    String? timezone,
    int? preferredSessionLength,
    List<Map<String, String>>? crisisContacts,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      country: country ?? this.country,
      personalityType: personalityType ?? this.personalityType,
      relaxationTime: relaxationTime ?? this.relaxationTime,
      selfcareFrequency: selfcareFrequency ?? this.selfcareFrequency,
      relaxationTools: relaxationTools ?? this.relaxationTools,
      hasPreviousMentalHealthAppExperience:
          hasPreviousMentalHealthAppExperience ??
          this.hasPreviousMentalHealthAppExperience,
      therapyChatHistoryPreference:
          therapyChatHistoryPreference ?? this.therapyChatHistoryPreference,
      goals: goals ?? this.goals,
      concerns: concerns ?? this.concerns,
      preferredActivities: preferredActivities ?? this.preferredActivities,
      therapyGoals: therapyGoals ?? this.therapyGoals,
      wellnessGoals: wellnessGoals ?? this.wellnessGoals,
      copingStrategies: copingStrategies ?? this.copingStrategies,
      mindfulnessPractices: mindfulnessPractices ?? this.mindfulnessPractices,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      timezone: timezone ?? this.timezone,
      preferredSessionLength:
          preferredSessionLength ?? this.preferredSessionLength,
      crisisContacts: crisisContacts ?? this.crisisContacts,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
