// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotional_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmotionalRecordAdapter extends TypeAdapter<EmotionalRecord> {
  @override
  final int typeId = 1;

  @override
  EmotionalRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmotionalRecord(
      fecha: fields[0] as DateTime,
      origen: fields[1] as String,
      descripcion: fields[2] as String,
      emocion: fields[3] as Emotion,
    );
  }

  @override
  void write(BinaryWriter writer, EmotionalRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.fecha)
      ..writeByte(1)
      ..write(obj.origen)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.emocion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionalRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmotionAdapter extends TypeAdapter<Emotion> {
  @override
  final int typeId = 0;

  @override
  Emotion read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Emotion.happy;
      case 1:
        return Emotion.excited;
      case 2:
        return Emotion.tender;
      case 3:
        return Emotion.scared;
      case 4:
        return Emotion.angry;
      case 5:
        return Emotion.sad;
      case 6:
        return Emotion.anxious;
      default:
        return Emotion.happy;
    }
  }

  @override
  void write(BinaryWriter writer, Emotion obj) {
    switch (obj) {
      case Emotion.happy:
        writer.writeByte(0);
        break;
      case Emotion.excited:
        writer.writeByte(1);
        break;
      case Emotion.tender:
        writer.writeByte(2);
        break;
      case Emotion.scared:
        writer.writeByte(3);
        break;
      case Emotion.angry:
        writer.writeByte(4);
        break;
      case Emotion.sad:
        writer.writeByte(5);
        break;
      case Emotion.anxious:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
