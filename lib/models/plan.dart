// lib/models/plan.dart
// Specification v7 Section 27: ExercisePlan Data Contract

import 'enums.dart';

class ExercisePlan {
  final String id;
  final String doctorId;
  final String patientId;
  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final String referenceVideoUrl;
  final double extractedTargetAngle;
  final double extractedAngleTolerance;
  final double extractionConfidence;
  final double? manualOverrideAngle;
  final List<MovementPhase> movementPhases;
  final BodySide bodySide;
  final int reps;
  final int sets;
  final double holdDurationSeconds;
  final PlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExercisePlan({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    this.referenceVideoUrl = '',
    required this.extractedTargetAngle,
    this.extractedAngleTolerance = 12.0,
    required this.extractionConfidence,
    this.manualOverrideAngle,
    this.movementPhases = const [
      MovementPhase.start,
      MovementPhase.moving,
      MovementPhase.peak,
      MovementPhase.returnPhase,
    ],
    this.bodySide = BodySide.right,
    this.reps = 10,
    this.sets = 3,
    this.holdDurationSeconds = 60.0,
    this.status = PlanStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The effective target angle used for live patient comparison.
  /// If clinician manually overrode, returns manualOverrideAngle; else returns extractedTargetAngle.
  double get effectiveTargetAngle => manualOverrideAngle ?? extractedTargetAngle;

  bool get isClinicianOverridden => manualOverrideAngle != null;

  ExercisePlan copyWith({
    String? referenceVideoUrl,
    double? extractedTargetAngle,
    double? extractedAngleTolerance,
    double? extractionConfidence,
    double? manualOverrideAngle,
    BodySide? bodySide,
    int? reps,
    int? sets,
    double? holdDurationSeconds,
    PlanStatus? status,
    DateTime? updatedAt,
  }) {
    return ExercisePlan(
      id: id,
      doctorId: doctorId,
      patientId: patientId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseType: exerciseType,
      referenceVideoUrl: referenceVideoUrl ?? this.referenceVideoUrl,
      extractedTargetAngle: extractedTargetAngle ?? this.extractedTargetAngle,
      extractedAngleTolerance: extractedAngleTolerance ?? this.extractedAngleTolerance,
      extractionConfidence: extractionConfidence ?? this.extractionConfidence,
      manualOverrideAngle: manualOverrideAngle ?? this.manualOverrideAngle,
      movementPhases: movementPhases,
      bodySide: bodySide ?? this.bodySide,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      holdDurationSeconds: holdDurationSeconds ?? this.holdDurationSeconds,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorId': doctorId,
        'patientId': patientId,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'exerciseType': exerciseType.name,
        'referenceVideoUrl': referenceVideoUrl,
        'extractedTargetAngle': extractedTargetAngle,
        'extractedAngleTolerance': extractedAngleTolerance,
        'extractionConfidence': extractionConfidence,
        'manualOverrideAngle': manualOverrideAngle,
        'movementPhases': movementPhases.map((e) => e.name).toList(),
        'bodySide': bodySide.name,
        'reps': reps,
        'sets': sets,
        'holdDurationSeconds': holdDurationSeconds,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ExercisePlan.fromJson(Map<String, dynamic> json) => ExercisePlan(
        id: json['id'] as String,
        doctorId: json['doctorId'] as String,
        patientId: json['patientId'] as String,
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        exerciseType: ExerciseType.values.firstWhere(
          (e) => e.name == json['exerciseType'],
          orElse: () => ExerciseType.rep,
        ),
        referenceVideoUrl: json['referenceVideoUrl'] as String? ?? '',
        extractedTargetAngle:
            (json['extractedTargetAngle'] as num).toDouble(),
        extractedAngleTolerance:
            (json['extractedAngleTolerance'] as num?)?.toDouble() ?? 12.0,
        extractionConfidence:
            (json['extractionConfidence'] as num).toDouble(),
        manualOverrideAngle:
            (json['manualOverrideAngle'] as num?)?.toDouble(),
        movementPhases: (json['movementPhases'] as List<dynamic>?)
                ?.map((e) => MovementPhase.values.firstWhere(
                      (m) => m.name == e,
                      orElse: () => MovementPhase.moving,
                    ))
                .toList() ??
            const [
              MovementPhase.start,
              MovementPhase.moving,
              MovementPhase.peak,
              MovementPhase.returnPhase,
            ],
        bodySide: BodySide.values.firstWhere(
          (e) => e.name == json['bodySide'],
          orElse: () => BodySide.right,
        ),
        reps: json['reps'] as int? ?? 10,
        sets: json['sets'] as int? ?? 3,
        holdDurationSeconds:
            (json['holdDurationSeconds'] as num?)?.toDouble() ?? 60.0,
        status: PlanStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PlanStatus.active,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
