// lib/ai/engine/exercise_engine.dart
// Central pipeline coordinator separating Biomechanics & AI logic from UI screens.
// Human -> Pose -> Landmarks -> Angles -> Movement -> Comparison -> Validation -> Feedback -> Events -> Summary

import '../../exercises/bicep_curl/bicep_curl_rule.dart';
import '../../exercises/exercise_rule.dart';
import '../../models/enums.dart';
import '../../models/landmark.dart';
import '../../models/movement_event.dart';
import '../../models/reference_profile.dart';
import '../../models/session.dart';
import '../feedback/feedback_engine.dart';
import '../holds/shoulder_hold_engine.dart';
import '../summary/session_summary_generator.dart';
import '../visibility/visibility_tracker.dart';

class ExerciseEngine {
  final ExerciseRule rule;
  final ReferenceProfile profile;
  final int prescribedReps;
  final double targetHoldSeconds;

  late final VisibilityTracker _visibilityTracker;
  ShoulderHoldEngine? _holdEngine;

  final List<AngleSample> _angleHistory = [];
  final List<SessionEvent> _sessionEvents = [];
  final List<RepEvent> _repEvents = [];

  DateTime? _lastFrameTime;
  double _totalVisibilityLossSeconds = 0.0;
  bool _isFinished = false;

  ExerciseEngine({
    required this.rule,
    required this.profile,
    this.prescribedReps = 10,
    this.targetHoldSeconds = 60.0,
    VisibilityTracker? visibilityTracker,
  }) {
    _visibilityTracker = visibilityTracker ??
        VisibilityTracker(
          confidenceThreshold: 0.60,
          failThreshold: 5,
          passThreshold: 3,
          initialValidState: false,
        );

    if (rule.type == ExerciseType.hold) {
      _holdEngine = ShoulderHoldEngine(targetHoldSeconds: targetHoldSeconds);
    }
  }

  bool get isFinished => _isFinished;
  List<SessionEvent> get sessionEvents => List.unmodifiable(_sessionEvents);
  List<RepEvent> get repEvents => List.unmodifiable(_repEvents);
  VisibilityTracker get visibilityTracker => _visibilityTracker;

  int get validReps {
    if (rule is BicepCurlRule) {
      return (rule as BicepCurlRule).repEngine.validReps;
    }
    return 0;
  }

  int get invalidAttempts {
    if (rule is BicepCurlRule) {
      return (rule as BicepCurlRule).repEngine.invalidAttempts;
    }
    return 0;
  }

  /// Processes one camera frame or fixture frame.
  EngineFrame processFrame({
    required Map<String, Landmark> landmarks,
    required DateTime timestamp,
  }) {
    final double deltaSeconds;
    if (_lastFrameTime != null) {
      deltaSeconds = (timestamp.difference(_lastFrameTime!).inMilliseconds) / 1000.0;
    } else {
      deltaSeconds = 0.1; // Default 10 FPS assumption for first frame
    }
    _lastFrameTime = timestamp;

    // 1. Evaluate Visibility (Section 12: Priority 1)
    final triple = rule.jointDefinition.jointTriple;
    final requiredKeys = [triple.a, triple.b, triple.c];

    final visResult = _visibilityTracker.evaluate(
      landmarks: landmarks,
      requiredLandmarkKeys: requiredKeys,
    );

    final bool isVisibilityValid = visResult.isValid;

    if (!isVisibilityValid) {
      _totalVisibilityLossSeconds += deltaSeconds;

      final sessionEvent = SessionEvent(
        timestamp: timestamp,
        aiState: AiState.insufficientVisibility,
        currentAngle: 0.0,
        targetAngle: profile.targetAngle,
        issueCode: IssueCode.insufficientVisibility,
        durationSeconds: deltaSeconds,
      );
      _sessionEvents.add(sessionEvent);

      HoldState? holdState;
      if (_holdEngine != null) {
        holdState = _holdEngine!.processTick(
          aiState: AiState.insufficientVisibility,
          issueCode: IssueCode.insufficientVisibility,
          deltaSeconds: deltaSeconds,
        );
      }

      return EngineFrame(
        timestamp: timestamp,
        landmarks: landmarks,
        currentAngle: 0.0,
        targetAngle: profile.targetAngle,
        tolerance: profile.tolerance,
        aiState: AiState.insufficientVisibility,
        issueCode: IssueCode.insufficientVisibility,
        repPhase: (rule is BicepCurlRule)
            ? (rule as BicepCurlRule).repEngine.phase
            : RepPhase.idle,
        holdState: holdState,
        feedbackMessage: FeedbackEngine.getFeedback(
          aiState: AiState.insufficientVisibility,
          issueCode: IssueCode.insufficientVisibility,
          currentAngle: 0.0,
          targetAngle: profile.targetAngle,
          tolerance: profile.tolerance,
          repPhase: RepPhase.idle,
          exerciseType: rule.type,
        ),
        validReps: validReps,
        targetReps: prescribedReps,
        invalidAttempts: invalidAttempts,
        isVisibilityValid: false,
      );
    }

    // 2. Visibility Valid: Compute angle
    double currentAngle = 180.0;
    if (rule is BicepCurlRule) {
      currentAngle = (rule as BicepCurlRule).extractAngle(landmarks);
    }

    // Sample history
    final sample = AngleSample(
      timestamp: timestamp,
      angle: currentAngle,
      visibilityValid: true,
    );
    _angleHistory.add(sample);

    // 3. Movement correctness & phase
    final AiState aiState = rule.analyzePatient(currentAngle, profile, true);
    IssueCode currentIssue = IssueCode.none;

    // 4. Rep or Hold Engine Processing
    HoldState? holdState;
    if (rule.type == ExerciseType.rep) {
      final repEvent = rule.detectRep([sample], profile);
      if (repEvent != null) {
        _repEvents.add(repEvent);
        currentIssue = repEvent.issueCode;
        if (validReps >= prescribedReps) {
          _isFinished = true;
        }
      } else if (rule is BicepCurlRule) {
        currentIssue = (rule as BicepCurlRule).repEngine.lastIssueCode;
      }
    } else if (rule.type == ExerciseType.hold && _holdEngine != null) {
      holdState = _holdEngine!.processTick(
        aiState: aiState,
        issueCode: aiState == AiState.correct ? IssueCode.none : IssueCode.postureDeviation,
        deltaSeconds: deltaSeconds,
      );
      currentIssue = holdState.issueCode;
      if (_holdEngine!.isCompleted) {
        _isFinished = true;
      }
    }

    // Directional Feedback
    final feedback = rule.getFeedback(currentAngle, profile, aiState, currentIssue);

    // Record Event
    _sessionEvents.add(SessionEvent(
      timestamp: timestamp,
      aiState: aiState,
      currentAngle: currentAngle,
      targetAngle: profile.targetAngle,
      issueCode: currentIssue,
      repPhase: (rule is BicepCurlRule) ? (rule as BicepCurlRule).repEngine.phase : null,
      durationSeconds: deltaSeconds,
    ));

    return EngineFrame(
      timestamp: timestamp,
      landmarks: landmarks,
      currentAngle: currentAngle,
      targetAngle: profile.targetAngle,
      tolerance: profile.tolerance,
      aiState: aiState,
      issueCode: currentIssue,
      repPhase: (rule is BicepCurlRule)
          ? (rule as BicepCurlRule).repEngine.phase
          : RepPhase.idle,
      holdState: holdState,
      feedbackMessage: feedback,
      validReps: validReps,
      targetReps: prescribedReps,
      invalidAttempts: invalidAttempts,
      isVisibilityValid: true,
    );
  }

  /// Builds the final [SessionSummary] strictly from gathered telemetry.
  SessionSummary generateSummary({
    required String sessionId,
    required String planId,
    required String patientId,
  }) {
    return SessionSummaryGenerator.generate(
      sessionId: sessionId,
      planId: planId,
      patientId: patientId,
      exerciseName: rule.name,
      exerciseType: rule.type,
      prescribedReps: prescribedReps,
      validReps: validReps,
      invalidAttempts: invalidAttempts,
      targetHoldSeconds: targetHoldSeconds,
      correctHoldSeconds: _holdEngine?.correctHoldSeconds ?? 0.0,
      incorrectHoldSeconds: _holdEngine?.incorrectHoldSeconds ?? 0.0,
      visibilityLossSeconds: _totalVisibilityLossSeconds + (_holdEngine?.visibilityLossSeconds ?? 0.0),
      events: _sessionEvents,
      repEvents: _repEvents,
    );
  }
}
