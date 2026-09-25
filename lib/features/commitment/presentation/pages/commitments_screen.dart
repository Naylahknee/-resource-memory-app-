import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/commitment/data/commitment_memory_store.dart';

class CommitmentsScreen extends StatefulWidget {
  const CommitmentsScreen({super.key});

  @override
  State<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends State<CommitmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final pending = CommitmentMemoryStore.instance.pending;
    final upcoming = CommitmentMemoryStore.instance.upcoming;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Remember'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Text('Things you said you would do.', style: AppTypography.h2),
          const SizedBox(height: 6),
          Text(
            'NanyNany keeps time-sensitive commitments separate from the things you save for later.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          _SectionLabel(label: 'NEEDS YOUR OK', count: pending.length),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            const _EmptyCard(message: 'Nothing is waiting for confirmation.')
          else
            _CommitmentGroup(
              items: pending,
              trailingBuilder: (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => setState(() => CommitmentMemoryStore.instance.dismiss(item.id)),
                    child: const Text('Not this'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () => setState(() => CommitmentMemoryStore.instance.confirm(item.id)),
                    child: const Text('Remember'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
          _SectionLabel(label: 'COMING UP', count: upcoming.length),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            const _EmptyCard(message: 'Confirmed reminders will appear here.')
          else
            _CommitmentGroup(
              items: upcoming,
              trailingBuilder: (item) => IconButton(
                tooltip: 'Done',
                onPressed: () => setState(() => CommitmentMemoryStore.instance.complete(item.id)),
                icon: const Icon(Icons.check_circle_outline),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: AppTypography.labelLg.copyWith(color: AppColors.textMuted)),
      const SizedBox(width: 8),
      Text('$count', style: AppTypography.labelLg.copyWith(color: AppColors.textMuted)),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
  );
}

class _CommitmentGroup extends StatelessWidget {
  const _CommitmentGroup({required this.items, required this.trailingBuilder});
  final List<CommitmentMemory> items;
  final Widget Function(CommitmentMemory item) trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _CommitmentRow(item: items[i], trailing: trailingBuilder(items[i])),
            if (i < items.length - 1)
              Divider(height: 1, indent: 16, color: AppColors.kBorderColor),
          ],
        ],
      ),
    );
  }
}

class _CommitmentRow extends StatelessWidget {
  const _CommitmentRow({required this.item, required this.trailing});
  final CommitmentMemory item;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    title: Text(item.title),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(item.whenLabel),
        if (item.sourceLabel.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(item.sourceLabel, style: TextStyle(color: AppColors.textMuted)),
        ],
      ],
    ),
    trailing: trailing,
  );
}
