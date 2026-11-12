import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:resource_memory/features/focus_flow/data/focus_store.dart';
import 'package:resource_memory/features/focus_flow/presentation/cubit/focus_flow_cubit.dart';

/// Cubit-level check for the stolen signal-watch item: a brain dump
/// (voice or text) auto-generates an ordered plan and picks the first
/// task. Plain test, not testWidgets: no widget means no GoogleFonts,
/// which cannot load in the test environment (see the widget-test note
/// in the steal test file's history).
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

  test('brainDump auto-plans and picks the urgent task first', () async {
    final cubit = FocusFlowCubit();
    await cubit.load();
    await cubit.brainDump(
        'Pay electric bill today\nCall mom tomorrow\nLearn Spanish someday');

    // Ordered by urgency: "today" first, "tomorrow" next, no keyword last.
    expect(
      cubit.state.autoPlan.map((t) => t.title).toList(),
      [
        'Pay electric bill today',
        'Call mom tomorrow',
        'Learn Spanish someday',
      ],
    );
    // The picked first task is also the one the Focus tab shows next.
    expect(cubit.state.queue.first.title, 'Pay electric bill today');
    await cubit.close();
  });

  test('brainDump with no urgency words still picks the first line',
      () async {
    final cubit = FocusFlowCubit();
    await cubit.load();
    await cubit.brainDump('Water the plants\nTidy the desk');

    expect(
      cubit.state.autoPlan.map((t) => t.title).toList(),
      ['Water the plants', 'Tidy the desk'],
    );
    expect(cubit.state.queue.first.title, 'Water the plants');
    await cubit.close();
  });
}
