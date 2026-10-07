import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../domain/entities/focus_task.dart';
import '../../cubit/focus_flow_cubit.dart';
import '../../cubit/focus_flow_state.dart';

/// Focus session: exactly ONE task visible. "Start here."
/// Big DONE, "Not now" bumps it to the end of the queue, "I'm stuck"
/// breaks it into ridiculously small steps.
class FocusSessionPanel extends StatelessWidget {
  const FocusSessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusFlowCubit, FocusFlowState>(
      builder: (context, state) {
        if (state.queue.isEmpty) {
          return _EmptyQueue(inboxCount: state.inbox.length);
        }
        final view = state.queue.first;
        final cubit = context.read<FocusFlowCubit>();
        final isStuck = state.stuckKey == view.key;
        final steps = state.microSteps[view.key] ?? const <String>[];
        final checked = state.microStepsChecked[view.key] ?? const <int>{};

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            _StatsRow(doneToday: state.doneToday, remaining: state.queue.length),
            const SizedBox(height: 18),
            Text('Start here.', style: AppTypography.h2),
            const SizedBox(height: 4),
            Text(
              'One thing. Not the list. This one.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accent.withValues(alpha: .45), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(label: view.urgency.name.toUpperCase(), highlight: view.urgency == Urgency.now),
                      _MetaChip(label: '${view.energy.name.toUpperCase()} ENERGY'),
                      if (view.dueAt != null) _MetaChip(label: _dueLabel(view.dueAt!)),
                      if (view.isExternal)
                        const _MetaChip(label: 'FROM YOUR LISTS'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(view.title, style: AppTypography.h1.copyWith(height: 1.25)),
                  if (view.skippedCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Skipped ${view.skippedCount}× — no judgment, still here.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
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
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
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
                          onPressed: () => cubit.skip(view.key),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.kBorderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Not now'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => isStuck ? cubit.closeStuck() : cubit.openStuck(view.key),
                          icon: Icon(isStuck ? Icons.expand_less : Icons.psychology_outlined),
                          label: Text(isStuck ? 'Hide steps' : "I'm stuck"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isStuck ? AppColors.accent : AppColors.textPrimary,
                            side: BorderSide(
                              color: isStuck ? AppColors.accent : AppColors.kBorderColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isStuck) ...[
                    const SizedBox(height: 16),
                    _StuckBreakdown(
                      steps: steps,
                      checked: checked,
                      onToggle: (i) => cubit.toggleMicroStep(view.key, i),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                state.queue.length > 1
                    ? '${state.queue.length - 1} more waiting — finish this one first.'
                    : 'Last one in the queue. Nice.',
                style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
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
    if (d.isBefore(today)) return 'OVERDUE';
    if (d == today) return 'DUE TODAY';
    return 'DUE ${_monthDay(d)}';
  }

  String _monthDay(DateTime d) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[d.month - 1]} ${d.day}';
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
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('$doneToday done today', style: AppTypography.labelLg),
            ],
          ),
          Text('$remaining in queue', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool highlight;
  const _MetaChip({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? AppColors.accent.withValues(alpha: .18) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight ? AppColors.accent : AppColors.kBorderColor,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: highlight ? AppColors.accent : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StuckBreakdown extends StatelessWidget {
  final List<String> steps;
  final Set<int> checked;
  final void Function(int) onToggle;
  const _StuckBreakdown({required this.steps, required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Okay. Forget the whole thing. Just do step one:',
            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
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
                      color: checked.contains(i) ? AppColors.accent : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: AppTypography.bodyLg.copyWith(
                          decoration: checked.contains(i) ? TextDecoration.lineThrough : null,
                          color: checked.contains(i) ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Check them all and the task is done.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  final int inboxCount;
  const _EmptyQueue({required this.inboxCount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement_outlined, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text('All clear.', style: AppTypography.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              inboxCount > 0
                  ? 'You have $inboxCount dumped item${inboxCount == 1 ? '' : 's'} waiting for a quick tag.'
                  : 'Nothing in the queue. Dump what is on your mind and start here.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
