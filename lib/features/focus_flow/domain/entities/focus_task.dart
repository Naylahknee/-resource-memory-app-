/// Triage dimensions for a focus task. Kept intentionally coarse:
/// the whole point is 2 taps, not a taxonomy.
enum Urgency {
  later,
  soon,
  now,
}

enum EnergyLevel {
  low,
  medium,
  high,
}

/// A single actionable item in the Focus Flow queue.
///
/// Native focus tasks are created from the brain dump. External items
/// (todos, commitments) are projected into [FocusTaskView] at read time and
/// never duplicated here.
class FocusTask {
  final int id;
  final String title;
  final Urgency urgency;
  final EnergyLevel energy;
  final List<String> microSteps;
  final List<bool> microStepsDone;
  final DateTime? completedAt;
  final int skippedCount;
  final DateTime createdAt;
  final bool triaged;
  final DateTime? lastBumpedAt;

  const FocusTask({
    required this.id,
    required this.title,
    this.urgency = Urgency.soon,
    this.energy = EnergyLevel.medium,
    this.microSteps = const [],
    this.microStepsDone = const [],
    this.completedAt,
    this.skippedCount = 0,
    required this.createdAt,
    this.triaged = false,
    this.lastBumpedAt,
  });

  bool get isCompleted => completedAt != null;

  bool get allMicroStepsDone =>
      microSteps.isNotEmpty && microStepsDone.length == microSteps.length && microStepsDone.every((d) => d);

  FocusTask copyWith({
    int? id,
    String? title,
    Urgency? urgency,
    EnergyLevel? energy,
    List<String>? microSteps,
    List<bool>? microStepsDone,
    DateTime? completedAt,
    int? skippedCount,
    DateTime? createdAt,
    bool? triaged,
    DateTime? lastBumpedAt,
    bool clearCompletedAt = false,
  }) {
    return FocusTask(
      id: id ?? this.id,
      title: title ?? this.title,
      urgency: urgency ?? this.urgency,
      energy: energy ?? this.energy,
      microSteps: microSteps ?? this.microSteps,
      microStepsDone: microStepsDone ?? this.microStepsDone,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      skippedCount: skippedCount ?? this.skippedCount,
      createdAt: createdAt ?? this.createdAt,
      triaged: triaged ?? this.triaged,
      lastBumpedAt: lastBumpedAt ?? this.lastBumpedAt,
    );
  }
}

/// Unified view of one queue item: either a native [FocusTask] or a
/// projected external item (todo / commitment). External items are read-only
/// projections; completing or skipping them only affects focus-layer state,
/// never the underlying todo/commitment.
class FocusTaskView {
  /// Stable key: 'focus:<id>', 'todo:<id>' or 'commitment:<id>'.
  final String key;
  final String title;
  final Urgency urgency;
  final EnergyLevel energy;
  final DateTime? dueAt;
  final int skippedCount;
  final DateTime? lastBumpedAt;
  final DateTime createdAt;
  final List<String> microSteps;
  final List<bool> microStepsDone;
  final bool isExternal;
  final int? nativeId;

  const FocusTaskView({
    required this.key,
    required this.title,
    required this.urgency,
    required this.energy,
    this.dueAt,
    this.skippedCount = 0,
    this.lastBumpedAt,
    required this.createdAt,
    this.microSteps = const [],
    this.microStepsDone = const [],
    this.isExternal = false,
    this.nativeId,
  });
}
