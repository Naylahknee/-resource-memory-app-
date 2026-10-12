import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final _speech = stt.SpeechToText();
  bool _listening = false;
  String? _speechNote;

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  /// Voice dump: tap the mic, talk, tap again to stop.
  /// The words land in the field so the user can edit before dumping.
  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    // Initialized lazily so the mic permission prompt only appears on tap.
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _listening = false;
            _speechNote = 'The mic did not work. Try again or just type it.';
          });
        }
      },
    );
    if (!available) {
      if (mounted) {
        setState(() {
          _speechNote =
              'I cannot hear you. Allow the mic for this site in your browser, then tap the mic again.';
        });
      }
      return;
    }
    setState(() {
      _listening = true;
      _speechNote = null;
    });
    await _speech.listen(
      onResult: (result) {
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      },
      listenOptions: stt.SpeechListenOptions(partialResults: true),
    );
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
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
            ),
            const SizedBox(width: 10),
            _MicButton(listening: _listening, onTap: _toggleVoice),
          ],
        ),
        if (_listening) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.piesPink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Listening... tap the mic to stop.',
                style: AppTypography.bodySm.copyWith(color: AppColors.piesPink),
              ),
            ],
          ),
        ],
        if (_speechNote != null && !_listening) ...[
          const SizedBox(height: 10),
          Text(
            _speechNote!,
            style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _dump,
            icon: const Icon(Icons.bolt_outlined),
            label: const Text('Dump it'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: AppTypography.labelLg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (inbox.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Quick tag: two taps each', style: AppTypography.h4),
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

  void _maybeCommit(bool lowCapacity) {
    if (lowCapacity) {
      // Low-capacity day: one tap on urgency is enough, energy defaults low.
      if (_urgency != null) {
        context.read<FocusFlowCubit>().triage(widget.task.id, _urgency!, EnergyLevel.low);
      }
      return;
    }
    if (_urgency != null && _energy != null) {
      context.read<FocusFlowCubit>().triage(widget.task.id, _urgency!, _energy!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowCapacity = context.select((FocusFlowCubit c) => c.state.lowCapacity);
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
                    _maybeCommit(lowCapacity);
                  }),
                ),
            ],
          ),
          if (!lowCapacity) ...[
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
                      _maybeCommit(lowCapacity);
                    }),
                  ),
              ],
            ),
          ],
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
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Mic button beside the brain dump field. Pink and pulsing-look while
/// listening, plain otherwise. Handles "no mic" with a friendly note.
class _MicButton extends StatelessWidget {
  final bool listening;
  final VoidCallback onTap;
  const _MicButton({required this.listening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: listening ? AppColors.piesPink : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: listening ? AppColors.piesPink : AppColors.kBorderColor,
            width: 1.5,
          ),
        ),
        child: Icon(
          listening ? Icons.mic : Icons.mic_none_outlined,
          color: listening ? Colors.white : AppColors.textSecondary,
          semanticLabel: listening ? 'Stop listening' : 'Dictate your dump',
        ),
      ),
    );
  }
}
