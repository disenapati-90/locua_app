// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mnemonic.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MnemonicAdapter extends TypeAdapter<Mnemonic> {
  @override
  final int typeId = 1;

  @override
  Mnemonic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mnemonic(
      word: fields[0] as String,
      textNote: fields[1] as String?,
      audioFilePath: fields[2] as String?,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Mnemonic obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.textNote)
      ..writeByte(2)
      ..write(obj.audioFilePath)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MnemonicAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
