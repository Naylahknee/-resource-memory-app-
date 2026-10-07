import 'package:equatable/equatable.dart';

import '../../domain/entities/focus_task.dart';

class FocusFlowState extends Equatable {
  /// Native tasks waiting for 2-tap triage (newest first).
  final List<FocusTask> inbox;

  /// Sorted focus queue: triaged native tasks + projected external items.
  final List<FocusTaskView> queue;

  final int doneToday;

  /// Key of the task currently in "I'm stuck" breakdown mode, if any.
  final String? stuckKey;

  /// Generated or persisted micro-steps per queue key.
  final Map<String, List<String>> microSteps;

  /// Checked micro-step indices per queue key.
  final Map<String, Set<int>> microStepsChecked;

  const FocusFlowState({
    this.inbox = const [],
    this.queue = const [],
    this.doneToday = 0,
    this.stuckKey,
    this.microSteps = const {},
    this.microStepsChecked = const {},
  });

  FocusTaskView? get stuckTask {
    final key = stuckKey;
    if (key == null) return null;
    for (final v in queue) {
      if (v.key == key) return v;
    }
    return null;
  }

  FocusFlowState copyWith({
    List<FocusTask>? inbox,
    List<FocusTaskView>? queue,
    int? doneToday,
    String? stuckKey,
    bool clearStuckKey = false,
    Map<String, List<String>>? microSteps,
    Map<String, Set<int>>? microStepsChecked,
  }) {
    return FocusFlowState(
      inbox: inbox ?? this.inbox,
      queue: queue ?? this.queue,
      doneToday: doneToday ?? this.doneToday,
      stuckKey: clearStuckKey ? null : (stuckKey ?? this.stuckKey),
      microSteps: microSteps ?? this.microSteps,
      microStepsChecked: microStepsChecked ?? this.microStepsChecked,
    );
  }

  @override
  List<Object?> get props => [inbox, queue, doneToday, stuckKey, microSteps, microStepsChecked];
}
