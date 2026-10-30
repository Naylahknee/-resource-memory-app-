import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:resource_memory/features/commitment/data/commitment_store.dart';
import 'package:resource_memory/features/commitment/domain/commitment.dart';
import 'package:resource_memory/features/resource/data/memory_surface_store.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';
import 'package:resource_memory/features/resource/domain/memory_search.dart';
import 'package:resource_memory/features/resource/domain/resource.dart';
import 'package:resource_memory/features/widget/memory_capture_sheet.dart';
import 'package:resource_memory/features/widget/memory_card.dart';
import 'package:resource_memory/features/widget/memory_mascot.dart';
import 'package:resource_memory/features/widget/todoist_light.dart';

class ResourceHomeScreen extends StatefulWidget {
  const ResourceHomeScreen({super.key});
  @override
  State<ResourceHomeScreen> createState() => _ResourceHomeScreenState();
}

class _ResourceHomeScreenState extends State<ResourceHomeScreen> {
  final _query = TextEditingController();
  @override
  void dispose() { _query.dispose(); super.dispose(); }
  void _find([String? query]) {
    final value = (query ?? _query.text).trim();
    if (value.isNotEmpty) context.go('/library?q=${Uri.encodeComponent(value)}');
  }

  Future<void> _later(Resource memory, bool lessOften) async {
    await MemorySurfaceStore.later(memory.id, lessOften: lessOften);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lessOften
        ? 'This memory will stay out of suggestions for two weeks.'
        : 'We’ll leave this memory until tomorrow.')));
  }

  @override
  Widget build(BuildContext context) => TodoistLightScope(child: Scaffold(
    body: SafeArea(child: ValueListenableBuilder<Box<Map>>(
      valueListenable: ResourceStore.box.listenable(),
      builder: (context, _, __) => ValueListenableBuilder<Box<Map>>(
        valueListenable: CommitmentStore.box.listenable(),
        builder: (context, _, __) {
          final memories = ResourceStore.getAll().where((r) => r.status != ResourceStatus.archived).toList();
          final commitments = CommitmentStore.getAll().where((c) => c.status != CommitmentStatus.done && c.status != CommitmentStatus.dismissed).toList();
          final now = DateTime.now();
          final available = memories.where((r) => MemorySurfaceStore.eligible(r.id, now)).toList();
          final suggestions = <({Resource memory, String reason})>[];
          for (final commitment in commitments.where((c) => c.status != CommitmentStatus.needsConfirmation && c.dueAt.isBefore(now.add(const Duration(days: 7))))) {
            for (final match in MemorySearch.find(available, commitment.title).take(1)) {
              if (suggestions.any((s) => s.memory.id == match.resource.id)) continue;
              suggestions.add((memory: match.resource, reason: 'Matches your reminder “${commitment.title}”.'));
            }
          }
          final older = available.where((r) => now.difference(r.savedAt).inDays >= 2).toList()
            ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
          for (final memory in older) {
            if (suggestions.any((s) => s.memory.id == memory.id)) continue;
            suggestions.add((memory: memory, reason: 'Saved ${now.difference(memory.savedAt).inDays} days ago. A chance to revisit it.'));
            if (suggestions.length >= 3) break;
          }
          return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Your memory, when you need it.', style: Theme.of(context).textTheme.headlineMedium)),
                IconButton(tooltip: 'Sync devices', onPressed: () => context.push('/sync'), icon: const Icon(Icons.cloud_sync_outlined)),
              ]),
              const SizedBox(height: 8),
              const Text('Useful links, screenshots, ideas, and commitments. Together, with their context.'),
              const SizedBox(height: 24),
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
                color: TodoistLight.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: TodoistLight.hairline)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Save it before it slips away.', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('One place for something Future You may need.'),
                    const SizedBox(height: 20),
                    FilledButton.icon(onPressed: () => showMemoryCapture(context), icon: const Icon(Icons.add), label: const Text('Save something')),
                  ])),
                  if (MediaQuery.sizeOf(context).width >= 650) const Padding(padding: EdgeInsets.only(left: 20), child: MemoryMascot(size: 140)),
                ]),
              ),
              const SizedBox(height: 28),
              Text('What are you trying to find?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: _query, textInputAction: TextInputAction.search, onSubmitted: _find,
                decoration: InputDecoration(labelText: 'Search your memory', hintText: 'A title, source, or words you remember', prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(tooltip: 'Find memories', onPressed: _find, icon: const Icon(Icons.arrow_forward)))),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ActionChip(label: const Text('Screenshots'), onPressed: () => _find('screenshot')),
                ActionChip(label: const Text('Voice memories'), onPressed: () => _find('voice')),
                TextButton(onPressed: () => context.push('/project-match'), child: const Text('Find resources for something I’m doing')),
              ]),
              const SizedBox(height: 28),
              if (memories.isEmpty) ...[
                Text('A little less to hold in your head.', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Save your first memory, or try a guided example to see how saving and finding work.'),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () => context.push('/welcome?tour=1'), child: const Text('Try a guided example')),
              ] else ...[
                Text(suggestions.isEmpty ? 'Saved recently' : 'Useful again', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final suggestion in suggestions.take(3)) Padding(padding: const EdgeInsets.only(bottom: 12), child: MemoryCard(
                  memory: suggestion.memory, reason: suggestion.reason,
                  onLater: () => _later(suggestion.memory, false), onLessOften: () => _later(suggestion.memory, true))),
                if (suggestions.isEmpty) for (final memory in memories.take(3)) Padding(padding: const EdgeInsets.only(bottom: 12), child: MemoryCard(memory: memory)),
              ],
              const SizedBox(height: 20),
              TextButton(onPressed: () => context.go('/commitments'), child: Text('${commitments.where((c) => c.status != CommitmentStatus.needsConfirmation).length} confirmed reminders · Review reminders')),
              TextButton(onPressed: () => context.push('/welcome?tour=1'), child: const Text('Practice saving and finding')),
            ]),
          )));
        },
      ),
    )),
  ));
}
