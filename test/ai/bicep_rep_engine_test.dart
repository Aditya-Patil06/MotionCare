// test/ai/bicep_rep_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/ai/reps/bicep_rep_engine.dart';
import 'package:physio_app/models/enums.dart';
import 'package:physio_app/models/reference_profile.dart';

void main() {
  group('BicepRepEngine Rep Validation State Machine', () {
    late BicepRepEngine engine;
    const profile = ReferenceProfile(
      exerciseId: 'bicep_curl',
      targetAngle: 45.0,
      tolerance: 12.0,
      confidence: 0.90,
    );

    setUp(() {
      engine = BicepRepEngine();
    });

    test('Valid complete repetition increments valid reps', () {
      final now = DateTime.now();

      // Cycle: 160 -> 140 (flexing) -> 50 (peak) -> 120 (returning) -> 160 (idle)
      final angles = [160.0, 140.0, 100.0, 70.0, 50.0, 52.0, 90.0, 130.0, 155.0];

      for (int i = 0; i < angles.length; i++) {
        final event = engine.processSample(
          currentAngle: angles[i],
          profile: profile,
          isVisibilityValid: true,
          timestamp: now.add(Duration(milliseconds: i * 100)),
        );

        if (i == angles.length - 1) {
          expect(event, isNotNull);
          expect(event!.isValid, isTrue);
          expect(event.repIndex, equals(1));
        }
      }

      expect(engine.validReps, equals(1));
      expect(engine.invalidAttempts, equals(0));
      expect(engine.phase, equals(RepPhase.idle));
    });

    test('Incomplete repetition does NOT count as valid and logs invalid attempt', () {
      final now = DateTime.now();

      // Cycle: 160 -> 130 (flexing) -> 80 (only reaches 80°, misses 45±12° target) -> returns to 150
      final angles = [160.0, 140.0, 120.0, 80.0, 90.0, 120.0, 150.0];

      for (int i = 0; i < angles.length; i++) {
        final event = engine.processSample(
          currentAngle: angles[i],
          profile: profile,
          isVisibilityValid: true,
          timestamp: now.add(Duration(milliseconds: i * 100)),
        );

        if (i == angles.length - 1) {
          expect(event, isNotNull);
          expect(event!.isValid, isFalse);
          expect(event.issueCode, equals(IssueCode.incompleteMovement));
        }
      }

      expect(engine.validReps, equals(0));
      expect(engine.invalidAttempts, equals(1));
      expect(engine.lastIssueCode, equals(IssueCode.incompleteMovement));
      expect(engine.phase, equals(RepPhase.idle));
    });

    test('Overshoot past target tolerance flags overshoot issue', () {
      final now = DateTime.now();

      // Target is 45° ± 12° = [33°, 57°].
      // Angle goes to 20° (overshoot < 25°)
      final angles = [160.0, 140.0, 80.0, 20.0, 20.0, 60.0, 110.0, 155.0];

      for (int i = 0; i < angles.length; i++) {
        final event = engine.processSample(
          currentAngle: angles[i],
          profile: profile,
          isVisibilityValid: true,
          timestamp: now.add(Duration(milliseconds: i * 100)),
        );

        if (i == angles.length - 1) {
          expect(event, isNotNull);
          expect(event!.isValid, isTrue);
          expect(event.issueCode, equals(IssueCode.overshoot));
        }
      }

      expect(engine.validReps, equals(1));
      expect(engine.lastIssueCode, equals(IssueCode.overshoot));
    });

    test('Visibility loss does NOT generate an invalid rep', () {
      final now = DateTime.now();

      // Start curl
      engine.processSample(
        currentAngle: 160.0,
        profile: profile,
        isVisibilityValid: true,
        timestamp: now,
      );
      engine.processSample(
        currentAngle: 120.0,
        profile: profile,
        isVisibilityValid: true,
        timestamp: now.add(const Duration(milliseconds: 100)),
      );
      expect(engine.phase, equals(RepPhase.flexing));

      // Visibility drops
      final event = engine.processSample(
        currentAngle: 100.0,
        profile: profile,
        isVisibilityValid: false,
        timestamp: now.add(const Duration(milliseconds: 200)),
      );

      expect(event, isNull);
      expect(engine.invalidAttempts, equals(0), reason: 'Visibility loss must never punish the patient');
      expect(engine.lastIssueCode, equals(IssueCode.insufficientVisibility));
    });

    test('Multiple continuous repetitions count accurately', () {
      final now = DateTime.now();
      int timestampMs = 0;

      void performCurl(double peakAngle) {
        final cycle = [160.0, 130.0, 80.0, peakAngle, peakAngle, 80.0, 130.0, 155.0];
        for (final a in cycle) {
          engine.processSample(
            currentAngle: a,
            profile: profile,
            isVisibilityValid: true,
            timestamp: now.add(Duration(milliseconds: timestampMs += 100)),
          );
        }
      }

      // Rep 1 (clean)
      performCurl(45.0);
      expect(engine.validReps, equals(1));

      // Rep 2 (clean)
      performCurl(42.0);
      expect(engine.validReps, equals(2));

      // Rep 3 (clean)
      performCurl(46.0);
      expect(engine.validReps, equals(3));
      expect(engine.invalidAttempts, equals(0));
    });
  });
}
