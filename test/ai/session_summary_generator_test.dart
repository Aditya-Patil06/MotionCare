// test/ai/session_summary_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:motioncare/ai/summary/session_summary_generator.dart';
import 'package:motioncare/models/enums.dart';
import 'package:motioncare/models/movement_event.dart';

void main() {
  group('SessionSummaryGenerator Factually Grounded Clinical Summaries', () {
    test('Generates precise Bicep Curl session summary per Specification Section 24', () {
      final now = DateTime.now();

      // 8 valid reps, 2 incomplete reps, 1 overshoot among the valid reps
      final repEvents = [
        RepEvent(
          repIndex: 1,
          isValid: true,
          peakAngle: 43,
          targetAngle: 45,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 2,
          isValid: true,
          peakAngle: 44,
          targetAngle: 45,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 3,
          isValid: true,
          peakAngle: 42,
          targetAngle: 45,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 4,
          isValid: false,
          peakAngle: 75,
          targetAngle: 45,
          issueCode: IssueCode.incompleteMovement,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 5,
          isValid: true,
          peakAngle: 45,
          targetAngle: 45,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 6,
          isValid: true,
          peakAngle: 22,
          targetAngle: 45,
          issueCode: IssueCode.overshoot,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 7,
          isValid: true,
          peakAngle: 44,
          targetAngle: 45,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 8,
          isValid: false,
          peakAngle: 80,
          targetAngle: 45,
          issueCode: IssueCode.incompleteMovement,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 9,
          isValid: true,
          peakAngle: 43,
          targetAngle: 45,
          timestamp: now,
        ),
        RepEvent(
          repIndex: 10,
          isValid: true,
          peakAngle: 45,
          targetAngle: 45,
          timestamp: now,
        ),
      ];

      final sessionEvents = [
        SessionEvent(
          timestamp: now,
          aiState: AiState.insufficientVisibility,
          currentAngle: 0,
          targetAngle: 45,
          issueCode: IssueCode.insufficientVisibility,
        ),
      ];

      final summary = SessionSummaryGenerator.generate(
        sessionId: 'sess_123',
        planId: 'plan_abc',
        patientId: 'pat_456',
        exerciseName: 'Bicep Curl',
        exerciseType: ExerciseType.rep,
        prescribedReps: 10,
        validReps: 8,
        invalidAttempts: 2,
        targetHoldSeconds: 0,
        correctHoldSeconds: 0,
        incorrectHoldSeconds: 0,
        visibilityLossSeconds: 2.5,
        events: sessionEvents,
        repEvents: repEvents,
      );

      expect(summary.validReps, equals(8));
      expect(summary.targetReps, equals(10));
      expect(summary.invalidAttempts, equals(2));
      expect(summary.accuracyPercentage, equals(80.0));
      expect(summary.commonIssue, equals(IssueCode.incompleteMovement));

      // Check narrative accuracy
      expect(
        summary.aiSummaryText,
        contains(
          'completed 8 valid repetitions out of 10 prescribed repetitions',
        ),
      );
      expect(summary.aiSummaryText, contains('2 attempts were incomplete'));
      expect(
        summary.aiSummaryText,
        contains('1 movement exceeded the reference tolerance'),
      );
      expect(
        summary.aiSummaryText,
        contains(
          'visibility interruption (2.5s) was excluded from movement-error scoring',
        ),
      );

      // Clinician Review Suggestion
      expect(
        summary.clinicianReviewSuggestion,
        contains(
          'Consider reviewing whether movement range decreases during later repetitions',
        ),
      );
    });

    test(
      'Generates precise Shoulder Raise hold summary with pause and recovery',
      () {
        final now = DateTime.now();
        final sessionEvents = [
          // 45s correct
          SessionEvent(
            timestamp: now,
            aiState: AiState.correct,
            currentAngle: 90,
            targetAngle: 90,
          ),
          // 10s posture loss
          SessionEvent(
            timestamp: now.add(const Duration(seconds: 45)),
            aiState: AiState.incorrect,
            currentAngle: 120,
            targetAngle: 90,
            issueCode: IssueCode.postureDeviation,
          ),
          // recovery back to correct
          SessionEvent(
            timestamp: now.add(const Duration(seconds: 55)),
            aiState: AiState.correct,
            currentAngle: 89,
            targetAngle: 90,
          ),
        ];

        final summary = SessionSummaryGenerator.generate(
          sessionId: 'sess_hold_1',
          planId: 'plan_hold',
          patientId: 'pat_456',
          exerciseName: 'Shoulder Raise',
          exerciseType: ExerciseType.hold,
          prescribedReps: 0,
          validReps: 0,
          invalidAttempts: 0,
          targetHoldSeconds: 60.0,
          correctHoldSeconds: 45.0,
          incorrectHoldSeconds: 10.0,
          visibilityLossSeconds: 0.0,
          events: sessionEvents,
          repEvents: const [],
        );

        expect(summary.correctHoldSeconds, equals(45.0));
        expect(summary.incorrectHoldSeconds, equals(10.0));
        expect(summary.commonIssue, equals(IssueCode.postureDeviation));
        expect(summary.accuracyPercentage, closeTo(81.8, 0.1));

        expect(
          summary.aiSummaryText,
          contains(
            'maintained the prescribed position correctly for approximately 45 seconds',
          ),
        );
        expect(
          summary.aiSummaryText,
          contains('lost the required position for approximately 10 seconds'),
        );
        expect(
          summary.aiSummaryText,
          contains('followed by successful recovery'),
        );

        expect(
          summary.clinicianReviewSuggestion,
          contains(
            'Consider reviewing whether the patient consistently loses the target position during prolonged holds',
          ),
        );
      },
    );
  });
}
