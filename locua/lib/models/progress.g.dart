// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgressAdapter extends TypeAdapter<Progress> {
  @override
  final int typeId = 0;

  @override
  Progress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Progress(
      word: fields[0] as String,
      lastReviewed: fields[1] as DateTime?,
      intervalDays: fields[2] as int,
      correctStreak: fields[3] as int,
      nextReviewDue: fields[4] as DateTime?,
      learned: fields[5] as bool,
      userMnemonic: fields[6] as String?,
      voiceNoteId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Progress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.lastReviewed)
      ..writeByte(2)
      ..write(obj.intervalDays)
      ..writeByte(3)
      ..write(obj.correctStreak)
      ..writeByte(4)
      ..write(obj.nextReviewDue)
      ..writeByte(5)
      ..write(obj.learned)
      ..writeByte(6)
      ..write(obj.userMnemonic)
      ..writeByte(7)
      ..write(obj.voiceNoteId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
