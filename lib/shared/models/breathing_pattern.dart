import 'package:hive/hive.dart';

part 'breathing_pattern.g.dart';

@HiveType(typeId: 2)
class BreathingPattern extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int inhaleSeconds;

  @HiveField(2)
  final int holdSeconds;

  @HiveField(3)
  final int exhaleSeconds;

  BreathingPattern({
    required this.name,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
  });
}
