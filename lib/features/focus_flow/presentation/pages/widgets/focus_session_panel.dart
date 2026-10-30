import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:resource_memory/features/widget/todoist_light.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../domain/entities/focus_task.dart';
import '../../../domain/micro_step_generator.dart';
import '../../cubit/focus_flow_cubit.dart';
import '../../cubit/focus_flow_state.dart';

/// Focus session: exactly ONE task visible. "Start here."
/// Big DONE, "Not now" snoozes it for ~2 hours, "I'm stuck"
/// breaks it into ridiculously small steps, "Make it tiny"
/// reframes it as just 2 minutes.
class FocusSessionPanel extends StatelessWidget {
  const FocusSessionPanel({super.key, this.onCapture, this.onSort});
  final VoidCallback? onCapture;
  final VoidCallback? onSort;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusFlowCubit, FocusFlowState>(
      builder: (context, state) {
        final cubit = context.read<FocusFlowCubit>();
        // Buffer rule: after a completion, breathe before the next task.
        if (state.showBreather) {
          return _BreatherScreen(
            doneToday: state.doneToday,
            onDone: () => cubit.dismissBreather(),
          );
        }
        if (state.queue.isEmpty) {
          return _EmptyQueue(inboxCount: state.inbox.length, onCapture: onCapture, onSort: onSort);
        }
        final view = state.queue.first;
        final isStuck = state.stuckKey == view.key;
        final isTiny = state.tinyKey == view.key;
        final steps = state.microSteps[view.key] ?? const <String>[];
        final checked = state.microStepsChecked[view.key] ?? const <int>{};
        final lowCapacity = state.lowCapacity;
        final badDay = state.badDay;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            _StatsRow(doneToday: state.doneToday, remaining: state.queue.length),
            const SizedBox(height: 12),
            _LowCapacityToggle(
              value: lowCapacity,
              onChanged: (v) => cubit.setLowCapacity(v),
            ),
            const SizedBox(height: 10),
            _BadDayToggle(
              value: badDay,
              onChanged: (v) => cubit.setBadDay(v),
            ),
            const SizedBox(height: 18),
            Text(
              lowCapacity ? 'Start here, gently.' : 'Start here.',
              style: AppTypography.h2,
            ),
            const SizedBox(height: 4),
            Text(
              badDay
                  ? 'The rest can wait. Just this one.'
                  : lowCapacity
                      ? 'Just one small thing. That counts.'
                      : 'One thing. Not the list. This one.',
              style: AppTypography.bodyMd.copyWith(color: TodoistLight.secondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: TodoistLight.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TodoistLight.verb.withValues(alpha: .45), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (view.cameBack)
                        const _MetaChip(label: 'CAME BACK', pink: true),
                      _MetaChip(label: view.urgency.name.toUpperCase(), highlight: view.urgency == Urgency.now),
                      if (!lowCapacity) _MetaChip(label: '${view.energy.name.toUpperCase()} ENERGY'),
                      if (view.dueAt != null) _MetaChip(label: _dueLabel(view.dueAt!)),
                      if (view.isExternal)
                        const _MetaChip(label: 'FROM YOUR LISTS'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(view.title, style: AppTypography.h1.copyWith(height: 1.25)),
                  if (view.cameBack) ...[
                    const SizedBox(height: 8),
                    Text(
                      'You set this one aside. It is back, no rush.',
                      style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
                    ),
                  ],
                  if (view.skippedCount > 0 && !view.cameBack) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Skipped ${view.skippedCount}×. No judgment, still here.',
                      style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
                    ),
                  ],
                  if (isTiny) ...[
                    const SizedBox(height: 16),
                    _TinyBanner(
                      title: view.title,
                      onDismiss: () => cubit.closeTiny(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => cubit.complete(view.key),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('DONE'),
                      style: FilledButton.styleFrom(
                        backgroundColor: TodoistLight.verb,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        textStyle: AppTypography.h3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final reason = await _showPauseReasonDialog(context);
                            if (reason == null || !context.mounted) return;
                            if (reason.isEmpty) {
                              cubit.skip(view.key);
                            } else {
                              cubit.skipWithReason(view.key, reason);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TodoistLight.secondary,
                            side: BorderSide(color: TodoistLight.hairline),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Not now'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (isStuck) {
                              cubit.closeStuck();
                              return;
                            }
                            final reason = await _showPauseReasonDialog(context);
                            if (reason == null || !context.mounted) return;
                            if (reason.isEmpty) {
                              cubit.openStuck(view.key);
                            } else {
                              cubit.openStuckWithReason(view.key, reason);
                            }
                          },
                          icon: Icon(isStuck ? Icons.expand_less : Icons.psychology_outlined),
                          label: Text(isStuck ? 'Hide steps' : "I'm stuck"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isStuck ? TodoistLight.warm : TodoistLight.ink,
                            side: BorderSide(
                              color: isStuck ? TodoistLight.warm : TodoistLight.hairline,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => isTiny ? cubit.closeTiny() : cubit.openTiny(view.key),
                      icon: Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: isTiny ? TodoistLight.warm : TodoistLight.secondary,
                      ),
                      label: Text(
                        isTiny ? 'Never mind' : 'Make it tiny',
                        style: AppTypography.labelMd.copyWith(
                          color: isTiny ? TodoistLight.warm : TodoistLight.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showLogWinDialog(context),
                      icon: const Icon(
                        Icons.add_task_outlined,
                        size: 18,
                        color: TodoistLight.secondary,
                      ),
                      label: Text(
                        'Already did it',
                        style: AppTypography.labelMd.copyWith(
                          color: TodoistLight.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (isStuck) ...[
                    const SizedBox(height: 12),
                    _StuckBreakdown(
                      steps: steps,
                      checked: checked,
                      spiciness: state.stuckSpiciness,
                      onToggle: (i) => cubit.toggleMicroStep(view.key, i),
                      onSpicinessChanged: (s) => cubit.setStuckSpiciness(view.key, s),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Gentle self-trust score: tiny, ignorable, never red, never shaming.
            if (state.trustKept > 0) ...[
              Center(
                child: Text(
                  'Kept ${state.trustKept} of ${state.trustTotal} this week. Every kept one counts.',
                  style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Center(
              child: Text(
                lowCapacity
                    ? 'Short list today. One small thing is enough.'
                    : state.queue.length > 1
                        ? '${state.queue.length - 1} more waiting. Finish this one first.'
                        : 'Last one in the queue. Nice.',
                style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);
    if (d.isBefore(today)) return 'STILL OPEN';
    if (d == today) return 'DUE TODAY';
    return 'DUE ${_monthDay(d)}';
  }

  String _monthDay(DateTime d) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _LowCapacityToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  const _LowCapacityToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: value ? TodoistLight.warm.withValues(alpha: .10) : TodoistLight.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? TodoistLight.warm.withValues(alpha: .45) : TodoistLight.hairline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Low-capacity day', style: AppTypography.labelLg),
                Text(
                  'One small thing is enough today.',
                  style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: TodoistLight.warm,
          ),
        ],
      ),
    );
  }
}

class _BadDayToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  const _BadDayToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: value ? TodoistLight.verb.withValues(alpha: .10) : TodoistLight.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? TodoistLight.verb.withValues(alpha: .45) : TodoistLight.hairline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rough day', style: AppTypography.labelLg),
                Text(
                  'Only one task shows. The rest can wait.',
                  style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: TodoistLight.verb,
          ),
        ],
      ),
    );
  }
}

/// "Already did it": lets the user log something they already finished.
/// It lands directly as a completed task, timestamped now.
Future<void> _showLogWinDialog(BuildContext context) async {
  final controller = TextEditingController();
  final cubit = context.read<FocusFlowCubit>();
  final submitted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('What did you already do?', style: AppTypography.h4),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
        style: AppTypography.bodyLg,
        decoration: InputDecoration(
          hintText: 'Made the dentist appointment',
          hintStyle: AppTypography.bodyLg.copyWith(color: TodoistLight.secondary.withValues(alpha: .5)),
          filled: true,
          fillColor: TodoistLight.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: TodoistLight.hairline),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: TodoistLight.verb,
            foregroundColor: Colors.white,
          ),
          child: const Text('Log it'),
        ),
      ],
    ),
  );
  final text = controller.text.trim();
  controller.dispose();
  if (submitted == true && text.isNotEmpty && context.mounted) {
    await cubit.logWin(text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged. That is a win.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TinyBanner extends StatelessWidget {
  final String title;
  final VoidCallback onDismiss;
  const _TinyBanner({required this.title, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TodoistLight.warm.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TodoistLight.warm.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_outlined, color: TodoistLight.warm, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Just do 2 minutes of:',
                  style: AppTypography.labelMd.copyWith(
                    color: TodoistLight.warm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: AppTypography.bodyLg),
                const SizedBox(height: 4),
                Text(
                  'Two minutes counts. You can stop after.',
                  style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18),
            color: TodoistLight.secondary,
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int doneToday;
  final int remaining;
  const _StatsRow({required this.doneToday, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TodoistLight.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 18, color: TodoistLight.verb),
              const SizedBox(width: 8),
              Text('$doneToday done today', style: AppTypography.labelLg),
            ],
          ),
          Text('$remaining in queue', style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool highlight;
  final bool pink;
  const _MetaChip({required this.label, this.highlight = false, this.pink = false});

  @override
  Widget build(BuildContext context) {
    final color = pink ? TodoistLight.warm : highlight ? TodoistLight.verb : TodoistLight.secondary;
    final borderColor = pink ? TodoistLight.warm : highlight ? TodoistLight.verb : TodoistLight.hairline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pink
            ? TodoistLight.warm.withValues(alpha: .12)
            : highlight
                ? TodoistLight.verb.withValues(alpha: .18)
                : TodoistLight.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StuckBreakdown extends StatelessWidget {
  final List<String> steps;
  final Set<int> checked;
  final StepSpiciness spiciness;
  final void Function(int) onToggle;
  final void Function(StepSpiciness) onSpicinessChanged;
  const _StuckBreakdown({
    required this.steps,
    required this.checked,
    required this.spiciness,
    required this.onToggle,
    required this.onSpicinessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TodoistLight.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TodoistLight.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Okay. Forget the whole thing. Just do step one:',
            style: AppTypography.bodyMd.copyWith(color: TodoistLight.secondary),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < steps.length; i++)
            InkWell(
              onTap: () => onToggle(i),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      checked.contains(i) ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: checked.contains(i) ? TodoistLight.verb : TodoistLight.secondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: AppTypography.bodyLg.copyWith(
                          decoration: checked.contains(i) ? TextDecoration.lineThrough : null,
                          color: checked.contains(i) ? TodoistLight.secondary : TodoistLight.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Text(
            'How tiny should the steps be?',
            style: AppTypography.labelMd.copyWith(color: TodoistLight.secondary),
          ),
          Row(
            children: [
              Text('Gentle', style: _spiceLabel(StepSpiciness.gentle)),
              Expanded(
                child: Slider(
                  value: spiciness.index.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  activeColor: TodoistLight.warm,
                  inactiveColor: TodoistLight.hairline,
                  onChanged: (v) => onSpicinessChanged(StepSpiciness.values[v.round()]),
                ),
              ),
              Text('Spicy', style: _spiceLabel(StepSpiciness.spicy)),
            ],
          ),
          Center(
            child: Text(
              _spicinessHint(),
              style: AppTypography.caption.copyWith(color: TodoistLight.secondary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check them all and the task is done.',
            style: AppTypography.caption.copyWith(color: TodoistLight.secondary),
          ),
        ],
      ),
    );
  }

  TextStyle _spiceLabel(StepSpiciness level) {
    final active = spiciness == level;
    return AppTypography.caption.copyWith(
      color: active ? TodoistLight.warm : TodoistLight.muted,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
    );
  }

  String _spicinessHint() {
    switch (spiciness) {
      case StepSpiciness.gentle:
        return 'Gentle: a couple of big, forgiving steps.';
      case StepSpiciness.spicy:
        return 'Spicy: lots of tiny steps. Silly small counts.';
      case StepSpiciness.medium:
        return 'Medium: a comfortable handful of steps.';
    }
  }
}

class _EmptyQueue extends StatelessWidget {
  final int inboxCount;
  const _EmptyQueue({required this.inboxCount, this.onCapture, this.onSort});
  final VoidCallback? onCapture;
  final VoidCallback? onSort;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement_outlined, size: 56, color: TodoistLight.verb),
            const SizedBox(height: 16),
            Text('One thing at a time.', style: AppTypography.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              inboxCount > 0
                  ? 'You have $inboxCount dumped item${inboxCount == 1 ? '' : 's'} waiting for a quick tag.'
                  : 'Nothing queued yet. Capture what is on your mind, then choose one small thing.',
              style: AppTypography.bodyMd.copyWith(color: TodoistLight.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (inboxCount > 0 && onSort != null)
              FilledButton(onPressed: onSort, child: const Text('Choose one thing'))
            else if (onCapture != null)
              FilledButton(onPressed: onCapture, child: const Text('Capture what’s on my mind')),
          ],
        ),
      ),
    );
  }
}

/// Buffer rule screen: after a task is done, a 60-second breather before
/// the next task appears. Skip is always visible. Never traps the user.
class _BreatherScreen extends StatefulWidget {
  final int doneToday;
  final VoidCallback onDone;
  const _BreatherScreen({required this.doneToday, required this.onDone});

  @override
  State<_BreatherScreen> createState() => _BreatherScreenState();
}

class _BreatherScreenState extends State<_BreatherScreen> {
  static const _total = 60;
  int _left = _total;
  Timer? _timer;

  static const _suggestions = [
    'Get some water.',
    'Roll your shoulders.',
    'Look out a window for a bit.',
    'Shake your hands out.',
    'Take three slow breaths.',
  ];

  late final String _suggestion =
      (List<String>.of(_suggestions)..shuffle()).first;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        t.cancel();
        widget.onDone();
      } else if (mounted) {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: TodoistLight.verb),
            const SizedBox(height: 16),
            Text('Done. Nice.', style: AppTypography.h1, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              widget.doneToday > 0
                  ? 'That is ${widget.doneToday} done today.'
                  : 'One done.',
              style: AppTypography.bodyMd.copyWith(color: TodoistLight.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _left / _total,
                    strokeWidth: 10,
                    backgroundColor: TodoistLight.surfaceVariant,
                    color: TodoistLight.verb,
                  ),
                  Text(
                    '$_left',
                    style: AppTypography.h1.copyWith(fontSize: 44),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Take a breather.', style: AppTypography.h4),
            const SizedBox(height: 6),
            Text(
              _suggestion,
              style: AppTypography.bodyMd.copyWith(color: TodoistLight.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: TodoistLight.verb,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: AppTypography.h3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Skip the breather'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The next task appears when the timer ends.',
              style: AppTypography.caption.copyWith(color: TodoistLight.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pause reasons: quick, private pattern-spotting. Stored locally only,
/// shown back as one gentle line on the Sort tab.
const _pauseReasons = [
  'Need a moment',
  'Too big',
  'Wrong energy',
  'Waiting on someone',
];

/// Quick reason chips before a "Not now" or "I'm stuck" dismisses.
///
/// Returns the picked reason, '' to go ahead without logging one,
/// or null if she dismissed the dialog (then nothing happens).
Future<String?> _showPauseReasonDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('What is going on?', style: AppTypography.h4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Just for you. No judgment, and this stays private.',
            style: AppTypography.bodyMd.copyWith(color: TodoistLight.secondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in _pauseReasons)
                InkWell(
                  onTap: () => Navigator.of(dialogContext).pop(reason),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: TodoistLight.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: TodoistLight.hairline),
                    ),
                    child: Text(reason, style: AppTypography.labelMd),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(''),
          child: const Text('Just skip'),
        ),
      ],
    ),
  );
}
