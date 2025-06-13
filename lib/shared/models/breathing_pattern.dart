class BreathingPattern {
  final String name;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int cycles; // Number of cycles (n)
  final int restSeconds; // Rest duration between cycles (m)

  BreathingPattern({
    required this.name,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    required this.cycles,
    required this.restSeconds,
  });

  // Convert to SQLite-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inhaleSeconds': inhaleSeconds,
      'holdSeconds': holdSeconds,
      'exhaleSeconds': exhaleSeconds,
      'cycles': cycles,
      'restSeconds': restSeconds,
    };
  }

  // Create an instance from SQLite Map
  factory BreathingPattern.fromMap(Map<String, dynamic> map) {
    return BreathingPattern(
      name: map['name'] as String,
      inhaleSeconds: map['inhaleSeconds'] as int,
      holdSeconds: map['holdSeconds'] as int,
      exhaleSeconds: map['exhaleSeconds'] as int,
      cycles: map['cycles'] as int,
      restSeconds: map['restSeconds'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BreathingPattern &&
        other.name == name &&
        other.inhaleSeconds == inhaleSeconds &&
        other.holdSeconds == holdSeconds &&
        other.exhaleSeconds == exhaleSeconds &&
        other.cycles == cycles &&
        other.restSeconds == restSeconds;
  }

  @override
  int get hashCode => Object.hash(
    name,
    inhaleSeconds,
    holdSeconds,
    exhaleSeconds,
    cycles,
    restSeconds,
  );
}
