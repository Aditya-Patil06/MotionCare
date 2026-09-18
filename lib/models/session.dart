// lib/models/session.dart
// Specification v7 Section 23, 24, 25, 27: Session Data Contracts

import 'enums.dart';
import 'movement_event.dart';

class SessionSummary {
  final String sessionId;
  final String planId;
  final String patientId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final int validReps;
  final int targetReps;
  final int invalidAttempts;
  final double correctHoldSeconds;
  final double targetHoldSeconds;
  final double incorrectHoldSeconds;
  final double visibilityLossSeconds;
  final double accuracyPercentage;
  final IssueCode commonIssue;
  final String aiSummaryText;
  final String clinicianReviewSuggestion;
  final DateTime createdAt;

  const SessionSummary({
    required this.sessionId,
    required this.planId,
    required this.patientId,
    required this.exerciseName,
    required this.exerciseType,
    this.validReps = 0,
    this.targetReps = 0,
    this.invalidAttempts = 0,
    this.correctHoldSeconds = 0.0,
    this.targetHoldSeconds = 0.0,
    this.incorrectHoldSeconds = 0.0,
    this.visibilityLossSeconds = 0.0,
    required this.accuracyPercentage,
    this.commonIssue = IssueCode.none,
    required this.aiSummaryText,
    required this.clinicianReviewSuggestion,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'planId': planId,
    'patientId': patientId,
    'exerciseName': exerciseName,
    'exerciseType': exerciseType.name,
    'validReps': validReps,
    'targetReps': targetReps,
    'invalidAttempts': invalidAttempts,
    'correctHoldSeconds': correctHoldSeconds,
    'targetHoldSeconds': targetHoldSeconds,
    'incorrectHoldSeconds': incorrectHoldSeconds,
    'visibilityLossSeconds': visibilityLossSeconds,
    'accuracyPercentage': accuracyPercentage,
    'commonIssue': commonIssue.name,
    'aiSummaryText': aiSummaryText,
    'clinicianReviewSuggestion': clinicianReviewSuggestion,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
    sessionId: json['sessionId'] as String,
    planId: json['planId'] as String,
    patientId: json['patientId'] as String,
    exerciseName: json['exerciseName'] as String,
    exerciseType: ExerciseType.values.firstWhere(
      (e) => e.name == json['exerciseType'],
      orElse: () => ExerciseType.rep,
    ),
    validReps: json['validReps'] as int? ?? 0,
    targetReps: json['targetReps'] as int? ?? 0,
    invalidAttempts: json['invalidAttempts'] as int? ?? 0,
    correctHoldSeconds: (json['correctHoldSeconds'] as num?)?.toDouble() ?? 0.0,
    targetHoldSeconds: (json['targetHoldSeconds'] as num?)?.toDouble() ?? 0.0,
    incorrectHoldSeconds:
        (json['incorrectHoldSeconds'] as num?)?.toDouble() ?? 0.0,
    visibilityLossSeconds:
        (json['visibilityLossSeconds'] as num?)?.toDouble() ?? 0.0,
    accuracyPercentage: (json['accuracyPercentage'] as num).toDouble(),
    commonIssue: IssueCode.values.firstWhere(
      (e) => e.name == json['commonIssue'],
      orElse: () => IssueCode.none,
    ),
    aiSummaryText: json['aiSummaryText'] as String,
    clinicianReviewSuggestion: json['clinicianReviewSuggestion'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class SessionRecord {
  final String id;
  final String planId;
  final String patientId;
  final String exerciseId;
  final SessionSummary summary;
  final List<SessionEvent> events;

  const SessionRecord({
    required this.id,
    required this.planId,
    required this.patientId,
    required this.exerciseId,
    required this.summary,
    required this.events,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'patientId': patientId,
    'exerciseId': exerciseId,
    'summary': summary.toJson(),
    'events': events.map((e) => e.toJson()).toList(),
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    id: json['id'] as String,
    planId: json['planId'] as String,
    patientId: json['patientId'] as String,
    exerciseId: json['exerciseId'] as String,
    summary: SessionSummary.fromJson(json['summary'] as Map<String, dynamic>),
    events:
        (json['events'] as List<dynamic>?)
            ?.map((e) => SessionEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
