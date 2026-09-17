// lib/ai/holds/shoulder_hold_engine.dart
// Specification v7 Section 22: Hold Engine for Isometric Exercises (e.g. Shoulder Raise/Hold)
// Correct -> Timer running; Incorrect -> Timer paused + feedback; Correct again -> Timer resumes;
// Insufficient visibility -> Timer paused; Timer never resets on posture breaks.

import '../../models/enums.dart';
import '../../models/movement_event.dart';

class ShoulderHoldEngine {
  final double targetHoldSeconds;

  double _correctHoldSeconds = 0.0;
  double _incorrectHoldSeconds = 0.0;
  double _visibilityLossSeconds = 0.0;
  int _postureBreakCount = 0;
  bool _wasPreviousStateIncorrect = false;
  int _recoveryCount = 0;

  ShoulderHoldEngine({required this.targetHoldSeconds});

  double get correctHoldSeconds => _correctHoldSeconds;
  double get incorrectHoldSeconds => _incorrectHoldSeconds;
  double get visibilityLossSeconds => _visibilityLossSeconds;
  int get postureBreakCount => _postureBreakCount;
  int get recoveryCount => _recoveryCount;
  bool get isCompleted => _correctHoldSeconds >= targetHoldSeconds;

  void reset() {
    _correctHoldSeconds = 0.0;
    _incorrectHoldSeconds = 0.0;
    _visibilityLossSeconds = 0.0;
    _postureBreakCount = 0;
    _wasPreviousStateIncorrect = false;
    _recoveryCount = 0;
  }

  /// Processes a time step with duration [deltaSeconds].
  HoldState processTick({
    required AiState aiState,
    required IssueCode issueCode,
    required double deltaSeconds,
  }) {
    if (isCompleted) {
      return HoldState(
        currentHoldSeconds: _correctHoldSeconds,
        targetHoldSeconds: targetHoldSeconds,
        isHolding: false,
        isPaused: true,
        issueCode: IssueCode.none,
      );
    }

    if (aiState == AiState.insufficientVisibility) {
      _visibilityLossSeconds += deltaSeconds;
      return HoldState(
        currentHoldSeconds: _correctHoldSeconds,
        targetHoldSeconds: targetHoldSeconds,
        isHolding: false,
        isPaused: true,
        issueCode: IssueCode.insufficientVisibility,
      );
    } else if (aiState == AiState.correct) {
      _correctHoldSeconds += deltaSeconds;

      // Check recovery
      if (_wasPreviousStateIncorrect) {
        _recoveryCount++;
        _wasPreviousStateIncorrect = false;
      }

      return HoldState(
        currentHoldSeconds: _correctHoldSeconds,
        targetHoldSeconds: targetHoldSeconds,
        isHolding: true,
        isPaused: false,
        issueCode: IssueCode.none,
      );
    } else {
      // INCORRECT posture
      _incorrectHoldSeconds += deltaSeconds;

      if (!_wasPreviousStateIncorrect) {
        _postureBreakCount++;
        _wasPreviousStateIncorrect = true;
      }

      return HoldState(
        currentHoldSeconds: _correctHoldSeconds,
        targetHoldSeconds: targetHoldSeconds,
        isHolding: false,
        isPaused: true,
        issueCode: issueCode != IssueCode.none
            ? issueCode
            : IssueCode.postureDeviation,
      );
    }
  }
}
