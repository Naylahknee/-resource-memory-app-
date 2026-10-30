import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_memory/features/resource/data/resource_enrichment_service.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';
import 'package:resource_memory/features/resource/domain/resource.dart';
import 'package:resource_memory/features/resource/presentation/pages/save_resource_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/voice_memory_screen.dart';
import 'memory_mascot.dart';
import 'todoist_light.dart';

Future<Resource?> showMemoryCapture(BuildContext context) => showModalBottomSheet<Resource>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: TodoistLight.canvas,
  constraints: const BoxConstraints(maxWidth: 560),
  sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(duration: Duration(milliseconds: 260), reverseDuration: Duration(milliseconds: 180)),
  builder: (_) => const TodoistLightScope(child: _CaptureSheet()),
);

class _CaptureSheet extends StatefulWidget {
  const _CaptureSheet();
  @override
  State<_CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<_CaptureSheet> {
  final _link = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _syncNote;
  Resource? _saved;
  @override
  void dispose() { _link.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_busy) return;
    if (_link.text.trim().isEmpty) {
      setState(() => _error = 'Paste a link, or choose an image or voice memory.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    Resource? attempted;
    try {
      final url = _link.text.trim();
      final draft = await ResourceEnrichmentService.enrich(url);
      final now = DateTime.now();
      final memory = Resource(
        id: now.microsecondsSinceEpoch.toString(), title: draft.title, url: url,
        creator: draft.creator, platform: draft.platform, summary: draft.summary,
        whyUseful: draft.whyUseful, useWhen: draft.useWhen, thumbnail: draft.thumbnail,
        type: draft.type, topics: draft.topics, technologies: draft.technologies, savedAt: now,
      );
      attempted = memory;
      await ResourceStore.save(memory);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() => _saved = memory);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        if (attempted != null && ResourceStore.getById(attempted.id) != null) {
          setState(() { _saved = attempted; _syncNote = 'Saved on this device. Cloud sync failed; you can retry in Sync devices.'; });
        } else {
          setState(() => _error = 'Could not save this link. Your link is still here; try again.');
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(bool voice) async {
    if (_busy) return;
    final memory = await Navigator.of(context).push<Resource>(MaterialPageRoute(
      builder: (_) => voice
          ? const VoiceMemoryScreen(returnSavedResource: true)
          : const SaveResourceScreen(returnSavedResource: true, imageFirst: true),
    ));
    if (mounted && memory != null) setState(() => _saved = memory);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text(_saved == null ? 'Save something' : 'Remembered.', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(tooltip: _saved == null ? 'Close capture' : 'Done',
                onPressed: _busy ? null : () => Navigator.pop(context, _saved), icon: const Icon(Icons.close)),
            ]),
            if (_saved case final memory?) ...[
              const Center(child: MemoryMascot(mood: MemoryMood.saved)),
              Text(memory.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Saved in Memory. You can find it by its title, source, or the words you remember.'),
              if (_syncNote != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_syncNote!)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.pop(context, memory), child: const Text('Done')),
            ] else ...[
              const Text('A link, screenshot, or voice memory. No folders to choose.'),
              const SizedBox(height: 20),
              TextField(controller: _link, enabled: !_busy, keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done, onSubmitted: (_) => _save(),
                decoration: InputDecoration(labelText: 'Link', hintText: 'https://…', errorText: _error, prefixIcon: const Icon(Icons.link))),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: _busy ? null : _save,
                icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bookmark_add_outlined),
                label: Text(_busy ? 'Saving…' : 'Save link')),
              const SizedBox(height: 20),
              Wrap(spacing: 12, runSpacing: 8, children: [
                OutlinedButton.icon(onPressed: _busy ? null : () => _import(false), icon: const Icon(Icons.image_outlined), label: const Text('Image')),
                OutlinedButton.icon(onPressed: _busy ? null : () => _import(true), icon: const Icon(Icons.mic_none), label: const Text('Voice')),
                TextButton(onPressed: _busy ? null : () { Navigator.pop(context); context.push('/save-resource'); }, child: const Text('More capture options')),
              ]),
            ],
          ],
        )),
      ),
    );
  }
}
