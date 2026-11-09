import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:resource_memory/features/widget/todoist_light.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../cubit/focus_flow_cubit.dart';

/// Waiting mode: the hours before an appointment, when big tasks freeze.
///
/// The user sets the appointment time by hand (no calendar reading).
/// Waiting mode kicks in a set window before it (2 hours by default,
/// changeable when setting the appointment). During the window, big tasks
/// stay out of the queue and only tiny, low-stakes steps are offered,
/// with a countdown to the appointment. When the appointment time passes,
/// the normal queue returns.
class WaitingModeCard extends StatefulWidget {
  final DateTime? appointment;
  final int windowMinutes;
  final bool active;
  const WaitingModeCard({
    super.key,
    required this.appointment,
    required this.windowMinutes,
    required this.active,
  });

  @override
  State<WaitingModeCard> createState() => _WaitingModeCardState();
}

class _WaitingModeCardState extends State<WaitingModeCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh the countdown and catch window start/end while open.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      final appointment = widget.appointment;
      if (appointment == null) return;
      final now = DateTime.now();
      if (!mounted) return;
      if (!now.isBefore(appointment)) {
        // Appointment passed: reload so the normal queue returns and
        // the appointment clears itself.
        context.read<FocusFlowCubit>().load();
        return;
      }
      final shouldBeActive = !now.isBefore(appointment
          .subtract(Duration(minutes: widget.windowMinutes)));
      if (shouldBeActive != widget.active) {
        // Window just started or (defensively) ended: rebuild the queue.
        context.read<FocusFlowCubit>().load();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _timeLabel(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour12:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _appointmentLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final time = _timeLabel(dt);
    if (day == today) return 'Today $time';
    if (day == today.add(const Duration(days: 1))) return 'Tomorrow $time';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[dt.weekday - 1]} ${months[dt.month - 1]} ${dt.day}, $time';
  }

  String _countdown(Duration d) {
    if (d.isNegative) return 'now';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes >= 1) return '${d.inMinutes}m';
    return 'under a minute';
  }

  String _windowLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes % 60 == 0) {
      final h = minutes ~/ 60;
      return h == 1 ? '1 hour' : '$h hours';
    }
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  Future<void> _setAppointment() async {
    final result = await showWaitingSetupDialog(
      context,
      currentAppointment: widget.appointment,
      currentWindowMinutes: widget.windowMinutes,
    );
    if (result == null || !mounted) return;
    await context.read<FocusFlowCubit>().setWaitingAppointment(
          result.appointment,
          windowMinutes: result.windowMinutes,
        );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.active
            ? TodoistLight.verb.withValues(alpha: .08)
            : TodoistLight.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.active
              ? TodoistLight.verb.withValues(alpha: .45)
              : TodoistLight.hairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_available_outlined,
              color: TodoistLight.secondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appointment == null) ...[
                  Text('Waiting mode', style: AppTypography.labelLg),
                  Text(
                    'Got an appointment coming up? Set it and only tiny steps show before it.',
                    style: AppTypography.bodySm
                        .copyWith(color: TodoistLight.secondary),
                  ),
                ] else if (widget.active) ...[
                  Text('Waiting mode is on', style: AppTypography.labelLg),
                  Text(
                    'Appointment in ${_countdown(appointment.difference(DateTime.now()))}. Only tiny steps until then. The rest of the queue is waiting.',
                    style: AppTypography.bodySm
                        .copyWith(color: TodoistLight.secondary),
                  ),
                ] else ...[
                  Text('Appointment ${_appointmentLabel(appointment)}',
                      style: AppTypography.labelLg),
                  Text(
                    'Waiting mode starts ${_windowLabel(widget.windowMinutes)} before, at ${_timeLabel(appointment.subtract(Duration(minutes: widget.windowMinutes)))}. Starts in ${_countdown(appointment.subtract(Duration(minutes: widget.windowMinutes)).difference(DateTime.now()))}.',
                    style: AppTypography.bodySm
                        .copyWith(color: TodoistLight.secondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (appointment == null)
            TextButton(
              onPressed: _setAppointment,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Set appointment',
                style: AppTypography.labelMd.copyWith(
                  color: TodoistLight.verb,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _setAppointment,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Change',
                    style: AppTypography.labelMd.copyWith(
                      color: TodoistLight.verb,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context
                      .read<FocusFlowCubit>()
                      .clearWaitingAppointment(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear',
                    style: AppTypography.labelMd.copyWith(
                      color: TodoistLight.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The setup dialog: pick a day, a time, and how long before it waiting
/// mode kicks in. Returns the picked appointment and window, or null
/// when dismissed.
Future<({DateTime appointment, int windowMinutes})?> showWaitingSetupDialog(
  BuildContext context, {
  required DateTime? currentAppointment,
  required int currentWindowMinutes,
}) {
  final now = DateTime.now();
  // Default: an hour from now (rolls to tomorrow when it is late).
  final defaultWhen = now.add(const Duration(hours: 1));
  DateTime pickedDate = currentAppointment != null
      ? DateTime(currentAppointment.year, currentAppointment.month,
          currentAppointment.day)
      : DateTime(defaultWhen.year, defaultWhen.month, defaultWhen.day);
  TimeOfDay pickedTime = currentAppointment != null
      ? TimeOfDay(
          hour: currentAppointment.hour, minute: currentAppointment.minute)
      : TimeOfDay(hour: defaultWhen.hour, minute: 0);
  int pickedWindow = currentWindowMinutes;
  String? error;

  String dateLabel(DateTime d) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (day == today) return 'Today, ${months[d.month - 1]} ${d.day}';
    if (day == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${months[d.month - 1]} ${d.day}';
    }
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String timeLabel(TimeOfDay t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$hour12:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  const windowOptions = [30, 60, 120, 180, 360];
  String windowOptionLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    return h == 1 ? '1 hour' : '$h hours';
  }

  return showDialog<({DateTime appointment, int windowMinutes})>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text('Set an appointment', style: AppTypography.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Before it, only tiny steps show. The normal queue comes back after.',
              style: AppTypography.bodyMd
                  .copyWith(color: TodoistLight.secondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: dialogContext,
                  initialDate: pickedDate,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setDialogState(() {
                    pickedDate = picked;
                    error = null;
                  });
                }
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(dateLabel(pickedDate)),
              style: OutlinedButton.styleFrom(
                foregroundColor: TodoistLight.ink,
                side: BorderSide(color: TodoistLight.hairline),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: dialogContext,
                  initialTime: pickedTime,
                );
                if (picked != null) {
                  setDialogState(() {
                    pickedTime = picked;
                    error = null;
                  });
                }
              },
              icon: const Icon(Icons.access_time_outlined, size: 18),
              label: Text(timeLabel(pickedTime)),
              style: OutlinedButton.styleFrom(
                foregroundColor: TodoistLight.ink,
                side: BorderSide(color: TodoistLight.hairline),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting mode starts:',
              style: AppTypography.labelMd
                  .copyWith(color: TodoistLight.secondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in windowOptions)
                  InkWell(
                    onTap: () =>
                        setDialogState(() => pickedWindow = minutes),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: pickedWindow == minutes
                            ? TodoistLight.verb.withValues(alpha: .12)
                            : TodoistLight.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: pickedWindow == minutes
                              ? TodoistLight.verb
                              : TodoistLight.hairline,
                        ),
                      ),
                      child: Text(
                        windowOptionLabel(minutes),
                        style: AppTypography.labelMd.copyWith(
                          color: pickedWindow == minutes
                              ? TodoistLight.verb
                              : TodoistLight.ink,
                          fontWeight: pickedWindow == minutes
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: AppTypography.bodySm.copyWith(color: TodoistLight.warm),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final combined = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              if (combined.isBefore(DateTime.now())) {
                setDialogState(() {
                  error = 'That time has already passed. Pick a time ahead.';
                });
                return;
              }
              Navigator.of(dialogContext)
                  .pop((appointment: combined, windowMinutes: pickedWindow));
            },
            style: FilledButton.styleFrom(
              backgroundColor: TodoistLight.verb,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
