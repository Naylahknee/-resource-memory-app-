import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../domain/entities/focus_task.dart';
import '../../cubit/focus_flow_cubit.dart';

/// Brain dump: rapid capture of everything in your head, one per line.
/// New items land in the triage inbox; two taps (urgency + energy) move
/// each one into the focus queue.
class BrainDumpPanel extends StatefulWidget {
  const BrainDumpPanel({super.key});

  @override
  State<BrainDumpPanel> createState() => _BrainDumpPanelState();
}

class _BrainDumpPanelState extends State<BrainDumpPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dump() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<FocusFlowCubit>().brainDump(text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.select((FocusFlowCubit c) => c.state.inbox);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text('Get it out of your head.', style: AppTypography.h2),
        const SizedBox(height: 6),
        Text(
          'Dump everything. One per line. You will sort it in two taps each.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLines: 5,
          minLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _dump(),
          style: AppTypography.bodyLg,
          decoration: InputDecoration(
            hintText: 'Reply to Sam\nPay electric bill\nClean the kitchen\n…',
            hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.textSecondary.withValues(alpha: .5)),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _dump,
            icon: const Icon(Icons.bolt_outlined),
            label: const Text('Dump it'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: AppTypography.labelLg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (inbox.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Quick tag — two taps each', style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            'How urgent? How much energy? Then it joins your queue.',
            style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          for (final task in inbox) _TriageRow(task: task),
        ],
      ],
    );
  }
}

class _TriageRow extends StatefulWidget {
  final FocusTask task;
  const _TriageRow({required this.task});

  @override
  State<_TriageRow> createState() => _TriageRowState();
}

class _TriageRowState extends State<_TriageRow> {
  Urgency? _urgency;
  EnergyLevel? _energy;

  void _maybeCommit() {
    if (_urgency != null && _energy != null) {
      context.read<FocusFlowCubit>().triage(widget.task.id, _urgency!, _energy!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.task.title, style: AppTypography.bodyLg)),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textSecondary,
                onPressed: () => context.read<FocusFlowCubit>().deleteInboxTask(widget.task.id),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final u in Urgency.values.reversed)
                _Chip(
                  label: u.name.toUpperCase(),
                  selected: _urgency == u,
                  onTap: () => setState(() {
                    _urgency = u;
                    _maybeCommit();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final e in EnergyLevel.values)
                _Chip(
                  label: '${e.name.toUpperCase()} ENERGY',
                  selected: _energy == e,
                  onTap: () => setState(() {
                    _energy = e;
                    _maybeCommit();
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.kBorderColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: selected ? Colors.black : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
