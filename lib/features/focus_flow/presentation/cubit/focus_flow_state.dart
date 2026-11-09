import 'package:equatable/equatable.dart';

import '../../domain/entities/focus_task.dart';
import '../../domain/micro_step_generator.dart';

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

  /// Granularity of the currently open "I'm stuck" breakdown.
  final StepSpiciness stuckSpiciness;

  /// The reason picked in the "I'm stuck" menu for the open breakdown,
  /// if any. The reason picks the branch the steps came from.
  final StuckReason? stuckReason;

  /// Key of the task currently reframed as "just 2 minutes", if any.
  final String? tinyKey;

  /// Low-capacity day: queue capped at 3, gentler everything.
  final bool lowCapacity;

  /// Bad-day ("redo") mode: queue shrinks to the single most important task.
  final bool badDay;

  /// Waiting mode: the appointment the user set by hand, if any.
  final DateTime? waitingAppointment;

  /// How many minutes before the appointment waiting mode kicks in.
  final int waitingWindowMinutes;

  /// True while the clock is inside the waiting window (from
  /// appointment minus window, until the appointment time).
  final bool waitingActive;

  /// Buffer rule: after a completion, show the breather screen
  /// before revealing the next task. Cleared by the timer or Skip.
  final bool showBreather;

  /// Gentle self-trust score: kept commitments this week (resets Monday).
  final int trustKept;

  /// Focused sessions resolved this week (kept + "not now"). "Not now"
  /// is neutral, it just fills out the denominator.
  final int trustTotal;

  /// Most common recent pause reason, for the quiet "Why I pause" line.
  final String? pauseSummary;

  const FocusFlowState({
    this.inbox = const [],
    this.queue = const [],
    this.doneToday = 0,
    this.stuckKey,
    this.microSteps = const {},
    this.microStepsChecked = const {},
    this.stuckSpiciness = StepSpiciness.medium,
    this.stuckReason,
    this.tinyKey,
    this.lowCapacity = false,
    this.badDay = false,
    this.waitingAppointment,
    this.waitingWindowMinutes = 120,
    this.waitingActive = false,
    this.showBreather = false,
    this.trustKept = 0,
    this.trustTotal = 0,
    this.pauseSummary,
  });

  FocusTaskView? get stuckTask {
    final key = stuckKey;
    if (key == null) return null;
    for (final v in queue) {
      if (v.key == key) return v;
    }
    return null;
  }

  FocusTaskView? get tinyTask {
    final key = tinyKey;
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
    StepSpiciness? stuckSpiciness,
    StuckReason? stuckReason,
    bool clearStuckReason = false,
    String? tinyKey,
    bool clearTinyKey = false,
    bool? lowCapacity,
    bool? badDay,
    DateTime? waitingAppointment,
    bool clearWaitingAppointment = false,
    int? waitingWindowMinutes,
    bool? waitingActive,
    bool? showBreather,
    int? trustKept,
    int? trustTotal,
    String? pauseSummary,
  }) {
    return FocusFlowState(
      inbox: inbox ?? this.inbox,
      queue: queue ?? this.queue,
      doneToday: doneToday ?? this.doneToday,
      stuckKey: clearStuckKey ? null : (stuckKey ?? this.stuckKey),
      microSteps: microSteps ?? this.microSteps,
      microStepsChecked: microStepsChecked ?? this.microStepsChecked,
      stuckSpiciness: stuckSpiciness ?? this.stuckSpiciness,
      stuckReason:
          clearStuckReason ? null : (stuckReason ?? this.stuckReason),
      tinyKey: clearTinyKey ? null : (tinyKey ?? this.tinyKey),
      lowCapacity: lowCapacity ?? this.lowCapacity,
      badDay: badDay ?? this.badDay,
      waitingAppointment: clearWaitingAppointment
          ? null
          : (waitingAppointment ?? this.waitingAppointment),
      waitingWindowMinutes: waitingWindowMinutes ?? this.waitingWindowMinutes,
      waitingActive: waitingActive ?? this.waitingActive,
      showBreather: showBreather ?? this.showBreather,
      trustKept: trustKept ?? this.trustKept,
      trustTotal: trustTotal ?? this.trustTotal,
      pauseSummary: pauseSummary ?? this.pauseSummary,
    );
  }

  @override
  List<Object?> get props => [
        inbox,
        queue,
        doneToday,
        stuckKey,
        microSteps,
        microStepsChecked,
        stuckSpiciness,
        stuckReason,
        tinyKey,
        lowCapacity,
        badDay,
        waitingAppointment,
        waitingWindowMinutes,
        waitingActive,
        showBreather,
        trustKept,
        trustTotal,
        pauseSummary,
      ];
}
