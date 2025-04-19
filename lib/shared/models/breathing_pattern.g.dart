// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breathing_pattern.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BreathingPatternAdapter extends TypeAdapter<BreathingPattern> {
  @override
  final int typeId = 2;

  @override
  BreathingPattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreathingPattern(
      name: fields[0] as String,
      inhaleSeconds: fields[1] as int,
      holdSeconds: fields[2] as int,
      exhaleSeconds: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BreathingPattern obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.inhaleSeconds)
      ..writeByte(2)
      ..write(obj.holdSeconds)
      ..writeByte(3)
      ..write(obj.exhaleSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
