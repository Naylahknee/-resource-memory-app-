import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/theme/app_colors.dart';
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
        final isTiny = state.tinyKey == view.key;
        final steps = state.microSteps[view.key] ?? const <String>[];
        final checked = state.microStepsChecked[view.key] ?? const <int>{};
        final lowCapacity = state.lowCapacity;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            _StatsRow(doneToday: state.doneToday, remaining: state.queue.length),
            const SizedBox(height: 12),
            _LowCapacityToggle(
              value: lowCapacity,
              onChanged: (v) => cubit.setLowCapacity(v),
            ),
            const SizedBox(height: 18),
            Text(
              lowCapacity ? 'Start here, gently.' : 'Start here.',
              style: AppTypography.h2,
            ),
            const SizedBox(height: 4),
            Text(
              lowCapacity
                  ? 'Just one small thing. That counts.'
                  : 'One thing. Not the list. This one.',
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
                      style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  if (view.skippedCount > 0 && !view.cameBack) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Skipped ${view.skippedCount}×. No judgment, still here.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
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
                        backgroundColor: AppColors.accent,
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
                            foregroundColor: isStuck ? AppColors.piesPink : AppColors.textPrimary,
                            side: BorderSide(
                              color: isStuck ? AppColors.piesPink : AppColors.kBorderColor,
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
                        color: isTiny ? AppColors.piesPink : AppColors.textSecondary,
                      ),
                      label: Text(
                        isTiny ? 'Never mind' : 'Make it tiny',
                        style: AppTypography.labelMd.copyWith(
                          color: isTiny ? AppColors.piesPink : AppColors.textSecondary,
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
            Center(
              child: Text(
                lowCapacity
                    ? 'Short list today. One small thing is enough.'
                    : state.queue.length > 1
                        ? '${state.queue.length - 1} more waiting. Finish this one first.'
                        : 'Last one in the queue. Nice.',
                style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
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
    if (d.isBefore(today)) return 'OVERDUE';
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
        color: value ? AppColors.piesPink.withValues(alpha: .10) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.piesPink.withValues(alpha: .45) : AppColors.kBorderColor,
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
                  style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.piesPink,
          ),
        ],
      ),
    );
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
        color: AppColors.piesPink.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.piesPink.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.piesPink, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Just do 2 minutes of:',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.piesPink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: AppTypography.bodyLg),
                const SizedBox(height: 4),
                Text(
                  'Two minutes counts. You can stop after.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textSecondary,
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
  final bool pink;
  const _MetaChip({required this.label, this.highlight = false, this.pink = false});

  @override
  Widget build(BuildContext context) {
    final color = pink ? AppColors.piesPink : highlight ? AppColors.accent : AppColors.textSecondary;
    final borderColor = pink ? AppColors.piesPink : highlight ? AppColors.accent : AppColors.kBorderColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pink
            ? AppColors.piesPink.withValues(alpha: .12)
            : highlight
                ? AppColors.accent.withValues(alpha: .18)
                : AppColors.surfaceVariant,
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
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Text(
            'How tiny should the steps be?',
            style: AppTypography.labelMd.copyWith(color: AppColors.textSecondary),
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
                  activeColor: AppColors.piesPink,
                  inactiveColor: AppColors.kBorderColor,
                  onChanged: (v) => onSpicinessChanged(StepSpiciness.values[v.round()]),
                ),
              ),
              Text('Spicy', style: _spiceLabel(StepSpiciness.spicy)),
            ],
          ),
          Center(
            child: Text(
              _spicinessHint(),
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
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

  TextStyle _spiceLabel(StepSpiciness level) {
    final active = spiciness == level;
    return AppTypography.caption.copyWith(
      color: active ? AppColors.piesPink : AppColors.textMuted,
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
