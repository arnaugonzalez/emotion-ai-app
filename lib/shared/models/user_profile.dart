class UserProfile {
  final String? name;
  final int? age;
  final String? gender;
  final String? job;
  final String? country;
  final String? personalityType;
  final String? relaxationTime;
  final String? selfcareFrequency;
  final List<String>? relaxationTools;
  final bool? hasPreviousMentalHealthAppExperience;
  final String? therapyChatHistoryPreference;
  final String role; // 'admin' or 'user'
  final int dailyTokenLimit;

  UserProfile({
    this.name,
    this.age,
    this.gender,
    this.job,
    this.country,
    this.personalityType,
    this.relaxationTime,
    this.selfcareFrequency,
    this.relaxationTools,
    this.hasPreviousMentalHealthAppExperience,
    this.therapyChatHistoryPreference,
    this.role = 'user',
    this.dailyTokenLimit = 200000, // Default to regular user limit
  });

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    String? job,
    String? country,
    String? personalityType,
    String? relaxationTime,
    String? selfcareFrequency,
    List<String>? relaxationTools,
    bool? hasPreviousMentalHealthAppExperience,
    String? therapyChatHistoryPreference,
    String? role,
    int? dailyTokenLimit,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      job: job ?? this.job,
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
      role: role ?? this.role,
      dailyTokenLimit: dailyTokenLimit ?? this.dailyTokenLimit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'job': job,
      'country': country,
      'personalityType': personalityType,
      'relaxationTime': relaxationTime,
      'selfcareFrequency': selfcareFrequency,
      'relaxationTools': relaxationTools,
      'hasPreviousMentalHealthAppExperience':
          hasPreviousMentalHealthAppExperience,
      'therapyChatHistoryPreference': therapyChatHistoryPreference,
      'role': role,
      'dailyTokenLimit': dailyTokenLimit,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      job: map['job'],
      country: map['country'],
      personalityType: map['personalityType'],
      relaxationTime: map['relaxationTime'],
      selfcareFrequency: map['selfcareFrequency'],
      relaxationTools:
          map['relaxationTools'] != null
              ? List<String>.from(map['relaxationTools'])
              : null,
      hasPreviousMentalHealthAppExperience:
          map['hasPreviousMentalHealthAppExperience'],
      therapyChatHistoryPreference: map['therapyChatHistoryPreference'],
      role: map['role'] ?? 'user',
      dailyTokenLimit: map['dailyTokenLimit'] ?? 200000,
    );
  }

  bool isComplete() {
    return name != null &&
        age != null &&
        gender != null &&
        job != null &&
        country != null;
    // Not requiring the new fields for basic profile completion
  }

  String toContextString() {
    final buffer = StringBuffer("User Profile: ");
    buffer.write("${name ?? 'Unknown'}, ${age ?? 'Unknown'} years old, ");
    buffer.write(
      "${gender ?? 'Unknown'}, works as ${job ?? 'Unknown'} in ${country ?? 'Unknown'}. ",
    );

    if (personalityType != null) {
      buffer.write("Personality type: $personalityType. ");
    }

    if (relaxationTime != null) {
      buffer.write("Prefers to relax during: $relaxationTime. ");
    }

    if (selfcareFrequency != null) {
      buffer.write("Takes time for themselves: $selfcareFrequency. ");
    }

    if (relaxationTools != null && relaxationTools!.isNotEmpty) {
      buffer.write(
        "Preferred relaxation tools: ${relaxationTools!.join(', ')}. ",
      );
    }

    return buffer.toString();
  }

  // Helper method to get daily token limit based on role
  static int getDailyTokenLimit(String role) {
    switch (role) {
      case 'admin':
        return 25000000; // 25M tokens for admin
      case 'user':
      default:
        return 200000; // 200K tokens for regular users
    }
  }
}
