class BreathingPattern {
  final String? id;
  final String name;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int cycles;
  final int restSeconds;

  BreathingPattern({
    this.id,
    required this.name,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    required this.cycles,
    required this.restSeconds,
  });

  factory BreathingPattern.fromJson(Map<String, dynamic> json) {
    return BreathingPattern(
      id: json['id']?.toString(), // Ensure string conversion
      name: json['name'] ?? '',
      inhaleSeconds: json['inhale_seconds'] ?? 0,
      holdSeconds: json['hold_seconds'] ?? 0,
      exhaleSeconds: json['exhale_seconds'] ?? 0,
      cycles: json['cycles'] ?? 0,
      restSeconds: json['rest_seconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'inhale_seconds': inhaleSeconds,
      'hold_seconds': holdSeconds,
      'exhale_seconds': exhaleSeconds,
      'cycles': cycles,
      'rest_seconds': restSeconds,
    };
  }

  // SQLite methods
  factory BreathingPattern.fromMap(Map<String, dynamic> map) {
    return BreathingPattern(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      inhaleSeconds: map['inhaleSeconds'] ?? 0,
      holdSeconds: map['holdSeconds'] ?? 0,
      exhaleSeconds: map['exhaleSeconds'] ?? 0,
      cycles: map['cycles'] ?? 0,
      restSeconds: map['restSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inhaleSeconds': inhaleSeconds,
      'holdSeconds': holdSeconds,
      'exhaleSeconds': exhaleSeconds,
      'cycles': cycles,
      'restSeconds': restSeconds,
      'synced': 0,
    };
  }
}
