import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/theme/app_colors.dart';
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
  const TriageGridPanel({
    super.key,
    required this.onStart,
    required this.onTiny,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final queue = context.select((FocusFlowCubit c) => c.state.queue);
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
          style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _QuadrantCard(
          title: 'Do it now',
          hint: 'Urgent, and you have the energy. Go.',
          color: AppColors.accent,
          tasks: doNow,
          onStart: onStart,
        ),
        _QuadrantCard(
          title: 'Tiny version',
          hint: 'Urgent but low energy. Shrink it to 2 minutes.',
          color: AppColors.piesPink,
          tasks: tiny,
          onStart: onStart,
          secondaryLabel: 'Tiny it',
          onSecondary: onTiny,
        ),
        _QuadrantCard(
          title: 'Park it',
          hint: 'Not urgent, energy to spare. Pick one when ready.',
          color: AppColors.textSecondary,
          tasks: park,
          onStart: onStart,
        ),
        _QuadrantCard(
          title: 'Not now',
          hint: 'Not urgent, low energy. Snooze one and it comes back later.',
          color: AppColors.textMuted,
          tasks: notNow,
          onStart: onStart,
          secondaryLabel: 'Snooze 2h',
          onSecondary: onSnooze,
        ),
      ],
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
        color: AppColors.surface,
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
                style: AppTypography.labelMd.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Nothing here.',
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
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
          color: AppColors.surfaceVariant,
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
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
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
            const Icon(Icons.play_arrow_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
