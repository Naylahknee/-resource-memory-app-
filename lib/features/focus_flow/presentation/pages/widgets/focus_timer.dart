import 'dart:async';

import 'package:flutter/material.dart';

import 'package:resource_memory/features/widget/todoist_light.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../data/focus_store.dart';

/// Honest focus timer: counts only time actually spent on the task.
///
/// - Ticks while the timer runs and the app is in the foreground on the
///   Focus tab.
/// - Leaving the app (backgrounded, tab hidden) or switching to another
///   tab pauses the focus count and banks the wall-clock time as "away".
///   Away time is shown separately and never counted as focus.
/// - No guilt framing, no streaks, no punishment for time away.
///
/// Focus and away seconds persist per task (local only) so a refresh
/// does not lose the count. The stored time clears when the task is done.
class FocusTimerCard extends StatefulWidget {
  final String taskKey;
  final bool twoMinuteGoal;
  final bool visible;
  const FocusTimerCard({
    super.key,
    required this.taskKey,
    this.twoMinuteGoal = false,
    this.visible = true,
  });

  @override
  State<FocusTimerCard> createState() => _FocusTimerCardState();
}

class _FocusTimerCardState extends State<FocusTimerCard>
    with WidgetsBindingObserver {
  bool _running = false;
  bool _foreground = true;
  int _focusSeconds = 0;
  int _awaySeconds = 0;
  DateTime? _awayStart;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final saved = FocusStore.focusTimeFor(widget.taskKey);
    _focusSeconds = saved.focusSeconds;
    _awaySeconds = saved.awaySeconds;
    // "Make it tiny" arms the 2-minute start: the timer starts with it.
    _running = widget.twoMinuteGoal;
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running || !_foreground || !widget.visible) return;
      if (mounted) {
        setState(() {
          _focusSeconds++;
          // Save every 10 focused seconds so a refresh loses almost nothing.
          if (_focusSeconds % 10 == 0) _save();
        });
      }
    });
  }

  @override
  void didUpdateWidget(FocusTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible && !widget.visible) {
      // Switched away from the Focus tab: bank time as away, not focus.
      _awayStart ??= DateTime.now();
    } else if (!oldWidget.visible && widget.visible) {
      _bankAway();
    }
    // "Make it tiny" just armed the 2-minute start: start the timer.
    if (!oldWidget.twoMinuteGoal && widget.twoMinuteGoal && !_running) {
      setState(() => _running = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _foreground = false;
        _awayStart ??= DateTime.now();
        _save();
      case AppLifecycleState.resumed:
        _foreground = true;
        _bankAway();
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Moves wall-clock time since [_awayStart] into the away counter.
  void _bankAway() {
    final start = _awayStart;
    if (start == null || !mounted) return;
    _awayStart = null;
    final away = DateTime.now().difference(start).inSeconds;
    if (away > 0) {
      setState(() => _awaySeconds += away);
      _save();
    }
  }

  void _save() {
    FocusStore.saveFocusTime(widget.taskKey, _focusSeconds, _awaySeconds);
  }

  void _start() => setState(() => _running = true);

  void _pause() {
    setState(() => _running = false);
    _save();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }

  String _awayLabel(int seconds) {
    if (seconds < 60) return '${seconds}s away';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '${m}m away';
    return '${m}m ${s}s away';
  }

  @override
  Widget build(BuildContext context) {
    final goalReached = widget.twoMinuteGoal && _focusSeconds >= 120;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TodoistLight.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TodoistLight.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: TodoistLight.warm, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Focus time', style: AppTypography.labelLg),
                    Text(
                      widget.twoMinuteGoal
                          ? '2-minute start. Stop after if you want.'
                          : 'Only time on this task counts.',
                      style: AppTypography.bodySm
                          .copyWith(color: TodoistLight.secondary),
                    ),
                  ],
                ),
              ),
              Text(
                _clock(_focusSeconds),
                style: AppTypography.h1.copyWith(fontSize: 36),
              ),
            ],
          ),
          if (goalReached) ...[
            const SizedBox(height: 8),
            Text(
              '2 minutes done. Keep going or stop, either is fine.',
              style: AppTypography.bodyMd.copyWith(color: TodoistLight.warm),
            ),
          ],
          if (_awaySeconds > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${_awayLabel(_awaySeconds)}. Not counted as focus, no worries.',
              style: AppTypography.bodySm
                  .copyWith(color: TodoistLight.secondary),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _running ? _pause : _start,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
              label: Text(_running ? 'Pause' : 'Start focusing'),
              style: FilledButton.styleFrom(
                backgroundColor: TodoistLight.verb,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: AppTypography.labelLg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
