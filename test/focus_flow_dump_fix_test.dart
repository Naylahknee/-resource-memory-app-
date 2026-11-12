import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:resource_memory/features/focus_flow/data/focus_store.dart';
import 'package:resource_memory/features/focus_flow/domain/entities/focus_task.dart';
import 'package:resource_memory/features/focus_flow/presentation/cubit/focus_flow_cubit.dart';

/// Regression tests for the Nov 11 live tap-through failures:
///
/// 1. Pitch line: hidden whenever bad-day or low-capacity mode is on
///    (gated on `!badDay && !lowCapacity` in the panel). Fixed by
///    rendering it unconditionally; covered by code inspection + the
///    live bundle check, not here, because widget tests cannot run
///    in this environment (GoogleFonts network fetch).
///
/// 2. Dump-to-plan: the plan was built by filtering the mode-truncated
///    queue, so in rough-day mode (queue = 1 item) a dump produced no
///    plan card and the dumped tasks were invisible everywhere
///    (triaged, so not in the inbox; truncated out of the queue).
///    The plan was also in-memory only, so it vanished on reload.
///    Fixed by building the plan from the dumped tasks themselves and
///    persisting the plan ids in the store.
void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp();
    Hive.init(temp.path);
    await FocusStore.initialize();
  });

  tearDown(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });

  /// Waits until [check] is true or [timeout] passes, polling the
  /// cubit's state the way the UI does (no await on the dump call).
  Future<void> waitFor(
    FocusFlowCubit cubit,
    bool Function() check, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!check()) {
      if (DateTime.now().isAfter(deadline)) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(check(), isTrue);
  }

  test('dump in rough-day mode still produces a plan', () async {
    // Live session state: a pre-existing task already on top, and
    // rough-day mode on (persisted toggle), so the queue is 1 item.
    final existing = FocusStore.add('Reply to Sam');
    FocusStore.update(existing.copyWith(
      triaged: true,
      urgency: Urgency.now,
    ));
    FocusStore.setBadDay(true);

    final cubit = FocusFlowCubit();
    await cubit.load();
    expect(cubit.state.badDay, isTrue);
    expect(cubit.state.queue.map((t) => t.title).toList(), ['Reply to Sam']);

    await cubit.brainDump(
        'email the landlord today\nbuy milk\nfinish the report tomorrow');

    // The dumped tasks are in the store, triaged.
    expect(FocusStore.getAll().length, 3 + 1);
    // The plan holds the dumped items in queue order, first one picked,
    // even though rough-day mode caps the visible queue at one item.
    expect(
      cubit.state.autoPlan.map((t) => t.title).toList(),
      [
        'email the landlord today',
        'finish the report tomorrow',
        'buy milk',
      ],
    );
    // The picked first task is also the one the Focus tab shows next,
    // and the rough-day cap of one visible task still holds.
    expect(cubit.state.queue.length, 1);
    expect(cubit.state.queue.first.title, 'email the landlord today');
    await cubit.close();
  });

  test('dump in low-capacity mode still produces a full plan', () async {
    FocusStore.setLowCapacity(true);
    final cubit = FocusFlowCubit();
    await cubit.load();
    await cubit.brainDump(
        'email the landlord today\nbuy milk\nfinish the report tomorrow');

    // Low-capacity caps the visible queue at 3, but the plan still
    // holds all three dumped items.
    expect(cubit.state.autoPlan.length, 3);
    expect(
      cubit.state.autoPlan.map((t) => t.title).toList(),
      [
        'email the landlord today',
        'finish the report tomorrow',
        'buy milk',
      ],
    );
    await cubit.close();
  });

  test('the plan survives a fresh cubit load (reload)', () async {
    final first = FocusFlowCubit();
    await first.load();
    await first.brainDump(
        'email the landlord today\nbuy milk\nfinish the report tomorrow');
    expect(first.state.autoPlan.length, 3);
    await first.close();

    // Same store, new cubit: what the app does on restart.
    final second = FocusFlowCubit();
    await second.load();
    expect(
      second.state.autoPlan.map((t) => t.title).toList(),
      [
        'email the landlord today',
        'finish the report tomorrow',
        'buy milk',
      ],
    );
    await second.close();
  });

  test('a new dump replaces the previous plan', () async {
    final cubit = FocusFlowCubit();
    await cubit.load();
    await cubit.brainDump('Water the plants');
    expect(
      cubit.state.autoPlan.map((t) => t.title).toList(),
      ['Water the plants'],
    );
    await cubit.brainDump('Book the flights');
    expect(
      cubit.state.autoPlan.map((t) => t.title).toList(),
      ['Book the flights'],
    );
    await cubit.close();
  });

  test('dump called the way the UI calls it (unawaited) still plans',
      () async {
    final cubit = FocusFlowCubit();
    await cubit.load();
    // The panel fires brainDump without awaiting it, then clears the box.
    // ignore: unawaited_futures
    cubit.brainDump(
        'email the landlord today\nbuy milk\nfinish the report tomorrow');
    await waitFor(cubit, () => cubit.state.autoPlan.length == 3);
    expect(
      cubit.state.autoPlan.map((t) => t.title).toList(),
      [
        'email the landlord today',
        'finish the report tomorrow',
        'buy milk',
      ],
    );
    expect(FocusStore.getAll().length, 3);
    await cubit.close();
  });

  test('starting the plan shows the picked task even in rough-day mode',
      () async {
    final existing = FocusStore.add('Reply to Sam');
    FocusStore.update(existing.copyWith(
      triaged: true,
      urgency: Urgency.now,
    ));
    FocusStore.setBadDay(true);

    final cubit = FocusFlowCubit();
    await cubit.load();
    await cubit.brainDump(
        'email the landlord today\nbuy milk\nfinish the report tomorrow');
    final picked = cubit.state.autoPlan.first.key;

    cubit.bringToFront(picked);
    expect(cubit.state.queue.first.key, picked);
    expect(cubit.state.queue.first.title, 'email the landlord today');
    await cubit.close();
  });
}
