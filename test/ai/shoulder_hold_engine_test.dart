// test/ai/shoulder_hold_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:motioncare/ai/holds/shoulder_hold_engine.dart';
import 'package:motioncare/models/enums.dart';

void main() {
  group('ShoulderHoldEngine Hold Timer State Management', () {
    late ShoulderHoldEngine engine;

    setUp(() {
      engine = ShoulderHoldEngine(targetHoldSeconds: 60.0);
    });

    test('Correct state increments hold timer continuously', () {
      // 10 seconds of correct posture (10 ticks of 1.0s)
      for (int i = 0; i < 10; i++) {
        final state = engine.processTick(
          aiState: AiState.correct,
          issueCode: IssueCode.none,
          deltaSeconds: 1.0,
        );
        expect(state.isHolding, isTrue);
        expect(state.isPaused, isFalse);
      }

      expect(engine.correctHoldSeconds, equals(10.0));
      expect(engine.incorrectHoldSeconds, equals(0.0));
      expect(engine.visibilityLossSeconds, equals(0.0));
      expect(engine.postureBreakCount, equals(0));
    });

    test(
      'Posture deviation pauses timer without resetting accumulated time',
      () {
        // 15 seconds correct
        for (int i = 0; i < 15; i++) {
          engine.processTick(
            aiState: AiState.correct,
            issueCode: IssueCode.none,
            deltaSeconds: 1.0,
          );
        }
        expect(engine.correctHoldSeconds, equals(15.0));

        // 5 seconds incorrect posture
        for (int i = 0; i < 5; i++) {
          final state = engine.processTick(
            aiState: AiState.incorrect,
            issueCode: IssueCode.angleTooLow,
            deltaSeconds: 1.0,
          );
          expect(state.isHolding, isFalse);
          expect(state.isPaused, isTrue);
          expect(
            state.currentHoldSeconds,
            equals(15.0),
            reason: 'Timer must not reset on posture break',
          );
        }

        expect(engine.correctHoldSeconds, equals(15.0));
        expect(engine.incorrectHoldSeconds, equals(5.0));
        expect(engine.postureBreakCount, equals(1));
      },
    );

    test('Recovery resumes timer and tracks recovery event', () {
      // 10s correct -> 4s incorrect -> 10s correct (resumed)
      for (int i = 0; i < 10; i++) {
        engine.processTick(
          aiState: AiState.correct,
          issueCode: IssueCode.none,
          deltaSeconds: 1.0,
        );
      }
      for (int i = 0; i < 4; i++) {
        engine.processTick(
          aiState: AiState.incorrect,
          issueCode: IssueCode.postureDeviation,
          deltaSeconds: 1.0,
        );
      }
      for (int i = 0; i < 10; i++) {
        engine.processTick(
          aiState: AiState.correct,
          issueCode: IssueCode.none,
          deltaSeconds: 1.0,
        );
      }

      expect(engine.correctHoldSeconds, equals(20.0));
      expect(engine.incorrectHoldSeconds, equals(4.0));
      expect(engine.postureBreakCount, equals(1));
      expect(engine.recoveryCount, equals(1));
    });

    test('Visibility loss pauses timer without counting as posture break', () {
      // 10s correct
      for (int i = 0; i < 10; i++) {
        engine.processTick(
          aiState: AiState.correct,
          issueCode: IssueCode.none,
          deltaSeconds: 1.0,
        );
      }

      // 3s visibility loss
      for (int i = 0; i < 3; i++) {
        final state = engine.processTick(
          aiState: AiState.insufficientVisibility,
          issueCode: IssueCode.insufficientVisibility,
          deltaSeconds: 1.0,
        );
        expect(state.isHolding, isFalse);
        expect(state.isPaused, isTrue);
        expect(state.issueCode, equals(IssueCode.insufficientVisibility));
      }

      expect(engine.correctHoldSeconds, equals(10.0));
      expect(engine.visibilityLossSeconds, equals(3.0));
      expect(
        engine.incorrectHoldSeconds,
        equals(0.0),
        reason: 'Visibility loss is not movement error',
      );
      expect(engine.postureBreakCount, equals(0));
    });
  });
}
