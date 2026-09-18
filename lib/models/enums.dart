// lib/models/enums.dart
// Authoritative enum contracts according to Specification v7 Section 8.1

enum ExerciseType { rep, hold }

enum AiState { correct, incorrect, insufficientVisibility }

enum RepPhase { idle, flexing, peakReached, returning }

enum MovementPhase { start, moving, peak, returnPhase }

enum BodySide { left, right, auto }

enum PlanStatus { draft, awaitingReview, active, completed, rejected }

enum ExtractionMethod { liveRecord, videoFile }

enum IssueCode {
  none,
  incompleteMovement,
  overshoot,
  angleTooLow,
  angleTooHigh,
  postureDeviation,
  insufficientVisibility,
  movementTooFast,
  extractionLowConfidence,
}
