// lib/exercises/bicep_curl/bicep_curl_rule.dart
// Core MVP exercise rule implementing unified ExerciseRule contract per Specification v7 Section 14

import '../../ai/angles/joint_angle_engine.dart';
import '../../ai/feedback/feedback_engine.dart';
import '../../ai/reference/reference_analyzer.dart';
import '../../ai/reps/bicep_rep_engine.dart';
import '../../models/enums.dart';
import '../../models/landmark.dart';
import '../../models/movement_event.dart';
import '../../models/reference_profile.dart';
import '../exercise_rule.dart';

class BicepCurlRule implements ExerciseRule {
  final BodySide preferredSide;
  late final BicepRepEngine _repEngine;

  BicepCurlRule({this.preferredSide = BodySide.right}) {
    _repEngine = BicepRepEngine();
  }

  BicepRepEngine get repEngine => _repEngine;

  @override
  String get id => 'bicep_curl';

  @override
  String get name => 'Bicep Curl';

  @override
  ExerciseType get type => ExerciseType.rep;

  @override
  BiomechanicsBounds get bounds => const BiomechanicsBounds(
        minPlausibleAngle: 20.0,
        maxPlausibleAngle: 180.0,
        targetMinAngle: 25.0,
        targetMaxAngle: 110.0,
      );

  @override
  JointDefinition get jointDefinition {
    final prefix = preferredSide == BodySide.left ? 'left' : 'right';
    return JointDefinition(
      primaryJoint: '${prefix}_elbow',
      bodySide: preferredSide,
      jointTriple: JointTriple(
        a: '${prefix}_shoulder',
        b: '${prefix}_elbow',
        c: '${prefix}_wrist',
      ),
    );
  }

  /// Extracts joint angle from a raw pose frame using the locked JointAngleEngine
  double extractAngle(Map<String, Landmark> landmarks) {
    final prefix = preferredSide == BodySide.left ? 'left' : 'right';
    final a = landmarks['${prefix}_shoulder'];
    final b = landmarks['${prefix}_elbow'];
    final c = landmarks['${prefix}_wrist'];

    if (a == null || b == null || c == null) {
      return 180.0;
    }

    return JointAngleEngine.computeAngle(a, b, c);
  }

  @override
  ReferenceProfile analyzeReference(
    List<AngleSample> referenceSeries, {
    String exerciseId = 'bicep_curl',
    BodySide bodySide = BodySide.right,
    ExtractionMethod extractionMethod = ExtractionMethod.videoFile,
  }) {
    final analyzer = ReferenceAnalyzer(bounds: bounds);
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
    // 1. Priority 1: Visibility
    if (!visibilityValid) {
      return AiState.insufficientVisibility;
    }

    // 2. Priority 2: Plausibility check (Section 11 & 18)
    if (!bounds.isAnglePlausible(currentAngle)) {
      // Noise artifact, do not penalize patient
      return AiState.correct;
    }

    // 3. Movement correctness based on current phase and target tolerance
    final target = profile.targetAngle;
    final tol = profile.tolerance;

    if (_repEngine.phase == RepPhase.peakReached) {
      // In peak zone, must be within target ± tolerance (or slightly deeper)
      if (currentAngle <= target + tol) {
        return AiState.correct;
      } else {
        return AiState.incorrect;
      }
    } else if (_repEngine.phase == RepPhase.flexing ||
        _repEngine.phase == RepPhase.returning) {
      // During active flexion or return, patient is performing movement
      return AiState.correct;
    }

    // When idle at bottom extension
    return AiState.correct;
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
      repPhase: _repEngine.phase,
      exerciseType: ExerciseType.rep,
    );
  }

  @override
  RepEvent? detectRep(
    List<AngleSample> history,
    ReferenceProfile profile,
  ) {
    if (history.isEmpty) return null;
    final latest = history.last;
    return _repEngine.processSample(
      currentAngle: latest.angle,
      profile: profile,
      isVisibilityValid: latest.visibilityValid,
      timestamp: latest.timestamp,
    );
  }

  @override
  HoldState detectHold(
    AiState state,
    HoldState currentHold,
    double deltaSeconds,
  ) {
    // Rep exercises do not use hold timer
    return currentHold;
  }
}
