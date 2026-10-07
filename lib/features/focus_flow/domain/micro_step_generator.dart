/// Generates ridiculously small micro-steps for the "I'm stuck" button.
///
/// Pure local heuristics, no network. The goal is not accuracy, it is
/// momentum: steps so small they feel silly to refuse.
List<String> generateMicroSteps(String title) {
  final t = title.toLowerCase();

  bool any(List<String> words) => words.any((w) => t.contains(w));

  if (any(['email', 'e-mail', 'inbox', 'reply', 'send the'])) {
    return [
      'Open your email app. That is the whole step.',
      'Find the message. Just find it.',
      'Write two sentences. Bad ones count.',
      'Hit send before you re-read it.',
    ];
  }
  if (any(['clean', 'dishes', 'kitchen', 'laundry', 'tidy', 'vacuum', 'bathroom', 'trash', 'mop'])) {
    return [
      'Stand up. Seriously, just stand up.',
      'Put one thing where it goes.',
      'Set a timer for 5 minutes and stop when it rings.',
    ];
  }
  if (any(['call', 'phone', 'ring ', 'text '])) {
    return [
      'Find the number. Do not dial yet.',
      'Write down the one thing you need to say.',
      'Make the call. It can be under a minute.',
    ];
  }
  if (any(['pay', 'bill', 'invoice'])) {
    return [
      'Open the bill or the payment app.',
      'Check the amount. Just look at it.',
      'Pay it or schedule it. Done either way.',
    ];
  }
  if (any(['appointment', 'doctor', 'dentist', 'book', 'schedule', 'reserve'])) {
    return [
      'Decide the one day that could work.',
      'Open the booking page or find the number.',
      'Book it. A bad time beats no time.',
    ];
  }
  if (any(['cook', 'dinner', 'lunch', 'meal', 'eat'])) {
    return [
      'Drink a glass of water first.',
      'Pick the simplest thing you already have.',
      'Start one burner or open one package.',
    ];
  }
  if (any(['study', 'homework', 'read', 'write', 'essay', 'report'])) {
    return [
      'Open the document or book. Just open it.',
      'Read or write for 2 minutes. Time it.',
      'Keep going or stop. Either is fine.',
    ];
  }
  if (any(['exercise', 'workout', 'walk', 'run', 'gym', 'stretch'])) {
    return [
      'Put on shoes. That counts as starting.',
      'Step outside or stand up.',
      'Move for 5 minutes. Then decide.',
    ];
  }

  // Generic fallback: always 3 steps, always tiny.
  return [
    'Get what you need in front of you.',
    'Do just the first 2 minutes.',
    'Keep going or stop. Either is fine.',
  ];
}
