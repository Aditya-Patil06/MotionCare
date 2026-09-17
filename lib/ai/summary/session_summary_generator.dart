// lib/ai/summary/session_summary_generator.dart
// Specification v7 Section 24 & 25: AI-Generated Session Summary Generator
// Strictly deterministic, 100% grounded in recorded session events.
// Never diagnoses. Never prescribes. Formats observations and clinician review prompts.

import '../../models/enums.dart';
import '../../models/movement_event.dart';
import '../../models/session.dart';

class SessionSummaryGenerator {
  /// Generates a structured [SessionSummary] from recorded events and metrics.
  static SessionSummary generate({
    required String sessionId,
    required String planId,
    required String patientId,
    required String exerciseName,
    required ExerciseType exerciseType,
    required int prescribedReps,
    required int validReps,
    required int invalidAttempts,
    required double targetHoldSeconds,
    required double correctHoldSeconds,
    required double incorrectHoldSeconds,
    required double visibilityLossSeconds,
    required List<SessionEvent> events,
    required List<RepEvent> repEvents,
  }) {
    // 1. Analyze issue code distribution from events and rep history
    int incompleteCount = 0;
    int overshootCount = 0;
    int postureDeviationCount = 0;
    int recoveryCount = 0;
    bool previousWasError = false;

    for (final rep in repEvents) {
      if (!rep.isValid && rep.issueCode == IssueCode.incompleteMovement) {
        incompleteCount++;
      } else if (rep.issueCode == IssueCode.overshoot) {
        overshootCount++;
      }
    }

    for (final e in events) {
      if (e.issueCode == IssueCode.postureDeviation) {
        postureDeviationCount++;
      }

      if (e.aiState == AiState.incorrect) {
        previousWasError = true;
      } else if (e.aiState == AiState.correct && previousWasError) {
        recoveryCount++;
        previousWasError = false;
      }
    }

    // Determine common issue
    IssueCode commonIssue = IssueCode.none;
    int maxIssueCount = 0;
    final Map<IssueCode, int> issueFrequencies = {
      IssueCode.incompleteMovement: incompleteCount,
      IssueCode.overshoot: overshootCount,
      IssueCode.postureDeviation: postureDeviationCount,
    };
    issueFrequencies.forEach((issue, count) {
      if (count > maxIssueCount) {
        maxIssueCount = count;
        commonIssue = issue;
      }
    });

    // 2. Calculate accuracy percentage
    double accuracyPercentage = 100.0;
    if (exerciseType == ExerciseType.rep) {
      final int totalAttempts = validReps + invalidAttempts;
      if (totalAttempts > 0) {
        accuracyPercentage = (validReps / totalAttempts) * 100.0;
      }
    } else {
      final double totalActiveTime = correctHoldSeconds + incorrectHoldSeconds;
      if (totalActiveTime > 0) {
        accuracyPercentage = (correctHoldSeconds / totalActiveTime) * 100.0;
      }
    }
    accuracyPercentage = double.parse(accuracyPercentage.toStringAsFixed(1));

    // 3. Build natural language AI summary text (grounded in actual data)
    final StringBuffer summaryBuffer = StringBuffer();
    final StringBuffer suggestionBuffer = StringBuffer();

    if (exerciseType == ExerciseType.rep) {
      summaryBuffer.write(
        'Patient completed $validReps valid repetitions out of $prescribedReps prescribed repetitions. ',
      );

      if (validReps > 0) {
        final consistentCount = validReps - overshootCount;
        if (consistentCount > 0) {
          summaryBuffer.write(
            '$consistentCount repetitions reached the reference movement range consistently. ',
          );
        }
      }

      if (incompleteCount > 0) {
        summaryBuffer.write(
          '$incompleteCount ${incompleteCount == 1 ? 'attempt was' : 'attempts were'} incomplete and did not reach the target angle. ',
        );
      }

      if (overshootCount > 0) {
        summaryBuffer.write(
          '$overshootCount ${overshootCount == 1 ? 'movement' : 'movements'} exceeded the reference tolerance. ',
        );
      }

      if (visibilityLossSeconds > 0) {
        summaryBuffer.write(
          'A brief visibility interruption (${visibilityLossSeconds.toStringAsFixed(1)}s) was excluded from movement-error scoring. ',
        );
      }

      // Clinician Review Suggestion
      if (incompleteCount > 0 && validReps > incompleteCount) {
        suggestionBuffer.write(
          'Consider reviewing whether movement range decreases during later repetitions.',
        );
      } else if (overshootCount > 0) {
        suggestionBuffer.write(
          'Consider reviewing whether the patient tends to overshoot terminal joint angles under fatigue.',
        );
      } else if (validReps >= prescribedReps) {
        suggestionBuffer.write(
          'Movement consistency remained stable across all completed repetitions.',
        );
      } else {
        suggestionBuffer.write(
          'Consider reviewing overall completion rate and pacing for the prescribed target.',
        );
      }
    } else {
      // Hold Exercise Summary
      summaryBuffer.write(
        'Patient maintained the prescribed position correctly for approximately ${correctHoldSeconds.toStringAsFixed(0)} seconds. ',
      );

      if (incorrectHoldSeconds > 0) {
        summaryBuffer.write(
          'The patient lost the required position for approximately ${incorrectHoldSeconds.toStringAsFixed(0)} seconds, during which the hold timer paused. ',
        );
      }

      if (recoveryCount > 0) {
        summaryBuffer.write(
          'The patient corrected the position and maintained the target position for the remaining duration. ',
        );
        summaryBuffer.write(
          'Observed pattern: $postureDeviationCount posture ${postureDeviationCount == 1 ? 'deviation' : 'deviations'} occurred during the hold, followed by successful recovery. ',
        );
      }

      if (visibilityLossSeconds > 0) {
        summaryBuffer.write(
          'Tracking visibility was briefly lost for ${visibilityLossSeconds.toStringAsFixed(1)} seconds and excluded from posture scoring. ',
        );
      }

      // Clinician Review Suggestion
      if (incorrectHoldSeconds >= 10.0 || postureDeviationCount >= 2) {
        suggestionBuffer.write(
          'Consider reviewing whether the patient consistently loses the target position during prolonged holds.',
        );
      } else if (recoveryCount > 0) {
        suggestionBuffer.write(
          'Good compensatory recovery observed; verify whether hold duration can be sustained comfortably.',
        );
      } else {
        suggestionBuffer.write(
          'Target position was maintained with high stability throughout the prescribed hold duration.',
        );
      }
    }

    return SessionSummary(
      sessionId: sessionId,
      planId: planId,
      patientId: patientId,
      exerciseName: exerciseName,
      exerciseType: exerciseType,
      validReps: validReps,
      targetReps: prescribedReps,
      invalidAttempts: invalidAttempts,
      correctHoldSeconds: correctHoldSeconds,
      targetHoldSeconds: targetHoldSeconds,
      incorrectHoldSeconds: incorrectHoldSeconds,
      visibilityLossSeconds: visibilityLossSeconds,
      accuracyPercentage: accuracyPercentage,
      commonIssue: commonIssue,
      aiSummaryText: summaryBuffer.toString().trim(),
      clinicianReviewSuggestion: suggestionBuffer.toString().trim(),
      createdAt: DateTime.now(),
    );
  }
}
