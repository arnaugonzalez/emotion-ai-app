class UserProfile {
  final String? name;
  final int? age;
  final String? gender;
  final String? job;
  final String? country;

  UserProfile({this.name, this.age, this.gender, this.job, this.country});

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    String? job,
    String? country,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      job: job ?? this.job,
      country: country ?? this.country,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'job': job,
      'country': country,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      job: map['job'],
      country: map['country'],
    );
  }

  bool isComplete() {
    return name != null &&
        age != null &&
        gender != null &&
        job != null &&
        country != null;
  }

  String toContextString() {
    return "User Profile: ${name ?? 'Unknown'}, ${age ?? 'Unknown'} years old, ${gender ?? 'Unknown'}, works as ${job ?? 'Unknown'} in ${country ?? 'Unknown'}.";
  }
}
