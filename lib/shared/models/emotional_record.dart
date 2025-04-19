import 'package:hive/hive.dart';

part 'emotional_record.g.dart';

@HiveType(typeId: 0)
enum Emotion {
  @HiveField(0)
  happy,
  @HiveField(1)
  excited,
  @HiveField(2)
  tender,
  @HiveField(3)
  scared,
  @HiveField(4)
  angry,
  @HiveField(5)
  sad,
  @HiveField(6)
  anxious,
}

@HiveType(typeId: 1)
class EmotionalRecord extends HiveObject {
  @HiveField(0)
  final DateTime fecha;

  @HiveField(1)
  final String origen;

  @HiveField(2)
  final String descripcion;

  @HiveField(3)
  final Emotion emocion;

  EmotionalRecord({
    required this.fecha,
    required this.origen,
    required this.descripcion,
    required this.emocion,
  });
}
