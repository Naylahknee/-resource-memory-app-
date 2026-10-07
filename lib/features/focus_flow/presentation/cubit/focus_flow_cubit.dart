import 'package:bloc/bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../commitment/data/commitment_store.dart';
import '../../../commitment/domain/commitment.dart';
import '../../../todo/data/model/todo_hive_model.dart';
import '../../../todo/domain/entities/todo.dart';
import '../../data/focus_store.dart';
import '../../domain/entities/focus_task.dart';
import '../../domain/micro_step_generator.dart';
import 'focus_flow_state.dart';

/// Drives the Focus Flow screens. Everything is local-first; external items
/// (todos, commitments) are projected into the queue read-only.
class FocusFlowCubit extends Cubit<FocusFlowState> {
  FocusFlowCubit() : super(const FocusFlowState());

  Future<void> load() async {
    final inbox = FocusStore.getAll()
        .where((t) => !t.isCompleted && !t.triaged)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final queue = await _buildQueue();
    emit(state.copyWith(
      inbox: inbox,
      queue: queue,
      doneToday: FocusStore.completionsToday(),
    ));
  }


  FocusTaskView? _viewFor(String key) {
    for (final v in state.queue) {
      if (v.key == key) return v;
    }
    return null;
  }

  // ── Brain dump ──────────────────────────────────────────────

  Future<void> brainDump(String text) async {
    final lines = text
        .split('\n')
        .map((l) => l.trim().replaceAll(RegExp(r'^[-*•\d.)\s]+'), ''))
        .where((l) => l.isNotEmpty)
        .toList();
    for (final line in lines) {
      FocusStore.add(line);
    }
    await load();
  }

  Future<void> triage(int id, Urgency urgency, EnergyLevel energy) async {
    final tasks = FocusStore.getAll();
    for (final t in tasks) {
      if (t.id == id) {
        FocusStore.update(t.copyWith(urgency: urgency, energy: energy, triaged: true));
        break;
      }
    }
    await load();
  }

  Future<void> deleteInboxTask(int id) async {
    FocusStore.delete(id);
    await load();
  }

  // ── Focus session ───────────────────────────────────────────

  Future<void> complete(String key) async {
    if (key.startsWith('focus:')) {
      final id = int.tryParse(key.substring(6));
      if (id != null) {
        final tasks = FocusStore.getAll();
        for (final t in tasks) {
          if (t.id == id) {
            FocusStore.update(t.copyWith(completedAt: DateTime.now()));
            break;
          }
        }
      }
    } else {
      // External item: focus-layer resolution only. Never touches the
      // underlying todo/commitment (see FocusStore TODO).
      FocusStore.resolveExternal(key);
    }
    FocusStore.logCompletion(key);
    final microSteps = Map<String, List<String>>.from(state.microSteps)..remove(key);
    final checked = Map<String, Set<int>>.from(state.microStepsChecked)..remove(key);
    emit(state.copyWith(clearStuckKey: true, microSteps: microSteps, microStepsChecked: checked));
    await load();
  }

  /// "Not now": bumps the task to the end of its urgency tier.
  Future<void> skip(String key) async {
    if (key.startsWith('focus:')) {
      final id = int.tryParse(key.substring(6));
      if (id != null) {
        final tasks = FocusStore.getAll();
        for (final t in tasks) {
          if (t.id == id) {
            FocusStore.update(t.copyWith(
              skippedCount: t.skippedCount + 1,
              lastBumpedAt: DateTime.now(),
            ));
            break;
          }
        }
      }
    } else {
      FocusStore.bumpExternal(key);
    }
    emit(state.copyWith(clearStuckKey: true));
    await load();
  }

  // ── "I'm stuck" breakdown ───────────────────────────────────

  void openStuck(String key) {
    final microSteps = Map<String, List<String>>.from(state.microSteps);
    final checked = Map<String, Set<int>>.from(state.microStepsChecked);
    if (!microSteps.containsKey(key)) {
      final view = _viewFor(key);
      if (view == null) return;
      final steps = view.microSteps.isNotEmpty ? view.microSteps : generateMicroSteps(view.title);
      microSteps[key] = steps;
      checked[key] = {
        for (int i = 0; i < view.microStepsDone.length; i++)
          if (view.microStepsDone[i]) i,
      };
      // Persist generated steps on native tasks so they survive restarts.
      if (view.nativeId != null && view.microSteps.isEmpty) {
        final tasks = FocusStore.getAll();
        for (final t in tasks) {
          if (t.id == view.nativeId) {
            FocusStore.update(t.copyWith(
              microSteps: steps,
              microStepsDone: List<bool>.filled(steps.length, false),
            ));
            break;
          }
        }
      }
    }
    emit(state.copyWith(stuckKey: key, microSteps: microSteps, microStepsChecked: checked));
  }

  void closeStuck() => emit(state.copyWith(clearStuckKey: true));

  Future<void> toggleMicroStep(String key, int index) async {
    final checked = Map<String, Set<int>>.from(state.microStepsChecked);
    final set = Set<int>.from(checked[key] ?? {});
    if (set.contains(index)) {
      set.remove(index);
    } else {
      set.add(index);
    }
    checked[key] = set;

    final steps = state.microSteps[key] ?? [];
    final allDone = steps.isNotEmpty && set.length == steps.length;

    // Persist check state on native tasks.
    final view = _viewFor(key);
    if (view?.nativeId != null) {
      final tasks = FocusStore.getAll();
      for (final t in tasks) {
        if (t.id == view!.nativeId) {
          FocusStore.update(t.copyWith(
            microStepsDone: List<bool>.generate(steps.length, (i) => set.contains(i)),
          ));
          break;
        }
      }
    }

    if (allDone) {
      await complete(key);
    } else {
      emit(state.copyWith(microStepsChecked: checked));
    }
  }

  // ── Queue building ──────────────────────────────────────────

  Future<List<FocusTaskView>> _buildQueue() async {
    final views = <FocusTaskView>[];
    final resolved = FocusStore.resolvedExternal.toSet();

    for (final t in FocusStore.getAll()) {
      if (t.isCompleted || !t.triaged) continue;
      views.add(FocusTaskView(
        key: 'focus:${t.id}',
        title: t.title,
        urgency: t.urgency,
        energy: t.energy,
        skippedCount: t.skippedCount,
        lastBumpedAt: t.lastBumpedAt,
        createdAt: t.createdAt,
        microSteps: t.microSteps,
        microStepsDone: t.microStepsDone,
        nativeId: t.id,
      ));
    }

    for (final todo in await _readTodos()) {
      if (todo.isCompleted) continue;
      final key = 'todo:${todo.id}';
      if (resolved.contains(key)) continue;
      final skip = FocusStore.externalSkipState(key);
      views.add(FocusTaskView(
        key: key,
        title: todo.title,
        urgency: _urgencyForDue(todo.dueAt),
        energy: EnergyLevel.medium,
        dueAt: todo.dueAt,
        skippedCount: skip.skippedCount,
        lastBumpedAt: skip.lastBumpedAt,
        createdAt: todo.dueAt,
        isExternal: true,
      ));
    }

    try {
      for (final c in CommitmentStore.getAll()) {
        if (c.status == CommitmentStatus.done || c.status == CommitmentStatus.dismissed) continue;
        final key = 'commitment:${c.id}';
        if (resolved.contains(key)) continue;
        final skip = FocusStore.externalSkipState(key);
        views.add(FocusTaskView(
          key: key,
          title: c.title,
          urgency: _urgencyForDue(c.dueAt),
          energy: EnergyLevel.medium,
          dueAt: c.dueAt,
          skippedCount: skip.skippedCount,
          lastBumpedAt: skip.lastBumpedAt,
          createdAt: c.dueAt,
          isExternal: true,
        ));
      }
    } catch (_) {}

    views.sort(_compareViews);
    return views;
  }

  /// Reads todos defensively: the todo box may not be opened by the current
  /// app flow, and the feature must never break Focus Flow if it is absent.
  Future<List<Todo>> _readTodos() async {
    try {
      const boxName = 'todoBox';
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TodoHiveModelAdapter());
      }
      final Box<TodoHiveModel> box = Hive.isBoxOpen(boxName)
          ? Hive.box<TodoHiveModel>(boxName)
          : await Hive.openBox<TodoHiveModel>(boxName);
      return box.values
          .map((m) => Todo(id: m.id, title: m.title, isCompleted: m.isCompleted, dueAt: m.dueAt ?? DateTime.now()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Urgency _urgencyForDue(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);
    if (d.isBefore(today) || d == today) return Urgency.now;
    return Urgency.soon;
  }

  int _dueRank(FocusTaskView v) {
    final d = v.dueAt;
    if (d == null) return 2;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dd = DateTime(d.year, d.month, d.day);
    if (dd.isBefore(today)) return 0;
    if (dd == today) return 1;
    return 2;
  }

  int _compareViews(FocusTaskView a, FocusTaskView b) {
    final due = _dueRank(a).compareTo(_dueRank(b));
    if (due != 0) return due;
    final urg = b.urgency.index.compareTo(a.urgency.index);
    if (urg != 0) return urg;
    final aB = a.lastBumpedAt;
    final bB = b.lastBumpedAt;
    if (aB == null && bB != null) return -1;
    if (aB != null && bB == null) return 1;
    if (aB != null && bB != null) {
      final c = aB.compareTo(bB);
      if (c != 0) return c;
    }
    return a.createdAt.compareTo(b.createdAt);
  }
}
