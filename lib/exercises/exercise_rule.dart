// lib/exercises/exercise_rule.dart
// Unified Exercise Rule Interface per Specification v7 Section 9

import '../models/enums.dart';
import '../models/landmark.dart';
import '../models/movement_event.dart';
import '../models/reference_profile.dart';

abstract class ExerciseRule {
  String get id;
  String get name;
  ExerciseType get type;
  JointDefinition get jointDefinition;
  BiomechanicsBounds get bounds;

  /// Analyzes a clinician-provided reference angle series to extract the target profile.
  ReferenceProfile analyzeReference(
    List<AngleSample> referenceSeries, {
    String exerciseId = 'bicep_curl',
    BodySide bodySide = BodySide.right,
    ExtractionMethod extractionMethod = ExtractionMethod.videoFile,
  });

  /// Evaluates patient's live movement against the reference profile.
  AiState analyzePatient(
    double currentAngle,
    ReferenceProfile profile,
    bool visibilityValid,
  );

  /// Generates direction-aware corrective feedback.
  String getFeedback(
    double currentAngle,
    ReferenceProfile profile,
    AiState state,
    IssueCode issueCode,
  );

  /// Evaluates repetitions for rep-based exercises.
  RepEvent? detectRep(
    List<AngleSample> history,
    ReferenceProfile profile,
  );

  /// Evaluates hold progress for hold-based exercises.
  HoldState detectHold(
    AiState state,
    HoldState currentHold,
    double deltaSeconds,
  );
}
