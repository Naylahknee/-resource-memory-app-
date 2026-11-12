import 'package:flutter_test/flutter_test.dart';
import 'package:resource_memory/features/focus_flow/domain/auto_plan.dart';
import 'package:resource_memory/features/focus_flow/domain/entities/focus_task.dart';
import 'package:resource_memory/features/focus_flow/domain/micro_step_generator.dart';

void main() {
  group('Stuck reasons: four-stage language', () {
    test('the menu shows all four stages', () {
      final labels = StuckReason.values.map((r) => r.label).toList();
      expect(labels, contains("Can't Start"));
      expect(labels, contains('Too Many Choices'));
      expect(labels, contains('Too Big'));
      expect(labels, contains('Not Urgent Yet'));
    });

    test('the three reasons that do not map cleanly are kept', () {
      final labels = StuckReason.values.map((r) => r.label).toList();
      expect(labels, contains('Dreading it'));
      expect(labels, contains('Waiting on someone'));
      expect(labels, contains('No energy'));
    });

    test('every label parses back to its reason', () {
      for (final reason in StuckReason.values) {
        expect(stuckReasonFromLabel(reason.label), reason);
      }
    });

    test('each stage branches into its own micro-steps', () {
      final branches = <StuckReason, List<String>>{
        for (final reason in StuckReason.values)
          reason: generateMicroSteps('Email the landlord about the leak',
              reason: reason),
      };
      for (final steps in branches.values) {
        expect(steps, isNotEmpty);
      }
      // The new stages have their own branches, not the generic fallback.
      expect(branches[StuckReason.tooManyChoices]!.first,
          contains('Pick the first option'));
      expect(branches[StuckReason.notUrgentYet]!.first,
          contains('actually due soon'));
      // The five original branches still work as before.
      expect(branches[StuckReason.dontKnowWhereToStart]!.length, 1);
      expect(branches[StuckReason.tooBig]!.first,
          contains('smallest piece'));
      expect(branches[StuckReason.dreadingIt]!.first,
          contains('2 minutes'));
      expect(branches[StuckReason.waitingOnSomeone]!.first,
          contains('does not need them'));
      expect(branches[StuckReason.noEnergy]!.first,
          contains('smallest possible bit'));
    });
  });

  group('Auto-plan urgency', () {
    test('due and today words are urgent', () {
      expect(urgencyForDumpedTitle('Pay electric bill today'), Urgency.now);
      expect(urgencyForDumpedTitle('Reply to Sam ASAP'), Urgency.now);
      expect(urgencyForDumpedTitle('Dentist appointment due Friday'),
          Urgency.now);
    });

    test('tomorrow and this week are soon', () {
      expect(urgencyForDumpedTitle('Call mom tomorrow'), Urgency.soon);
      expect(urgencyForDumpedTitle('Clean the kitchen this week'),
          Urgency.soon);
    });

    test('everything else waits, and "know" does not trip "now"', () {
      expect(urgencyForDumpedTitle('Learn Spanish someday'), Urgency.later);
      expect(urgencyForDumpedTitle('I do not know what to make for dinner'),
          Urgency.later);
    });
  });
}
