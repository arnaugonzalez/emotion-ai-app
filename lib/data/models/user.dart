class User {
  final String? id;
  final String email;
  final String? password;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final bool? isActive;
  final bool? isVerified;
  final Map<String, dynamic>? agentPersonalityData;
  final Map<String, dynamic>? userProfileData;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  User({
    this.id,
    required this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.isActive,
    this.isVerified,
    this.agentPersonalityData,
    this.userProfileData,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth:
          json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'])
              : null,
      isActive: json['is_active'],
      isVerified: json['is_verified'],
      agentPersonalityData: json['agent_personality_data'],
      userProfileData: json['user_profile_data'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      lastLoginAt:
          json['last_login_at'] != null
              ? DateTime.parse(json['last_login_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'email': email};
    if (password != null) {
      data['password'] = password;
    }
    if (firstName != null) {
      data['first_name'] = firstName;
    }
    if (lastName != null) {
      data['last_name'] = lastName;
    }
    if (dateOfBirth != null) {
      data['date_of_birth'] = dateOfBirth!.toIso8601String();
    }
    return data;
  }
}
