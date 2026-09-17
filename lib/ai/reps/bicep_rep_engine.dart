// lib/ai/reps/bicep_rep_engine.dart
// Specification v7 Section 21: Bicep Curl Rep State Machine
// IDLE -> FLEXING -> PEAK_REACHED -> RETURNING -> VALID REP
// Incomplete rep, overshoot, and visibility loss handling.

import 'dart:math' as math;
import '../../models/enums.dart';
import '../../models/movement_event.dart';
import '../../models/reference_profile.dart';

class BicepRepEngine {
  final double extensionThreshold; // Angle considered fully extended (e.g. 145°-150°)
  final double overshootMargin; // Degrees beyond (target - tolerance) considered overshoot

  RepPhase _phase = RepPhase.idle;
  int _validReps = 0;
  int _invalidAttempts = 0;
  double _minAngleInRep = 180.0;
  bool _hadOvershootInRep = false;
  IssueCode _lastIssueCode = IssueCode.none;

  BicepRepEngine({
    this.extensionThreshold = 145.0,
    this.overshootMargin = 8.0,
  });

  RepPhase get phase => _phase;
  int get validReps => _validReps;
  int get invalidAttempts => _invalidAttempts;
  IssueCode get lastIssueCode => _lastIssueCode;

  void reset() {
    _phase = RepPhase.idle;
    _validReps = 0;
    _invalidAttempts = 0;
    _minAngleInRep = 180.0;
    _hadOvershootInRep = false;
    _lastIssueCode = IssueCode.none;
  }

  /// Processes one live angle sample.
  /// Returns a [RepEvent] if a rep or incomplete attempt just completed, else null.
  RepEvent? processSample({
    required double currentAngle,
    required ReferenceProfile profile,
    required bool isVisibilityValid,
    required DateTime timestamp,
  }) {
    // 1. If visibility fails, do NOT count an invalid rep. (Section 21)
    if (!isVisibilityValid) {
      _lastIssueCode = IssueCode.insufficientVisibility;
      return null;
    }

    final double target = profile.targetAngle;
    final double tol = profile.tolerance;
    final double peakThreshold = target + tol; // Angle must be <= peakThreshold to accept peak
    final double overshootThreshold = target - tol - overshootMargin;

    RepEvent? completedEvent;

    switch (_phase) {
      case RepPhase.idle:
        _lastIssueCode = IssueCode.none;
        // Check for start of flexion
        if (currentAngle < extensionThreshold) {
          _phase = RepPhase.flexing;
          _minAngleInRep = currentAngle;
          _hadOvershootInRep = false;
          _lastIssueCode = IssueCode.none;
        }
        break;

      case RepPhase.flexing:
        _minAngleInRep = math.min(_minAngleInRep, currentAngle);

        // Check overshoot
        if (currentAngle < overshootThreshold) {
          _hadOvershootInRep = true;
        }

        // Check if peak reached
        if (currentAngle <= peakThreshold) {
          _phase = RepPhase.peakReached;
          _lastIssueCode = IssueCode.none;
        } else if (currentAngle >= extensionThreshold) {
          // Patient returned to extension without ever reaching target -> Incomplete rep!
          _invalidAttempts++;
          _lastIssueCode = IssueCode.incompleteMovement;
          completedEvent = RepEvent(
            repIndex: _validReps + _invalidAttempts,
            isValid: false,
            peakAngle: _minAngleInRep,
            targetAngle: target,
            issueCode: IssueCode.incompleteMovement,
            timestamp: timestamp,
          );
          _phase = RepPhase.idle;
          _minAngleInRep = 180.0;
        }
        break;

      case RepPhase.peakReached:
        _minAngleInRep = math.min(_minAngleInRep, currentAngle);

        // Check overshoot
        if (currentAngle < overshootThreshold) {
          _hadOvershootInRep = true;
        }

        // Once the arm starts extending past peak zone, transition to returning
        if (currentAngle > peakThreshold + 8.0) {
          _phase = RepPhase.returning;
        }
        break;

      case RepPhase.returning:
        // If arm completes full extension back to start
        if (currentAngle >= extensionThreshold) {
          _validReps++;
          final issue = _hadOvershootInRep
              ? IssueCode.overshoot
              : IssueCode.none;
          _lastIssueCode = issue;

          completedEvent = RepEvent(
            repIndex: _validReps,
            isValid: true,
            peakAngle: _minAngleInRep,
            targetAngle: target,
            issueCode: issue,
            timestamp: timestamp,
          );
          _phase = RepPhase.idle;
          _minAngleInRep = 180.0;
          _hadOvershootInRep = false;
        } else if (currentAngle <= peakThreshold) {
          // Re-curled before full extension
          _phase = RepPhase.peakReached;
        }
        break;
    }

    return completedEvent;
  }
}
