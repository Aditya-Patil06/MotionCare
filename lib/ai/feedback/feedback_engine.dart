// lib/ai/feedback/feedback_engine.dart
// Specification v7 Section 20: Direction-Aware Feedback Engine
// Provides clear, clinically responsible directional cues. Avoids vague terms like "wrong" or "bad form".

import '../../models/enums.dart';

class FeedbackEngine {
  static String getFeedback({
    required AiState aiState,
    required IssueCode issueCode,
    required double currentAngle,
    required double targetAngle,
    required double tolerance,
    required RepPhase repPhase,
    required ExerciseType exerciseType,
  }) {
    // 1. Visibility failure takes unconditional priority (Section 12)
    if (aiState == AiState.insufficientVisibility ||
        issueCode == IssueCode.insufficientVisibility) {
      return 'Move into camera view.';
    }

    // 2. Specific issue code handling
    switch (issueCode) {
      case IssueCode.incompleteMovement:
        return 'Complete the movement before returning.';
      case IssueCode.overshoot:
        return 'Ease back slightly.';
      case IssueCode.postureDeviation:
        return 'Keep your posture steady and aligned.';
      case IssueCode.movementTooFast:
        return 'Slow down the movement.';
      case IssueCode.extractionLowConfidence:
        return 'Hold steady for better tracking.';
      default:
        break;
    }

    // 3. Evaluation based on AiState and angle position
    if (aiState == AiState.correct) {
      if (exerciseType == ExerciseType.hold) {
        return 'Hold position steady.';
      }
      switch (repPhase) {
        case RepPhase.idle:
          return 'Ready. Begin your curl.';
        case RepPhase.flexing:
          return 'Smooth movement. Continue upward.';
        case RepPhase.peakReached:
          return 'Target reached! Now lower smoothly.';
        case RepPhase.returning:
          return 'Good control. Lower all the way down.';
      }
    } else {
      // INCORRECT state - Directional cues based on target & tolerance
      if (exerciseType == ExerciseType.rep) {
        // For Bicep Curl: Angle decreasing means arm is flexing towards target.
        // If currentAngle > targetAngle + tolerance: patient hasn't curled high enough yet.
        if (currentAngle > targetAngle + tolerance) {
          return 'Raise your arm higher towards the target.';
        } else if (currentAngle < targetAngle - tolerance) {
          return 'Ease back slightly, past the target zone.';
        } else {
          return 'Maintain steady form.';
        }
      } else {
        // For Hold exercises (e.g. shoulder raise where target is ~90°):
        if (currentAngle < targetAngle - tolerance) {
          return 'Raise your arm higher.';
        } else if (currentAngle > targetAngle + tolerance) {
          return 'Ease back slightly.';
        } else {
          return 'Adjust arm position to match the target.';
        }
      }
    }
  }
}
