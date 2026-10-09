/// How granular the "I'm stuck" breakdown should be.
///
/// Gentle: 2-3 big, forgiving steps. Medium: 4-5 steps. Spicy: 6+ tiny,
/// almost silly steps (open the laptop, open the doc, ...).
enum StepSpiciness {
  gentle,
  medium,
  spicy,
}

/// Generates ridiculously small micro-steps for the "I'm stuck" button.
///
/// Pure local heuristics, no network. The goal is not accuracy, it is
/// momentum: steps so small they feel silly to refuse.
List<String> generateMicroSteps(String title, {StepSpiciness spiciness = StepSpiciness.medium}) {
  final t = title.toLowerCase();

  bool any(List<String> words) => words.any((w) => t.contains(w));

  List<String> pick(List<String> gentle, List<String> medium, List<String> spicy) {
    switch (spiciness) {
      case StepSpiciness.gentle:
        return gentle;
      case StepSpiciness.spicy:
        return spicy;
      case StepSpiciness.medium:
        return medium;
    }
  }

  if (any(['email', 'e-mail', 'inbox', 'reply', 'send the'])) {
    return pick(
      [
        'Open your email app. That is the whole step.',
        'Write something. Bad counts.',
      ],
      [
        'Open your email app. That is the whole step.',
        'Find the message. Just find it.',
        'Write two sentences. Bad ones count.',
        'Hit send before you re-read it.',
      ],
      [
        'Pick up your phone or sit at your computer.',
        'Open your email app.',
        'Find the message. Just find it.',
        'Skim the last line so you know what they asked.',
        'Type one sentence back.',
        'Type a second sentence if you feel like it.',
        'Hit send before you re-read it.',
      ],
    );
  }
  if (any(['clean', 'dishes', 'kitchen', 'laundry', 'tidy', 'vacuum', 'bathroom', 'trash', 'mop'])) {
    return pick(
      [
        'Stand up. Seriously, just stand up.',
        'Put one thing where it goes. Then you are free.',
      ],
      [
        'Stand up. Seriously, just stand up.',
        'Put one thing where it goes.',
        'Set a timer for 5 minutes and stop when it rings.',
      ],
      [
        'Stand up.',
        'Walk to the room.',
        'Pick up the closest thing out of place.',
        'Put it where it goes.',
        'Pick up one more thing.',
        'Put that one where it goes too.',
        'Look around. Good enough.',
      ],
    );
  }
  if (any(['call', 'phone', 'ring ', 'text '])) {
    return pick(
      [
        'Find the number. Do not dial yet.',
        'Say the one thing you need to say. It can be under a minute.',
      ],
      [
        'Find the number. Do not dial yet.',
        'Write down the one thing you need to say.',
        'Make the call. It can be under a minute.',
      ],
      [
        'Find the contact or the number.',
        'Take one slow breath.',
        'Write down the one thing you need to say.',
        'Tap call.',
        'Say the thing. Then say bye.',
        'Hang up. Done.',
      ],
    );
  }
  if (any(['pay', 'bill', 'invoice'])) {
    return pick(
      [
        'Open the bill or the payment app. Just look at it.',
        'Pay it or schedule it. Done either way.',
      ],
      [
        'Open the bill or the payment app.',
        'Check the amount. Just look at it.',
        'Pay it or schedule it. Done either way.',
      ],
      [
        'Find the bill. Paper pile, email, wherever it lives.',
        'Open it and look at the amount.',
        'Open your payment app or bank site.',
        'Type in the amount.',
        'Press pay or schedule.',
        'Close the tab. It is handled.',
      ],
    );
  }
  if (any(['appointment', 'doctor', 'dentist', 'book', 'schedule', 'reserve'])) {
    return pick(
      [
        'Decide the one day that could work.',
        'Book it. A bad time beats no time.',
      ],
      [
        'Decide the one day that could work.',
        'Open the booking page or find the number.',
        'Book it. A bad time beats no time.',
      ],
      [
        'Think of one day that could work. Any day.',
        'Find the booking page or the phone number.',
        'Open it.',
        'Pick a time. The first okay one.',
        'Confirm it.',
        'Add it to your calendar so you forget about it on purpose.',
      ],
    );
  }
  if (any(['cook', 'dinner', 'lunch', 'meal', 'eat'])) {
    return pick(
      [
        'Drink a glass of water first.',
        'Pick the simplest thing you already have.',
      ],
      [
        'Drink a glass of water first.',
        'Pick the simplest thing you already have.',
        'Start one burner or open one package.',
      ],
      [
        'Drink a glass of water.',
        'Open the fridge.',
        'Pick the simplest thing you already have.',
        'Put it on the counter.',
        'Start one burner, or open the package.',
        'Put the food in or on the heat.',
        'Wait. That is cooking.',
      ],
    );
  }
  if (any(['study', 'homework', 'read', 'write', 'essay', 'report'])) {
    return pick(
      [
        'Open the document or book. Just open it.',
        'Two minutes. Time it. Then you can stop.',
      ],
      [
        'Open the document or book. Just open it.',
        'Read or write for 2 minutes. Time it.',
        'Keep going or stop. Either is fine.',
      ],
      [
        'Sit down where you work.',
        'Open the document or book.',
        'Read the first paragraph, or write one sentence.',
        'Set a timer for 2 minutes.',
        'Keep going until it rings.',
        'Stop when it rings. You started, that was the job.',
      ],
    );
  }
  if (any(['exercise', 'workout', 'walk', 'run', 'gym', 'stretch'])) {
    return pick(
      [
        'Put on shoes. That counts as starting.',
        'Move for 5 minutes. Then decide.',
      ],
      [
        'Put on shoes. That counts as starting.',
        'Step outside or stand up.',
        'Move for 5 minutes. Then decide.',
      ],
      [
        'Put on shoes.',
        'Stand up.',
        'Step outside or clear a little space.',
        'Walk or move for one minute.',
        'Keep going to five minutes.',
        'Stop whenever. You moved.',
      ],
    );
  }

  // Generic fallback, sized by spiciness.
  return pick(
    [
      'Get what you need in front of you.',
      'Do just the first 2 minutes. Then stop if you want.',
    ],
    [
      'Get what you need in front of you.',
      'Do just the first 2 minutes.',
      'Notice you started. That was the hard part.',
      'Keep going or stop. Either is fine.',
    ],
    [
      'Sit where you will do it.',
      'Get what you need in front of you.',
      'Touch the thing. Open it, pick it up, whatever fits.',
      'Do 2 minutes. Set a timer so you believe you can stop.',
      'Notice you started. That was the hard part.',
      'Keep going, or stop. Either is fine.',
    ],
  );
}
