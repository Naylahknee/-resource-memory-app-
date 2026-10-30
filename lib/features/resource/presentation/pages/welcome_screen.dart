import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_memory/app/routing/app_route.dart';
import 'package:resource_memory/app/theme/nany_tokens.dart';
import 'package:resource_memory/features/commitment/data/phone_bridge.dart';
import 'package:resource_memory/features/commitment/data/spoken_reminder_service.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';
import 'package:resource_memory/features/resource/data/welcome_store.dart';
import 'package:resource_memory/features/resource/domain/memory_search.dart';
import 'package:resource_memory/features/resource/domain/resource.dart';
import 'package:resource_memory/features/widget/memory_capture_sheet.dart';
import 'package:resource_memory/features/widget/memory_mascot.dart';
import 'package:resource_memory/features/widget/todoist_light.dart';

/// First-launch welcome screen: warm paper canvas,
/// quiet typography, one teal verb. Mascot waves hello below the headline,
/// swipe up to enter. One-way door: once dismissed it never shows again.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.isTour = false});
  final bool isTour;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // NanyNany palette (see nany_tokens.dart).
  static const _canvas = NanyLight.bg;
  static const _ink = NanyLight.ink;
  static const _secondary = NanyLight.inkMuted;
  static const _verb = NanyLight.brand; // NanyNany teal: actions only.

  // Drag state: 0 = resting, negative = dragged upward.
  double _dragOffset = 0;
  double _opacity = 1;
  bool _leaving = false;

  late final AnimationController _hintController;
  late final AnimationController _exitController;
  late final AnimationController _waveController;
class _WelcomeScreenState extends State<WelcomeScreen> {
  late int _step;
  Resource? _memory;
  final _query = TextEditingController();
  MemoryMatch? _match;
  String? _notice;
  bool _busy = false;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _step = widget.isTour ? 0 : WelcomeStore.step;
    final id = WelcomeStore.memoryId;
    _memory = id == null ? null : ResourceStore.getById(id);
    if (_step >= 2 && _memory == null) _step = 1;
  }
  @override
  void dispose() { _query.dispose(); super.dispose(); }

  Future<void> _advance(int step) async {
    await WelcomeStore.saveProgress(step, memoryId: _memory?.id);
    if (mounted) setState(() { _step = step; _notice = null; });
  }
  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    await WelcomeStore.markSeen();
    if (mounted) context.go('/');
  }
  Future<void> _capture() async {
    final before = ResourceStore.getAll().map((r) => r.id).toSet();
    Resource? memory = await showMemoryCapture(context);
    // Dragging away a successful capture must not lose onboarding progress.
    if (memory == null) {
      final added = ResourceStore.getAll().where((r) => !before.contains(r.id));
      if (added.isNotEmpty) memory = added.first;
    }
    if (!mounted || memory == null) return;
    setState(() { _memory = memory; _match = null; _query.clear(); });
    await _advance(2);
  }
  Future<void> _example() async {
    if (_busy) return;
    setState(() => _busy = true);
    // Explicitly chosen example, stored only on this device, without a fake URL.
    final existing = ResourceStore.getById('nanynany-guided-example');
    final example = existing ?? Resource(
      id: 'nanynany-guided-example', title: 'Community funding guide — example',
      platform: 'Guided example', summary: 'A sample article about grants for starting a community. Start with local foundations, then prepare a clear project budget.',
      whyUseful: 'An example for practicing how to save and find a memory.',
      useWhen: 'When planning funding for a community.',
      topics: const ['community', 'funding', 'grants', 'article'],
      type: ResourceType.article, savedAt: DateTime.now(),
    );
    if (existing == null) await ResourceStore.box.put(example.id, example.toMap());
    if (!mounted) return;
    setState(() { _memory = example; _match = null; _query.clear(); _busy = false; });
    await _advance(2);
  }
  void _find() {
    final results = MemorySearch.find(ResourceStore.getAll(), _query.text);
    final chosen = results.where((r) => r.resource.id == _memory?.id);
    setState(() {
      _match = chosen.isEmpty ? null : chosen.first;
      _notice = _match == null ? 'Try a word from the title, source, or topic. Your memory is still saved.' : null;
    });
  }
  Future<void> _speak() async {
    if (_busy) return;
    setState(() { _busy = true; _preview = true; _notice = null; });
    try {
      await SpokenReminderService.speak('This is NanyNany. Here is something you asked me to remember. You can open it, leave it for later, or mark it done.');
    } catch (_) {
      if (mounted) setState(() => _notice = 'Voice playback is unavailable here. The reminder preview below still shows how it works.');
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _permissions() async {
    setState(() => _busy = true);
    try {
      final allowed = await PhoneBridge.requestNotificationPermission();
      if (mounted) setState(() => _notice = allowed ? 'Notifications enabled. You choose which commitments to confirm.' : 'You can enable notifications later in your device settings.');
    } catch (_) {
      if (mounted) setState(() => _notice = 'You can enable notifications later in your device settings.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => TodoistLightScope(child: Scaffold(
    body: GestureDetector(onVerticalDragEnd: (details) {
      if (_step == 0 && !_busy && (details.primaryVelocity ?? 0) < -600) _advance(1);
    }, child: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            if (_step > 0) IconButton(tooltip: 'Previous step', onPressed: _busy ? null : () => _advance(_step - 1), icon: const Icon(Icons.arrow_back)),
            Expanded(child: Text('Step ${_step + 1} of 4', style: const TextStyle(color: TodoistLight.secondary))),
            TextButton(onPressed: _busy ? null : _finish, child: const Text('Skip for now')),
          ]),
          const SizedBox(height: 8),
          Semantics(label: 'Onboarding progress, step ${_step + 1} of 4', child: LinearProgressIndicator(
            value: (_step + 1) / 4, backgroundColor: TodoistLight.hairline, color: TodoistLight.verb, minHeight: 4)),
          const SizedBox(height: 28),
          Center(child: MemoryMascot(mood: switch (_step) {
            0 => MemoryMood.welcome, 1 => MemoryMood.saved,
            2 => _match == null ? MemoryMood.searching : MemoryMood.found,
            _ => MemoryMood.reminder,
          }, size: _step == 0 ? 180 : 104)),
          const SizedBox(height: 20),
          if (_step == 0) ...[
            Text('You don’t have to remember to remember.', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const Text('Save something useful. Find it with the words you remember. Bring it back when you need it.'),
            const SizedBox(height: 28),
            FilledButton(onPressed: () => _advance(1), child: const Text('Get started')),
            const SizedBox(height: 8),
            TextButton(onPressed: _busy ? null : _example, child: const Text('Try a guided example')),
          ],
          if (_step == 1) ...[
            Text('Give me something to remember.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Choose a real link, screenshot, or voice memory—or practice with an example. You can skip setup and save later.'),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _busy ? null : _capture, icon: const Icon(Icons.add), label: const Text('Save my first memory')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _busy ? null : _example, child: Text(_busy ? 'Saving example…' : 'Save the example')),
            if (_memory != null) TextButton(onPressed: () => _advance(2), child: const Text('Continue with my saved memory')),
            const SizedBox(height: 12),
            const Text('The example is labeled as an example in Memory. No account is needed.', style: TextStyle(color: TodoistLight.secondary, fontSize: 13)),
          ],
          if (_step == 2 && _memory != null) ...[
            Text('Now, find it again.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('You saved “${_memory!.title}”. Try the words you remember.'),
            const SizedBox(height: 20),
            TextField(controller: _query, textInputAction: TextInputAction.search, onSubmitted: (_) => _find(),
              decoration: const InputDecoration(labelText: 'What do you remember?', hintText: 'That article about grants')),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: ActionChip(
              label: Text(_memory!.id == 'nanynany-guided-example' ? 'That article about grants' : _memory!.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              onPressed: () { _query.text = _memory!.id == 'nanynany-guided-example' ? 'that article about grants' : _memory!.title; _find(); })),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _find, icon: const Icon(Icons.search), label: const Text('Find my memory')),
            if (_match != null) ...[
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: TodoistLight.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: TodoistLight.hairline)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Found it.', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8), Text(_memory!.title),
                  const SizedBox(height: 8), Text(_memory!.platform ?? _memory!.type.name, style: const TextStyle(color: TodoistLight.secondary)),
                  const SizedBox(height: 12), Text(_match!.explanation),
                ])),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => _advance(3), child: const Text('See how reminders work')),
            ],
          ],
          if (_step == 3) ...[
            Text('A nudge, when you choose it.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Time-sensitive memories need your confirmation. Reminders give you a next step, not just another alert.'),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: TodoistLight.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: TodoistLight.hairline)), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('REMINDER PREVIEW · not scheduled', style: TextStyle(fontSize: 12, color: TodoistLight.secondary)),
                const SizedBox(height: 8), Text(_memory?.title ?? 'A memory you saved'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  TextButton(onPressed: () => setState(() => _notice = 'Preview marked done. Your saved memory stays in Memory.'), child: const Text('Done')),
                  TextButton(onPressed: () => setState(() => _notice = 'Preview left for later. No real reminder was scheduled.'), child: const Text('Later')),
                  if (_memory != null) TextButton(onPressed: () => context.push('/resource/${_memory!.id}'), child: const Text('Open memory')),
                ]),
              ],
            )),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _busy ? null : _speak, icon: const Icon(Icons.volume_up_outlined), label: Text(_busy ? 'Please wait…' : 'Hear the preview')),
            if (_preview) const Padding(padding: EdgeInsets.only(top: 8), child: Text('This is a preview. You control real reminders in Reminders.', style: TextStyle(color: TodoistLight.secondary, fontSize: 13))),
            if (!kIsWeb && PhoneBridge.isIOS) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _busy ? null : _permissions, child: const Text('Enable notifications')),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _busy ? null : _finish, child: const Text('Go to my memory')),
            const SizedBox(height: 8),
            const Text('Sync devices later if you want your memories on another device.', style: TextStyle(color: TodoistLight.secondary, fontSize: 13)),
          ],
          if (_notice != null) Padding(padding: const EdgeInsets.only(top: 16), child: Semantics(liveRegion: true, child: Text(_notice!))),
        ]),
      )),
    ))),
  ));
}
