import 'package:flutter/services.dart';

/// Syncs the Act-side "Start here" task to the phone's lock screen.
///
/// iOS: writes the current task into the App Group shared container and asks
/// WidgetKit to reload the lock-screen widget.
/// Android: updates a persistent low-priority notification, which is what
/// Android shows on the lock screen (Android has no iOS-style lock-screen
/// widgets).
///
/// Everything here is fire-and-forget: if the native side is unavailable
/// (tests, desktop builds), the app keeps working and the lock screen
/// simply does not update.
class LockScreenSync {
  static const _channel = MethodChannel('com.naylahknee.nanynany/lockscreen');

  /// Pushes the current "Start here" task to the lock screen.
  /// A null or blank title clears the lock screen instead.
  /// [dueAtMs] is the task's due time in epoch milliseconds; the lock screen
  /// shows it in 24-hour military time when present.
  static Future<void> syncCurrentTask(
      {String? title, String? key, int? dueAtMs}) async {
    try {
      final trimmed = title?.trim() ?? '';
      if (trimmed.isEmpty) {
        await _channel.invokeMethod<void>('clearCurrentTask');
      } else {
        await _channel.invokeMethod<void>('syncCurrentTask', {
          'title': trimmed,
          'key': key ?? '',
          'dueAtMs': dueAtMs,
        });
      }
    } catch (_) {
      // Native side unavailable. Never break the app for the widget.
    }
  }

  /// True when the app was opened from the lock-screen widget or
  /// notification. One-shot: the native side clears it on read.
  static Future<bool> consumePendingFocusLink() async {
    try {
      final value = await _channel.invokeMethod<String>('getPendingFocusLink');
      return value == 'focus';
    } catch (_) {
      return false;
    }
  }
}
