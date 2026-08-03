// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_meta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppMetaAdapter extends TypeAdapter<AppMeta> {
  @override
  final int typeId = 2;

  @override
  AppMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppMeta(
      currentStreak: fields[0] as int,
      longestStreak: fields[1] as int,
      lastOpenDate: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppMeta obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.lastOpenDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
