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
            // Success Header Icon & Accuracy Hero
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.stateCorrect.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.stateCorrect.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 44,
                color: AppTheme.stateCorrect,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${summary.exerciseName} Complete',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textLight,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Session analyzed and synced with your clinician.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),

            // Performance Cards (At a Glance)
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    title: 'ACCURACY SCORE',
                    value: '${summary.accuracyPercentage.toStringAsFixed(0)}%',
                    subtitle: 'Movement precision',
                    color: AppTheme.stateCorrect,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCard(
                    title: 'COMPLETED REPS',
                    value: '${summary.validReps} / ${summary.targetReps}',
                    subtitle: '${summary.invalidAttempts} incomplete attempts',
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Movement Summary Box
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primaryTeal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Movement Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textLight,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary.aiSummaryText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mandatory Clinical Scope Boundary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Text(
                AppConstants.clinicalScopeBoundaryStatement,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Return to Dashboard Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Return to Patient Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: AppTheme.darkBg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
