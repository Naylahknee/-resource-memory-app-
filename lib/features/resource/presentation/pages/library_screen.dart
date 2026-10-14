import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';
import 'package:resource_memory/features/resource/domain/resource.dart';
import 'package:resource_memory/features/resource/domain/memory_search.dart';
import 'package:resource_memory/features/widget/memory_capture_sheet.dart';
import 'package:resource_memory/features/widget/memory_card.dart';
import 'package:resource_memory/features/widget/memory_mascot.dart';
import 'package:resource_memory/features/widget/todoist_light.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final TextEditingController _search;
  String _query = '';
  ResourceType? _filter;
  @override
  void initState() { super.initState(); _query = widget.initialQuery; _search = TextEditingController(text: _query); }
  @override
  void didUpdateWidget(LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) { _query = widget.initialQuery; _search.text = _query; }
  }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _delete(Resource memory) async {
    await ResourceStore.remove(memory.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed ${memory.title}'), action: SnackBarAction(
      label: 'Undo', onPressed: () => ResourceStore.save(memory))));
  }
  Future<void> _filters() => showModalBottomSheet<void>(context: context, useRootNavigator: true, useSafeArea: true,
    backgroundColor: TodoistLight.canvas, builder: (context) => Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Filter memories', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(label: const Text('All'), selected: _filter == null, onSelected: (_) { setState(() => _filter = null); Navigator.pop(context); }),
          for (final type in ResourceType.values) ChoiceChip(label: Text(type == ResourceType.session ? 'Tab sessions' : type.name), selected: _filter == type,
            onSelected: (_) { setState(() => _filter = type); Navigator.pop(context); }),
        ]),
      ])));

  @override
  Widget build(BuildContext context) => TodoistLightScope(child: Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 980), child: Padding(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Your memory', style: Theme.of(context).textTheme.headlineSmall)),
          IconButton(tooltip: 'Save something', onPressed: () => showMemoryCapture(context), icon: const Icon(Icons.add)),
        ]),
        const SizedBox(height: 8),
        const Text('Everything you asked NanyNany to remember, with its original context.'),
        const SizedBox(height: 20),
        TextField(controller: _search, onChanged: (value) => setState(() => _query = value.trim()), textInputAction: TextInputAction.search,
          decoration: InputDecoration(labelText: 'Search your memory', hintText: 'A title, source, or words you remember', prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty ? null : IconButton(tooltip: 'Clear search', onPressed: () { _search.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close)))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          ChoiceChip(label: const Text('All'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
          ChoiceChip(label: const Text('Screenshots'), selected: _filter == ResourceType.screenshot, onSelected: (_) => setState(() => _filter = ResourceType.screenshot)),
          TextButton.icon(onPressed: _filters, icon: const Icon(Icons.tune, size: 18), label: Text(_filter == null || _filter == ResourceType.screenshot ? 'More filters' : _filter!.name)),
        ]),
        const SizedBox(height: 16),
        Expanded(child: ValueListenableBuilder<Box<Map>>(valueListenable: ResourceStore.box.listenable(), builder: (context, _, __) {
          final all = ResourceStore.getAll().where((r) => r.status != ResourceStatus.archived).toList();
          final matches = _query.isEmpty ? <MemoryMatch>[] : MemorySearch.find(all, _query);
          final candidates = _query.isEmpty ? all : matches.map((m) => m.resource).toList();
          final memories = candidates.where((r) => _filter == null || r.type == _filter).toList();
          if (memories.isEmpty) return SingleChildScrollView(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(children: [
            const MemoryMascot(mood: MemoryMood.searching),
            const SizedBox(height: 16),
            Text(all.isEmpty ? 'Nothing saved yet.' : 'No matching memory yet.', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(all.isEmpty ? 'Save something once. Its context stays here with it.' : 'Try a title, source, or topic, or clear the filters.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (all.isEmpty) ...[
              FilledButton(onPressed: () => showMemoryCapture(context), child: const Text('Save my first memory')),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.push('/welcome?tour=1'), child: const Text('Try a guided example')),
            ] else OutlinedButton(onPressed: () { _search.clear(); setState(() { _query = ''; _filter = null; }); }, child: const Text('Clear search and filters')),
          ])))));
          return ListView.separated(itemCount: memories.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, index) {
            final memory = memories[index];
            final reason = _query.isEmpty ? null : matches.firstWhere((m) => m.resource.id == memory.id).explanation;
            return MemoryCard(memory: memory, reason: reason, onDelete: () => _delete(memory));
          });
        })),
      ],
    )),
  )))));
}
