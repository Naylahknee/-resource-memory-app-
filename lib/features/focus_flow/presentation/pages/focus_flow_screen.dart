import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../cubit/focus_flow_cubit.dart';
import 'widgets/brain_dump_panel.dart';
import 'widgets/focus_session_panel.dart';

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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  BrainDumpPanel(),
                  FocusSessionPanel(),
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
