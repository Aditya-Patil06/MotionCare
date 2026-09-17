// lib/patient/results/session_result_screen.dart
// Specification v7 Section 2.2 & 30: Patient Session Result Screen

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/session.dart';

class SessionResultScreen extends StatelessWidget {
  final SessionRecord sessionRecord;

  const SessionResultScreen({super.key, required this.sessionRecord});

  @override
  Widget build(BuildContext context) {
    final summary = sessionRecord.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Completed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Success Header Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.stateCorrect.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt,
                size: 64,
                color: AppTheme.stateCorrect,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${summary.exerciseName} Complete!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your exercise session has been analyzed and forwarded to your clinician.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),

            // Performance Cards
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    title: 'Accuracy Score',
                    value: '${summary.accuracyPercentage.toStringAsFixed(0)}%',
                    subtitle: 'Movement precision',
                    color: AppTheme.stateCorrect,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCard(
                    title: 'Completed Reps',
                    value: '${summary.validReps} / ${summary.targetReps}',
                    subtitle: '${summary.invalidAttempts} incomplete attempts',
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // AI Movement Summary Box
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights,
                            color: AppTheme.primaryTeal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Movement Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textLight,
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
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mandatory Clinical Scope Boundary
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceBg),
              ),
              child: const Text(
                AppConstants.clinicalScopeBoundaryStatement,
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            // Return to Dashboard Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Return to Patient Home'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
