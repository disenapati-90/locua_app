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
      reminderEnabled: fields[3] == null ? false : fields[3] as bool,
      reminderHour: fields[4] == null ? 20 : fields[4] as int,
      reminderMinute: fields[5] == null ? 0 : fields[5] as int,
      ttsEnabled: fields[6] == null ? true : fields[6] as bool,
      ttsAccentLocale: fields[7] == null ? 'en-US' : fields[7] as String,
      ttsRate: fields[8] == null ? 0.45 : fields[8] as double,
      soundEnabled: fields[9] == null ? true : fields[9] as bool,
      soundPack: fields[10] == null ? 'chime' : fields[10] as String,
      userName: fields[11] == null ? '' : fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppMeta obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.lastOpenDate)
      ..writeByte(3)
      ..write(obj.reminderEnabled)
      ..writeByte(4)
      ..write(obj.reminderHour)
      ..writeByte(5)
      ..write(obj.reminderMinute)
      ..writeByte(6)
      ..write(obj.ttsEnabled)
      ..writeByte(7)
      ..write(obj.ttsAccentLocale)
      ..writeByte(8)
      ..write(obj.ttsRate)
      ..writeByte(9)
      ..write(obj.soundEnabled)
      ..writeByte(10)
      ..write(obj.soundPack)
      ..writeByte(11)
      ..write(obj.userName);
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
