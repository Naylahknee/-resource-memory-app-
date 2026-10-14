import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/focus_task.dart';
import '../cubit/focus_flow_cubit.dart';
import 'widgets/brain_dump_panel.dart';
import 'widgets/focus_session_panel.dart';
import 'widgets/triage_grid_panel.dart';

/// Focus Flow: the "Act" side of Capture → Understand → Remember → Resurface → Act.
///
/// A focus layer over existing todos/commitments, not a task manager:
/// dump everything, tag in two taps, then see exactly one task at a time.
class FocusFlowScreen extends StatelessWidget {
  const FocusFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FocusFlowCubit()..load(),
      child: const _FocusFlowView(),
    );
  }
}

class _FocusFlowView extends StatefulWidget {
  const _FocusFlowView();

  @override
  State<_FocusFlowView> createState() => _FocusFlowViewState();
}

class _FocusFlowViewState extends State<_FocusFlowView> {
  int _tab = 1; // Start on Focus ("Start here"), not the dump.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('ACT'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.kBorderColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegPill(
                        label: 'DUMP',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                    ),
                    Expanded(
                      child: _SegPill(
                        label: 'FOCUS',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ),
                    Expanded(
                      child: _SegPill(
                        label: 'SORT',
                        selected: _tab == 2,
                        onTap: () => setState(() => _tab = 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  const BrainDumpPanel(),
                  const FocusSessionPanel(),
                  TriageGridPanel(
                    onStart: (task) {
                      final cubit = context.read<FocusFlowCubit>();
                      cubit.bringToFront(task.key);
                      setState(() => _tab = 1);
                    },
                    onTiny: (task) {
                      final cubit = context.read<FocusFlowCubit>();
                      cubit.bringToFront(task.key);
                      cubit.openTiny(task.key);
                      setState(() => _tab = 1);
                    },
                    onSnooze: (task) =>
                        context.read<FocusFlowCubit>().skip(task.key),
                    onPickForMe: () async {
                      final cubit = context.read<FocusFlowCubit>();
                      if (cubit.state.queue.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Nothing in your queue yet. Dump a few things first, then I will pick one.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      final energy = await _showEnergyPicker(context);
                      if (energy == null || !context.mounted) return;
                      final result = cubit.pickForMe(energy: energy);
                      if (!result.picked) return;
                      setState(() => _tab = 1);
                      if (!result.matchedEnergy && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Nothing matches that energy. Picking from everything.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelLg.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// "Pick for me" energy check: two big chips. Returns the picked energy,
/// or null if she dismissed the dialog.
Future<EnergyLevel?> _showEnergyPicker(BuildContext context) {
  return showDialog<EnergyLevel>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('How is your energy?', style: AppTypography.h4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'I will pick something that fits.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _EnergyChoice(
            icon: Icons.bolt_outlined,
            title: 'Lots of energy',
            subtitle: 'Bigger things welcome.',
            onTap: () => Navigator.of(dialogContext).pop(EnergyLevel.high),
          ),
          const SizedBox(height: 10),
          _EnergyChoice(
            icon: Icons.spa_outlined,
            title: 'Running low',
            subtitle: 'Keep it small and gentle.',
            onTap: () => Navigator.of(dialogContext).pop(EnergyLevel.low),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class _EnergyChoice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _EnergyChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLg),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
