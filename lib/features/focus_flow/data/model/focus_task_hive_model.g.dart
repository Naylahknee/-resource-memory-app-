// GENERATED CODE - DO NOT MODIFY BY HAND
//
// If build_runner is available, regenerate with:
//   flutter pub run build_runner build --delete-conflicting-outputs
// This hand-written adapter matches the generator output exactly.

part of 'focus_task_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusTaskHiveModelAdapter extends TypeAdapter<FocusTaskHiveModel> {
  @override
  final int typeId = 3;

  @override
  FocusTaskHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusTaskHiveModel(
      id: fields[0] as int,
      title: fields[1] as String,
      urgency: fields[2] as int,
      energy: fields[3] as int,
      microSteps: (fields[4] as List).cast<String>(),
      microStepsDone: (fields[5] as List).cast<bool>(),
      completedAt: fields[6] as DateTime?,
      skippedCount: fields[7] as int,
      createdAt: fields[8] as DateTime,
      triaged: fields[9] as bool,
      lastBumpedAt: fields[10] as DateTime?,
      // Field 11 is new; old rows simply do not have it.
      resurfaceAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FocusTaskHiveModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.urgency)
      ..writeByte(3)
      ..write(obj.energy)
      ..writeByte(4)
      ..write(obj.microSteps)
      ..writeByte(5)
      ..write(obj.microStepsDone)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.skippedCount)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.triaged)
      ..writeByte(10)
      ..write(obj.lastBumpedAt)
      ..writeByte(11)
      ..write(obj.resurfaceAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusTaskHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
