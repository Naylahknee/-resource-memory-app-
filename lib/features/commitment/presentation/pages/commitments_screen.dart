import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/commitment/data/commitment_store.dart';
import 'package:taskee/features/commitment/domain/commitment.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class CommitmentsScreen extends StatefulWidget {
  const CommitmentsScreen({super.key});
  @override State<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends State<CommitmentsScreen> {
  List<Commitment> get items => CommitmentStore.getAll();

  Future<void> _setStatus(Commitment c, CommitmentStatus status) async {
    await CommitmentStore.save(c.copyWith(status: status));
    if (mounted) setState(() {});
  }

  @override Widget build(BuildContext context) {
    final pending = items.where((e) => e.status == CommitmentStatus.needsConfirmation).toList();
    final active = items.where((e) => e.status != CommitmentStatus.needsConfirmation && e.status != CommitmentStatus.done && e.status != CommitmentStatus.dismissed).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('What am I forgetting?')),
      body: AppGradient(child: SafeArea(child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Commitment memory', style: AppTypography.h2),
          const SizedBox(height: 8),
          Text('Appointments, meetings and deadlines stay active until you acknowledge them.', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          if (pending.isNotEmpty) ...[
            Text('POSSIBLE COMMITMENTS', style: AppTypography.labelLg.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 10),
            ...pending.map((c) => _CommitmentCard(c: c, confirm: () => _setStatus(c, CommitmentStatus.upcoming), dismiss: () => _setStatus(c, CommitmentStatus.dismissed))),
            const SizedBox(height: 22),
          ],
          Text('UPCOMING', style: AppTypography.labelLg.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 10),
          if (active.isEmpty) Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.kBorderColor)),
            child: Text('Nothing needs your attention right now.', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
          ),
          ...active.map((c) => _CommitmentCard(c: c, ready: () => _setStatus(c, CommitmentStatus.ready), done: () => _setStatus(c, CommitmentStatus.done))),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: .72), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.kBorderColor)),
            child: Text('Email + Calendar connection is the next layer. Resource Memory will detect possible commitments, ask before adding them, then use persistent spoken prompts when action is due.', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ))),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  final Commitment c;
  final VoidCallback? confirm, dismiss, ready, done;
  const _CommitmentCard({required this.c, this.confirm, this.dismiss, this.ready, this.done});

  @override Widget build(BuildContext context) {
    final local = c.dueAt.toLocal();
    final when = MaterialLocalizations.of(context).formatMediumDate(local) + ' · ' + TimeOfDay.fromDateTime(local).format(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.kBorderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.title, style: AppTypography.h3),
        const SizedBox(height: 6),
        Text(when, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
        if (c.detail != null) ...[const SizedBox(height: 6), Text(c.detail!, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary))],
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (confirm != null) FilledButton(onPressed: confirm, child: const Text('Add')),
          if (dismiss != null) TextButton(onPressed: dismiss, child: const Text('Not important')),
          if (ready != null) FilledButton(onPressed: ready, child: const Text("I'm ready")),
          if (done != null) OutlinedButton(onPressed: done, child: const Text('Done')),
        ]),
      ]),
    );
  }
}
