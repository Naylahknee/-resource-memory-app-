import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_memory/features/resource/domain/resource.dart';
import 'package:resource_memory/features/resource/data/resource_link_service.dart';
import 'todoist_light.dart';

class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.memory, this.reason, this.onLater, this.onLessOften, this.onDelete});
  final Resource memory;
  final String? reason;
  final VoidCallback? onLater;
  final VoidCallback? onLessOften;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) {
    final source = [memory.platform, memory.creator].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final date = MaterialLocalizations.of(context).formatMediumDate(memory.savedAt.toLocal());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TodoistLight.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: TodoistLight.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(memory.title, style: Theme.of(context).textTheme.titleLarge)),
          if (onDelete != null || onLessOften != null)
            PopupMenuButton<String>(tooltip: 'Memory options', onSelected: (value) {
              if (value == 'less') onLessOften?.call();
              if (value == 'delete') onDelete?.call();
            }, itemBuilder: (_) => [
              if (onLessOften != null) const PopupMenuItem(value: 'less', child: Text('Show less often')),
              if (onDelete != null) const PopupMenuItem(value: 'delete', child: Text('Delete memory')),
            ]),
        ]),
        const SizedBox(height: 4),
        Text('${source.isEmpty ? memory.type.name : source} · Saved $date', style: const TextStyle(color: TodoistLight.secondary, fontSize: 12)),
        if (memory.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(memory.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
        if (reason != null) ...[
          const SizedBox(height: 12),
          Text('Why this appeared: $reason', style: const TextStyle(color: TodoistLight.secondary, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 4, children: [
          TextButton.icon(onPressed: () => context.push('/resource/${memory.id}'), icon: const Icon(Icons.bookmark_outline), label: const Text('Open memory')),
          if (ResourceLinkService.normalize(memory.url) != null)
            TextButton.icon(onPressed: () => ResourceLinkService.open(context, memory.url), icon: const Icon(Icons.open_in_new, size: 18), label: const Text('Open source')),
          if (onLater != null) TextButton(onPressed: onLater, child: const Text('Later')),
        ]),
      ]),
    );
  }
}
