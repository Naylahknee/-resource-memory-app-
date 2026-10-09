import 'package:hive/hive.dart';

import '../../domain/entities/focus_task.dart';

part 'focus_task_hive_model.g.dart';

/// Hive model for [FocusTask]. Enums are stored as their index ints so no
/// enum adapters are needed.
@HiveType(typeId: 3)
class FocusTaskHiveModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int urgency;

  @HiveField(3)
  final int energy;

  @HiveField(4)
  final List<String> microSteps;

  @HiveField(5)
  final List<bool> microStepsDone;

  @HiveField(6)
  final DateTime? completedAt;

  @HiveField(7)
  final int skippedCount;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final bool triaged;

  @HiveField(10)
  final DateTime? lastBumpedAt;

  @HiveField(11)
  final DateTime? resurfaceAt;

  const FocusTaskHiveModel({
    required this.id,
    required this.title,
    required this.urgency,
    required this.energy,
    required this.microSteps,
    required this.microStepsDone,
    required this.completedAt,
    required this.skippedCount,
    required this.createdAt,
    required this.triaged,
    required this.lastBumpedAt,
    required this.resurfaceAt,
  });

  factory FocusTaskHiveModel.fromDomain(FocusTask task) => FocusTaskHiveModel(
        id: task.id,
        title: task.title,
        urgency: task.urgency.index,
        energy: task.energy.index,
        microSteps: List<String>.from(task.microSteps),
        microStepsDone: List<bool>.from(task.microStepsDone),
        completedAt: task.completedAt,
        skippedCount: task.skippedCount,
        createdAt: task.createdAt,
        triaged: task.triaged,
        lastBumpedAt: task.lastBumpedAt,
        resurfaceAt: task.resurfaceAt,
      );

  FocusTask toDomain() => FocusTask(
        id: id,
        title: title,
        urgency: Urgency.values[urgency.clamp(0, Urgency.values.length - 1)],
        energy: EnergyLevel.values[energy.clamp(0, EnergyLevel.values.length - 1)],
        microSteps: List<String>.from(microSteps),
        microStepsDone: List<bool>.from(microStepsDone),
        completedAt: completedAt,
        skippedCount: skippedCount,
        createdAt: createdAt,
        triaged: triaged,
        lastBumpedAt: lastBumpedAt,
        resurfaceAt: resurfaceAt,
      );
}
