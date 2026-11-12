import 'entities/focus_task.dart';

/// Auto-plan: after a brain dump, order the dumped lines and pick the
/// first one, without asking two taps per item.
///
/// Urgency comes from keywords in the line itself. Energy defaults to
/// medium, the safe middle. The queue's own sort then orders the plan:
/// due items first, then urgency, then the order they were dumped in.
///
/// Pure local heuristics, no network. The goal is a plan in seconds,
/// not a perfect one: the user can still re-tag anything by hand.
Urgency urgencyForDumpedTitle(String title) {
  final words = title
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.isNotEmpty)
      .toSet();
  final t = title.toLowerCase();

  // Single words match whole-word only, so "know" does not trip "now".
  const nowWords = {
    'today',
    'now',
    'urgent',
    'asap',
    'deadline',
    'due',
    'overdue',
  };
  if (words.intersection(nowWords).isNotEmpty) return Urgency.now;
  if (t.contains('this week') || t.contains('next week')) {
    return Urgency.soon;
  }
  const soonWords = {'tomorrow', 'soon'};
  if (words.intersection(soonWords).isNotEmpty) return Urgency.soon;
  return Urgency.later;
}
