// lib/models/reference_profile.dart
// Specification v7 Section 16 & 17: ReferenceProfile and Quality Metadata

import 'enums.dart';

class ReferenceProfile {
  final String exerciseId;
  final double targetAngle;
  final double tolerance; // Default ±12°
  final double confidence;
  final List<MovementPhase> movementPhases;
  final BodySide bodySide;
  final ExtractionMethod extractionMethod;
  final Map<String, dynamic> qualityMetadata;
  final bool isClinicianOverride;
  final bool isPlausible;
  final String? reviewPrompt;

  const ReferenceProfile({
    required this.exerciseId,
    required this.targetAngle,
    this.tolerance = 12.0,
    required this.confidence,
    this.movementPhases = const [
      MovementPhase.start,
      MovementPhase.moving,
      MovementPhase.peak,
      MovementPhase.returnPhase,
    ],
    this.bodySide = BodySide.right,
    this.extractionMethod = ExtractionMethod.videoFile,
    this.qualityMetadata = const {},
    this.isClinicianOverride = false,
    this.isPlausible = true,
    this.reviewPrompt,
  });

  /// Factory for manual clinician override per Section 16
  ReferenceProfile copyWithOverride(double newTargetAngle) {
    return ReferenceProfile(
      exerciseId: exerciseId,
      targetAngle: newTargetAngle,
      tolerance: tolerance,
      confidence: confidence,
      movementPhases: movementPhases,
      bodySide: bodySide,
      extractionMethod: extractionMethod,
      qualityMetadata: {
        ...qualityMetadata,
        'manualOverrideTimestamp': DateTime.now().toIso8601String(),
        'previousExtractedTarget': targetAngle,
      },
      isClinicianOverride: true,
      isPlausible: true,
      reviewPrompt: 'Clinician Override: Manually set to ${newTargetAngle.toStringAsFixed(1)}°',
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'targetAngle': targetAngle,
        'tolerance': tolerance,
        'confidence': confidence,
        'movementPhases': movementPhases.map((e) => e.name).toList(),
        'bodySide': bodySide.name,
        'extractionMethod': extractionMethod.name,
        'qualityMetadata': qualityMetadata,
        'isClinicianOverride': isClinicianOverride,
        'isPlausible': isPlausible,
        'reviewPrompt': reviewPrompt,
      };

  factory ReferenceProfile.fromJson(Map<String, dynamic> json) =>
      ReferenceProfile(
        exerciseId: json['exerciseId'] as String,
        targetAngle: (json['targetAngle'] as num).toDouble(),
        tolerance: (json['tolerance'] as num?)?.toDouble() ?? 12.0,
        confidence: (json['confidence'] as num).toDouble(),
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
        extractionMethod: ExtractionMethod.values.firstWhere(
          (e) => e.name == json['extractionMethod'],
          orElse: () => ExtractionMethod.videoFile,
        ),
        qualityMetadata: json['qualityMetadata'] as Map<String, dynamic>? ?? {},
        isClinicianOverride: json['isClinicianOverride'] as bool? ?? false,
        isPlausible: json['isPlausible'] as bool? ?? true,
        reviewPrompt: json['reviewPrompt'] as String?,
      );
}
