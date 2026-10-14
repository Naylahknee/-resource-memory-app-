import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:resource_memory/features/widget/todoist_light.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../domain/entities/focus_task.dart';
import '../../cubit/focus_flow_cubit.dart';

/// 4-box view of the triaged queue: urgency x energy, in plain words.
/// A view only. Tapping a task sends it to the front of the queue and
/// opens the Focus tab, so the 2-tap triage flow stays exactly as it is.
class TriageGridPanel extends StatelessWidget {
  final void Function(FocusTaskView task) onStart;
  final void Function(FocusTaskView task) onTiny;
  final void Function(FocusTaskView task) onSnooze;
  final void Function() onPickForMe;
  const TriageGridPanel({
    super.key,
    required this.onStart,
    required this.onTiny,
    required this.onSnooze,
    required this.onPickForMe,
  });

  @override
  Widget build(BuildContext context) {
    final queue = context.select((FocusFlowCubit c) => c.state.queue);
    final badDay = context.select((FocusFlowCubit c) => c.state.badDay);
    final pauseSummary = context.select((FocusFlowCubit c) => c.state.pauseSummary);
    final doNow = <FocusTaskView>[];
    final tiny = <FocusTaskView>[];
    final park = <FocusTaskView>[];
    final notNow = <FocusTaskView>[];
    for (final t in queue) {
      final urgent = t.urgency == Urgency.now;
      final hasEnergy =
          t.energy == EnergyLevel.medium || t.energy == EnergyLevel.high;
      if (urgent && hasEnergy) {
        doNow.add(t);
      } else if (urgent) {
        tiny.add(t);
      } else if (hasEnergy) {
        park.add(t);
      } else {
        notNow.add(t);
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text('Your queue, sorted.', style: AppTypography.h2),
        const SizedBox(height: 6),
        Text(
          'Tap any task to start it.',
          style: AppTypography.bodyMd.copyWith(color: TodoistLight.secondary),
        ),
        // Quiet pattern-spotting: only shows once she has logged reasons.
        if (pauseSummary != null) ...[
          const SizedBox(height: 4),
          Text(
            'Lately: mostly "$pauseSummary".',
            style: AppTypography.caption.copyWith(color: TodoistLight.muted),
          ),
        ],
        const SizedBox(height: 12),
        _RoughDayToggle(
          value: badDay,
          onChanged: (v) => context.read<FocusFlowCubit>().setBadDay(v),
        ),
        if (badDay) ...[
          const SizedBox(height: 10),
          Text(
            'Rough day on. Only your top task is showing. The rest can wait.',
            style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPickForMe,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Pick for me'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TodoistLight.ink,
              side: BorderSide(color: TodoistLight.hairline),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: AppTypography.labelLg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Can't decide? I'll choose one.",
          style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _QuadrantCard(
          title: 'Do it now',
          hint: 'Urgent, and you have the energy. Go.',
          color: TodoistLight.verb,
          tasks: doNow,
          onStart: onStart,
        ),
        _QuadrantCard(
          title: 'Tiny version',
          hint: 'Urgent but low energy. Shrink it to 2 minutes.',
          color: TodoistLight.warm,
          tasks: tiny,
          onStart: onStart,
          secondaryLabel: 'Tiny it',
          onSecondary: onTiny,
        ),
        _QuadrantCard(
          title: 'Park it',
          hint: 'Not urgent, energy to spare. Pick one when ready.',
          color: TodoistLight.secondary,
          tasks: park,
          onStart: onStart,
        ),
        _QuadrantCard(
          title: 'Not now',
          hint: 'Not urgent, low energy. Snooze one and it comes back later.',
          color: TodoistLight.muted,
          tasks: notNow,
          onStart: onStart,
          secondaryLabel: 'Snooze 2h',
          onSecondary: onSnooze,
        ),
      ],
    );
  }
}

/// Compact "Rough day" toggle for the triage screen. Same behavior as the
/// one on the Focus tab: only the single most important task stays visible.
class _RoughDayToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  const _RoughDayToggle({required this.value, required this.onChanged});

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

class _QuadrantCard extends StatelessWidget {
  final String title;
  final String hint;
  final Color color;
  final List<FocusTaskView> tasks;
  final void Function(FocusTaskView task) onStart;
  final String? secondaryLabel;
  final void Function(FocusTaskView task)? onSecondary;
  const _QuadrantCard({
    required this.title,
    required this.hint,
    required this.color,
    required this.tasks,
    required this.onStart,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TodoistLight.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.h4),
              const Spacer(),
              Text(
                '${tasks.length}',
                style: AppTypography.labelMd.copyWith(color: TodoistLight.secondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: AppTypography.bodySm.copyWith(color: TodoistLight.secondary),
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Nothing here.',
              style: AppTypography.bodySm.copyWith(color: TodoistLight.muted),
            ),
          ] else ...[
            const SizedBox(height: 10),
            for (final t in tasks)
              _TaskRow(
                task: t,
                color: color,
                onStart: () => onStart(t),
                secondaryLabel: secondaryLabel,
                onSecondary: onSecondary == null ? null : () => onSecondary!(t),
              ),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final FocusTaskView task;
  final Color color;
  final VoidCallback onStart;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  const _TaskRow({
    required this.task,
    required this.color,
    required this.onStart,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onStart,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: TodoistLight.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: AppTypography.bodyLg),
                  const SizedBox(height: 2),
                  Text(
                    '${task.urgency.name.toUpperCase()} · ${task.energy.name.toUpperCase()} ENERGY',
                    style: AppTypography.caption.copyWith(color: TodoistLight.muted),
                  ),
                ],
              ),
            ),
            if (secondaryLabel != null && onSecondary != null)
              TextButton(
                onPressed: onSecondary,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  secondaryLabel!,
                  style: AppTypography.labelMd.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const Icon(Icons.play_arrow_rounded, color: TodoistLight.secondary),
          ],
        ),
      ),
    );
  }
}
