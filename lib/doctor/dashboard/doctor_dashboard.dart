// lib/doctor/dashboard/doctor_dashboard.dart
// Specification v7 Section 2.1, 26, 29: Doctor / Physiotherapist Dashboard

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/plan.dart';
import '../../patient/exercise/clinician_video_dialog.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firestore/firestore_service.dart';
import '../health_profile/patient_health_profile_screen.dart';
import '../plans/create_plan_screen.dart';
import '../session_review/session_review_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  String _selectedPatientId = 'pat_alex_rivera';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firestore = context.watch<FirestoreService>();
    final healthProfile = firestore.getHealthProfile(_selectedPatientId);
    final plans = firestore.getPlansForPatient(_selectedPatientId);
    final sessions = firestore.getSessionsForPatient(_selectedPatientId);
    final initials = (healthProfile?.patientName ?? 'Patient')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinician Dashboard'),
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
              // Welcome Banner
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.primaryTeal.withOpacity(0.2),
                        child: const Icon(Icons.medical_services, color: AppTheme.primaryTeal, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.name ?? 'Dr. Sarah Chen, PT, DPT',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                            ),
                            const SizedBox(height: 2),
                            const Text('Chief Physiotherapist  •  Orthopedic Care', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
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
                  border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
                ),
                child: const Text(
                  AppConstants.clinicalScopeBoundaryStatement,
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                ),
              ),
              const SizedBox(height: 20),

              // Assigned Patients Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Patient Roster',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  ),
                  Text('${firestore.allPatients.length} patients', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: firestore.allPatients.map((p) {
                    final isSelected = p.patientId == _selectedPatientId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: isSelected ? AppTheme.darkBg : AppTheme.primaryTeal.withOpacity(0.2),
                          child: Text(
                            p.patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.primaryTeal : AppTheme.textLight,
                            ),
                          ),
                        ),
                        label: Text(p.patientName),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryTeal,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.darkBg : AppTheme.textLight,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedPatientId = p.patientId);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Card(
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
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    healthProfile?.patientName ?? 'Alex Rivera',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textLight),
                                  ),
                                  Text('Age: ${healthProfile?.age ?? 28} • ${healthProfile?.affectedBodyPart ?? "Right Biceps"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.stateCorrect.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Active Care', style: TextStyle(fontSize: 11, color: AppTheme.stateCorrect, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        healthProfile?.conditionNotes ?? 'Mild distal biceps tendinopathy.',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_search, size: 16),
                              label: const Text('Health Profile', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PatientHealthProfileScreen(patientId: _selectedPatientId),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_task, size: 16),
                              label: const Text('Create Plan', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreatePlanScreen(patientId: _selectedPatientId),
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
              ),
              const SizedBox(height: 20),

              // Active Prescribed Plans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Exercise Plans', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                  Text('${plans.length} prescribed', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              if (plans.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No active exercise plans assigned yet.', style: TextStyle(color: AppTheme.textMuted))),
                  ),
                )
              else
                ...plans.map((p) => _buildPlanItem(context, p)),
              const SizedBox(height: 20),

              // Recent Exercise Sessions & AI Summaries
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Completed Sessions & AI Review', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                  Text('${sessions.length} recorded', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              if (sessions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No completed patient sessions recorded yet.', style: TextStyle(color: AppTheme.textMuted))),
                  ),
                )
              else
                ...sessions.map((s) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s.summary.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textLight)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.stateCorrect.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${s.summary.accuracyPercentage.toStringAsFixed(0)}% Accuracy', style: const TextStyle(fontSize: 11, color: AppTheme.stateCorrect, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.summary.exerciseType == ExerciseType.rep
                                  ? 'Valid Reps: ${s.summary.validReps} / ${s.summary.targetReps}  •  Incomplete: ${s.summary.invalidAttempts}'
                                  : 'Hold: ${s.summary.correctHoldSeconds.toStringAsFixed(0)}s  •  Posture Pauses: ${s.summary.incorrectHoldSeconds.toStringAsFixed(0)}s',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.summary.aiSummaryText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textLight, height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.analytics_outlined, size: 16),
                                label: const Text('Review AI Summary & Clinical Suggestion', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => SessionReviewScreen(sessionRecord: s)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, ExercisePlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.exerciseName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textLight),
                ),
                if (plan.isClinicianOverridden)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.stateInsufficientVisibility.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Clinician Override', style: TextStyle(fontSize: 10, color: AppTheme.stateInsufficientVisibility, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Target Angle: ${plan.effectiveTargetAngle.toStringAsFixed(1)}° (±${plan.extractedAngleTolerance.toStringAsFixed(0)}°)  •  Side: ${plan.bodySide.name.toUpperCase()}',
              style: const TextStyle(fontSize: 13, color: AppTheme.primaryAccent),
            ),
            const SizedBox(height: 4),
            Text(
              plan.exerciseType == ExerciseType.rep
                  ? 'Prescription: ${plan.reps} reps  x  ${plan.sets} sets'
                  : 'Prescription: ${plan.holdDurationSeconds.toInt()} seconds hold',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            if (plan.referenceVideoUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.videocam, size: 15, color: AppTheme.primaryTeal),
                      SizedBox(width: 4),
                      Text(
                        'Clinician Video Attached',
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Review Demo Video', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => ClinicianVideoDialog.show(context, plan),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
