// lib/models/movement_event.dart
// Specification v7 Section 8.2 & 23: Rep, Hold, and Session Event Contracts

import 'enums.dart';
import 'landmark.dart';

class RepEvent {
  final int repIndex;
  final bool isValid;
  final double peakAngle;
  final double targetAngle;
  final IssueCode issueCode;
  final DateTime timestamp;

  const RepEvent({
    required this.repIndex,
    required this.isValid,
    required this.peakAngle,
    required this.targetAngle,
    this.issueCode = IssueCode.none,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'repIndex': repIndex,
        'isValid': isValid,
        'peakAngle': peakAngle,
        'targetAngle': targetAngle,
        'issueCode': issueCode.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RepEvent.fromJson(Map<String, dynamic> json) => RepEvent(
        repIndex: json['repIndex'] as int,
        isValid: json['isValid'] as bool,
        peakAngle: (json['peakAngle'] as num).toDouble(),
        targetAngle: (json['targetAngle'] as num).toDouble(),
        issueCode: IssueCode.values.firstWhere(
          (e) => e.name == json['issueCode'],
          orElse: () => IssueCode.none,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class HoldState {
  final double currentHoldSeconds;
  final double targetHoldSeconds;
  final bool isHolding;
  final bool isPaused;
  final IssueCode issueCode;

  const HoldState({
    this.currentHoldSeconds = 0.0,
    required this.targetHoldSeconds,
    this.isHolding = false,
    this.isPaused = false,
    this.issueCode = IssueCode.none,
  });

  HoldState copyWith({
    double? currentHoldSeconds,
    double? targetHoldSeconds,
    bool? isHolding,
    bool? isPaused,
    IssueCode? issueCode,
  }) {
    return HoldState(
      currentHoldSeconds: currentHoldSeconds ?? this.currentHoldSeconds,
      targetHoldSeconds: targetHoldSeconds ?? this.targetHoldSeconds,
      isHolding: isHolding ?? this.isHolding,
      isPaused: isPaused ?? this.isPaused,
      issueCode: issueCode ?? this.issueCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentHoldSeconds': currentHoldSeconds,
        'targetHoldSeconds': targetHoldSeconds,
        'isHolding': isHolding,
        'isPaused': isPaused,
        'issueCode': issueCode.name,
      };

  factory HoldState.fromJson(Map<String, dynamic> json) => HoldState(
        currentHoldSeconds: (json['currentHoldSeconds'] as num).toDouble(),
        targetHoldSeconds: (json['targetHoldSeconds'] as num).toDouble(),
        isHolding: json['isHolding'] as bool? ?? false,
        isPaused: json['isPaused'] as bool? ?? false,
        issueCode: IssueCode.values.firstWhere(
          (e) => e.name == json['issueCode'],
          orElse: () => IssueCode.none,
        ),
      );
}

class SessionEvent {
  final DateTime timestamp;
  final AiState aiState;
  final double currentAngle;
  final double targetAngle;
  final IssueCode issueCode;
  final RepPhase? repPhase;
  final double? durationSeconds;

  const SessionEvent({
    required this.timestamp,
    required this.aiState,
    required this.currentAngle,
    required this.targetAngle,
    this.issueCode = IssueCode.none,
    this.repPhase,
    this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'aiState': aiState.name,
        'currentAngle': currentAngle,
        'targetAngle': targetAngle,
        'issueCode': issueCode.name,
        'repPhase': repPhase?.name,
        'durationSeconds': durationSeconds,
      };

  factory SessionEvent.fromJson(Map<String, dynamic> json) => SessionEvent(
        timestamp: DateTime.parse(json['timestamp'] as String),
        aiState: AiState.values.firstWhere((e) => e.name == json['aiState']),
        currentAngle: (json['currentAngle'] as num).toDouble(),
        targetAngle: (json['targetAngle'] as num).toDouble(),
        issueCode: IssueCode.values.firstWhere(
          (e) => e.name == json['issueCode'],
          orElse: () => IssueCode.none,
        ),
        repPhase: json['repPhase'] != null
            ? RepPhase.values.firstWhere((e) => e.name == json['repPhase'])
            : null,
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
      );
}

class EngineFrame {
  final DateTime timestamp;
  final Map<String, Landmark> landmarks;
  final double currentAngle;
  final double targetAngle;
  final double tolerance;
  final AiState aiState;
  final IssueCode issueCode;
  final RepPhase repPhase;
  final HoldState? holdState;
  final String feedbackMessage;
  final int validReps;
  final int targetReps;
  final int invalidAttempts;
  final bool isVisibilityValid;

  const EngineFrame({
    required this.timestamp,
    required this.landmarks,
    required this.currentAngle,
    required this.targetAngle,
    required this.tolerance,
    required this.aiState,
    required this.issueCode,
    required this.repPhase,
    this.holdState,
    required this.feedbackMessage,
    required this.validReps,
    required this.targetReps,
    required this.invalidAttempts,
    required this.isVisibilityValid,
  });
}
