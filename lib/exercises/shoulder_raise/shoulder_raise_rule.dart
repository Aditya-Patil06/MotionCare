// lib/exercises/shoulder_raise/shoulder_raise_rule.dart
// Secondary exercise implementing unified ExerciseRule contract per Specification v7 Section 22

import '../../ai/angles/joint_angle_engine.dart';
import '../../ai/feedback/feedback_engine.dart';
import '../../ai/holds/shoulder_hold_engine.dart';
import '../../ai/reference/reference_analyzer.dart';
import '../../models/enums.dart';
import '../../models/landmark.dart';
import '../../models/movement_event.dart';
import '../../models/reference_profile.dart';
import '../exercise_rule.dart';

class ShoulderRaiseRule implements ExerciseRule {
  final BodySide preferredSide;
  late final ShoulderHoldEngine _holdEngine;

  ShoulderRaiseRule({
    this.preferredSide = BodySide.right,
    double targetHoldSeconds = 60.0,
  }) {
    _holdEngine = ShoulderHoldEngine(targetHoldSeconds: targetHoldSeconds);
  }

  ShoulderHoldEngine get holdEngine => _holdEngine;

  @override
  String get id => 'shoulder_raise';

  @override
  String get name => 'Shoulder Raise (Hold)';

  @override
  ExerciseType get type => ExerciseType.hold;

  @override
  BiomechanicsBounds get bounds => const BiomechanicsBounds(
        minPlausibleAngle: 20.0,
        maxPlausibleAngle: 180.0,
        targetMinAngle: 60.0,
        targetMaxAngle: 120.0,
      );

  @override
  JointDefinition get jointDefinition {
    final prefix = preferredSide == BodySide.left ? 'left' : 'right';
    return JointDefinition(
      primaryJoint: '${prefix}_shoulder',
      bodySide: preferredSide,
      jointTriple: JointTriple(
        a: '${prefix}_hip',
        b: '${prefix}_shoulder',
        c: '${prefix}_elbow',
      ),
    );
  }

  /// Extracts Hip-Shoulder-Elbow angle from pose landmarks using locked JointAngleEngine
  double extractAngle(Map<String, Landmark> landmarks) {
    final prefix = preferredSide == BodySide.left ? 'left' : 'right';
    final hip = landmarks['${prefix}_hip'];
    final shoulder = landmarks['${prefix}_shoulder'];
    final elbow = landmarks['${prefix}_elbow'];

    if (hip == null || shoulder == null || elbow == null) {
      return 0.0;
    }

    return JointAngleEngine.computeAngle(hip, shoulder, elbow);
  }

  @override
  ReferenceProfile analyzeReference(
    List<AngleSample> referenceSeries, {
    String exerciseId = 'shoulder_raise',
    BodySide bodySide = BodySide.right,
    ExtractionMethod extractionMethod = ExtractionMethod.videoFile,
  }) {
    // For hold exercises, the reference analyzer identifies the stable hold plateau angle
    final analyzer = ReferenceAnalyzer(
      bounds: bounds,
      prominenceThreshold: 25.0,
      minPeakSeparationSeconds: 0.8,
    );
    return analyzer.analyze(
      samples: referenceSeries,
      exerciseId: exerciseId,
      bodySide: bodySide,
      extractionMethod: extractionMethod,
    );
  }

  @override
  AiState analyzePatient(
    double currentAngle,
    ReferenceProfile profile,
    bool visibilityValid,
  ) {
    if (!visibilityValid) {
      return AiState.insufficientVisibility;
    }

    if (!bounds.isAnglePlausible(currentAngle)) {
      return AiState.correct; // Filter out tracking glitch
    }

    final target = profile.targetAngle;
    final tol = profile.tolerance;

    if (currentAngle >= target - tol && currentAngle <= target + tol) {
      return AiState.correct;
    } else {
      return AiState.incorrect;
    }
  }

  @override
  String getFeedback(
    double currentAngle,
    ReferenceProfile profile,
    AiState state,
    IssueCode issueCode,
  ) {
    return FeedbackEngine.getFeedback(
      aiState: state,
      issueCode: issueCode,
      currentAngle: currentAngle,
      targetAngle: profile.targetAngle,
      tolerance: profile.tolerance,
      repPhase: RepPhase.idle,
      exerciseType: ExerciseType.hold,
    );
  }

  @override
  RepEvent? detectRep(
    List<AngleSample> history,
    ReferenceProfile profile,
  ) {
    return null; // Hold exercises do not produce rep events
  }

  @override
  HoldState detectHold(
    AiState state,
    HoldState currentHold,
    double deltaSeconds,
  ) {
    final issue = state == AiState.correct
        ? IssueCode.none
        : (state == AiState.insufficientVisibility
            ? IssueCode.insufficientVisibility
            : IssueCode.postureDeviation);

    return _holdEngine.processTick(
      aiState: state,
      issueCode: issue,
      deltaSeconds: deltaSeconds,
    );
  }
}
