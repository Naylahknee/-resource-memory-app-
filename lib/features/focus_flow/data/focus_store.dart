import 'package:hive_flutter/hive_flutter.dart';

import '../domain/entities/focus_task.dart';
import 'model/focus_task_hive_model.dart';

/// Local persistence for Focus Flow. Static store on purpose: the feature is
/// a thin focus layer, not a managed aggregate, so it does not need DI.
///
/// Boxes:
/// - `focus_task_box`: native [FocusTaskHiveModel]s keyed by id.
/// - `focus_meta_box`: latest id counter, completion timestamps, and
///   focus-layer state for external items (resolved ids, skip counts).
class FocusStore {
  static const taskBoxName = 'focus_task_box';
  static const metaBoxName = 'focus_meta_box';

  static const _latestIdKey = 'latestId';
  static const _completionsKey = 'completions';
  static const _resolvedExternalKey = 'resolvedExternal';
  static const _externalSkipsKey = 'externalSkips';
  static const _lowCapacityKey = 'lowCapacity';

  static Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FocusTaskHiveModelAdapter());
    }
    if (!Hive.isBoxOpen(taskBoxName)) {
      await Hive.openBox<FocusTaskHiveModel>(taskBoxName);
    }
    if (!Hive.isBoxOpen(metaBoxName)) {
      await Hive.openBox(metaBoxName);
    }
  }

  static Box<FocusTaskHiveModel> get _tasks => Hive.box<FocusTaskHiveModel>(taskBoxName);
  static Box get _meta => Hive.box(metaBoxName);

  // ── Native tasks ──────────────────────────────────────────────

  static List<FocusTask> getAll() =>
      _tasks.values.map((m) => m.toDomain()).toList();

  static FocusTask add(String title) {
    final latest = (_meta.get(_latestIdKey, defaultValue: 0) as int?) ?? 0;
    final id = latest + 1;
    final task = FocusTask(
      id: id,
      title: title,
      createdAt: DateTime.now(),
    );
    _tasks.put(id, FocusTaskHiveModel.fromDomain(task));
    _meta.put(_latestIdKey, id);
    return task;
  }

  static void update(FocusTask task) {
    _tasks.put(task.id, FocusTaskHiveModel.fromDomain(task));
  }

  static void delete(int id) => _tasks.delete(id);

  // ── Low-capacity day mode ─────────────────────────────────────

  static bool get isLowCapacity =>
      (_meta.get(_lowCapacityKey, defaultValue: false) as bool?) ?? false;

  static void setLowCapacity(bool value) => _meta.put(_lowCapacityKey, value);

  // ── Completions (simple log: task key + timestamp) ─────────────

  static void logCompletion(String taskKey) {
    final list = List<String>.from(
      (_meta.get(_completionsKey, defaultValue: <String>[]) as List?) ?? <String>[],
    );
    list.add('${DateTime.now().toIso8601String()}|$taskKey');
    _meta.put(_completionsKey, list);
  }

  static int completionsToday() {
    final now = DateTime.now();
    final list = List<String>.from(
      (_meta.get(_completionsKey, defaultValue: <String>[]) as List?) ?? <String>[],
    );
    var count = 0;
    for (final entry in list) {
      final ts = entry.split('|').first;
      final dt = DateTime.tryParse(ts);
      if (dt != null && dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        count++;
      }
    }
    return count;
  }

  // ── External items (todos / commitments): focus-layer only ─────
  //
  // TODO: merge with real completion. Currently completing or skipping an
  // external item only affects Focus Flow state (it stops appearing in the
  // queue). Wiring DONE through to TodoRepository.toggleCompleteTodo and
  // CommitmentStore (status -> done) is a product decision: it would make
  // Focus Flow write to todos/commitments, which the current guardrails
  // forbid (read-only).

  static List<String> get resolvedExternal => List<String>.from(
        (_meta.get(_resolvedExternalKey, defaultValue: <String>[]) as List?) ?? <String>[],
      );

  static void resolveExternal(String key) {
    final list = resolvedExternal;
    if (!list.contains(key)) {
      list.add(key);
      _meta.put(_resolvedExternalKey, list);
    }
  }

  /// Stored as "skippedCount|lastBumpedIso|resurfaceIso" per external key.
  /// Older rows may only have the first two segments; resurface is optional.
  static Map<String, String> get externalSkips => Map<String, String>.from(
        (_meta.get(_externalSkipsKey, defaultValue: <String, String>{}) as Map?) ?? <String, String>{},
      );

  /// "Not now" for an external item: it leaves the queue and comes back
  /// in about 2 hours with a "Came back" badge.
  static void bumpExternal(String key) {
    final map = externalSkips;
    final raw = map[key];
    var count = 0;
    if (raw != null) {
      count = int.tryParse(raw.split('|').first) ?? 0;
    }
    final now = DateTime.now();
    map[key] = '${count + 1}|${now.toIso8601String()}|${now.add(const Duration(hours: 2)).toIso8601String()}';
    _meta.put(_externalSkipsKey, map);
  }

  static ({int skippedCount, DateTime? lastBumpedAt, DateTime? resurfaceAt}) externalSkipState(String key) {
    final raw = externalSkips[key];
    if (raw == null) return (skippedCount: 0, lastBumpedAt: null, resurfaceAt: null);
    final parts = raw.split('|');
    return (
      skippedCount: int.tryParse(parts.first) ?? 0,
      lastBumpedAt: parts.length > 1 ? DateTime.tryParse(parts[1]) : null,
      resurfaceAt: parts.length > 2 ? DateTime.tryParse(parts[2]) : null,
    );
  }
}
