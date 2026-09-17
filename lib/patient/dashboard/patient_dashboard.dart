// lib/patient/dashboard/patient_dashboard.dart
// Specification v7 Section 2.2 & 30: Patient Dashboard

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/plan.dart';
import '../calibration/calibration_screen.dart';
import '../exercise/clinician_video_dialog.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firestore/firestore_service.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firestore = context.watch<FirestoreService>();
    final patientId = auth.currentUser?.id ?? 'pat_alex_rivera';
    final plans = firestore.getPlansForPatient(patientId);
    final sessions = firestore.getSessionsForPatient(patientId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Exercise Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: Colors.white70),
            tooltip: 'Sign Out to Login Page',
            onPressed: () {
              auth.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(milliseconds: 300)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Banner
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                        child: const Icon(Icons.person, color: AppTheme.primaryAccent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.name ?? 'Alex Rivera',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                            ),
                            const SizedBox(height: 2),
                            const Text('Assigned Clinician: Dr. Sarah Chen, PT, DPT', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Mandatory Clinical Scope Boundary
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
                ),
                child: const Text(
                  AppConstants.clinicalScopeBoundaryStatement,
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                ),
              ),
              const SizedBox(height: 20),

              // Assigned Exercise Plans Section
              const Text(
                'Assigned Exercise Plans',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
              ),
              const SizedBox(height: 10),
              if (plans.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No assigned plans from clinician.', style: TextStyle(color: AppTheme.textMuted))),
                  ),
                )
              else
                ...plans.map((p) => _buildAssignedPlanCard(context, p)),
              const SizedBox(height: 24),

              // Recent Performance Trends
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Session History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                  Text('${sessions.length} sessions', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              if (sessions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No recorded sessions yet. Start your first exercise!', style: TextStyle(color: AppTheme.textMuted))),
                  ),
                )
              else
                ...sessions.map((s) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.stateCorrect.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check, color: AppTheme.stateCorrect, size: 20),
                        ),
                        title: Text(s.summary.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          s.summary.exerciseType == ExerciseType.rep
                              ? 'Reps: ${s.summary.validReps}/${s.summary.targetReps} • Accuracy: ${s.summary.accuracyPercentage.toStringAsFixed(0)}%'
                              : 'Hold: ${s.summary.correctHoldSeconds.toStringAsFixed(0)}s • Accuracy: ${s.summary.accuracyPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        trailing: Text(
                          s.summary.createdAt.toString().substring(5, 10),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedPlanCard(BuildContext context, ExercisePlan plan) {
    final isRep = plan.exerciseType == ExerciseType.rep;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isRep ? Icons.fitness_center : Icons.timer,
                      color: AppTheme.primaryTeal,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      plan.exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textLight),
                    ),
                  ],
                ),
                if (plan.isClinicianOverridden)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.stateInsufficientVisibility.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Clinician Adjusted', style: TextStyle(fontSize: 10, color: AppTheme.stateInsufficientVisibility, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Personalized Target Angle: ${plan.effectiveTargetAngle.toStringAsFixed(1)}° (±${plan.extractedAngleTolerance.toStringAsFixed(0)}° tolerance)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
            ),
            const SizedBox(height: 4),
            Text(
              isRep
                  ? 'Prescription: ${plan.reps} reps  x  ${plan.sets} sets  •  ${plan.bodySide.name.toUpperCase()} Arm'
                  : 'Prescription: ${plan.holdDurationSeconds.toInt()}s sustained hold  •  ${plan.bodySide.name.toUpperCase()} Arm',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            if (plan.referenceVideoUrl.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.videocam, size: 14, color: AppTheme.primaryTeal),
                  const SizedBox(width: 5),
                  Text(
                    'Doctor Video Demonstration Available',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 22),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_circle_fill, size: 18),
                    label: const Text('Watch Video', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
                    onPressed: () {
                      ClinicianVideoDialog.show(context, plan);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Start Exercise', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.stateCorrect),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CalibrationScreen(plan: plan),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
