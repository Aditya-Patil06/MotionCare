// lib/doctor/session_review/session_review_screen.dart
// Specification v7 Section 24, 25, 26: Clinician Session Review with AI Summary & Suggestion

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/session.dart';

class SessionReviewScreen extends StatelessWidget {
  final SessionRecord sessionRecord;

  const SessionReviewScreen({super.key, required this.sessionRecord});

  @override
  Widget build(BuildContext context) {
    final summary = sessionRecord.summary;
    final isRep = summary.exerciseType == ExerciseType.rep;

    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Session Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Exercise & Date
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isRep ? Icons.fitness_center : Icons.timer,
                        color: AppTheme.primaryTeal,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.exerciseName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Session ID: ${summary.sessionId}  •  ${summary.createdAt.toString().substring(0, 16)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.stateCorrect.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${summary.accuracyPercentage.toStringAsFixed(0)}% Acc',
                        style: const TextStyle(
                          color: AppTheme.stateCorrect,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Performance Metrics Cards Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: isRep ? 'Valid Reps' : 'Hold Time',
                    value: isRep
                        ? '${summary.validReps} / ${summary.targetReps}'
                        : '${summary.correctHoldSeconds.toStringAsFixed(0)}s / ${summary.targetHoldSeconds.toStringAsFixed(0)}s',
                    icon: Icons.check_circle,
                    color: AppTheme.stateCorrect,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: isRep ? 'Incomplete Reps' : 'Posture Deviations',
                    value: isRep
                        ? '${summary.invalidAttempts}'
                        : '${summary.incorrectHoldSeconds.toStringAsFixed(0)}s paused',
                    icon: Icons.error_outline,
                    color: AppTheme.stateIncorrect,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Visibility Loss',
                    value:
                        '${summary.visibilityLossSeconds.toStringAsFixed(1)}s (excluded)',
                    icon: Icons.visibility_off_outlined,
                    color: AppTheme.stateInsufficientVisibility,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Primary Issue',
                    value: summary.commonIssue == IssueCode.none
                        ? 'None (Clean form)'
                        : summary.commonIssue.name,
                    icon: Icons.flag_outlined,
                    color: AppTheme.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // AI-Generated Session Summary Card (Section 24)
            const Text(
              'AI-Generated Session Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primaryTeal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Observed Movement Pattern',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary.aiSummaryText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                      height: 1.5,
                    ),
                  ),
                  const Divider(height: 24),

                  // Clinician Review Suggestion (Section 24)
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.stateInsufficientVisibility,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Clinician Review Suggestion',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.stateInsufficientVisibility,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.clinicianReviewSuggestion,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mandatory Clinical Scope Notice
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceBg),
              ),
              child: const Text(
                AppConstants.clinicalScopeBoundaryStatement,
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 20),

            // Chronological Event Log
            if (sessionRecord.events.isNotEmpty) ...[
              const Text(
                'Recorded Session Telemetry Timeline',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessionRecord.events.take(15).length,
                itemBuilder: (context, index) {
                  final e = sessionRecord.events[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${e.timestamp.second}s: State: ${e.aiState.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: e.aiState == AiState.correct
                                ? AppTheme.stateCorrect
                                : (e.aiState == AiState.incorrect
                                      ? AppTheme.stateIncorrect
                                      : AppTheme.stateInsufficientVisibility),
                          ),
                        ),
                        Text(
                          'Angle: ${e.currentAngle.toStringAsFixed(1)}°',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
