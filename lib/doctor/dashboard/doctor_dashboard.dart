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

    final double avgAccuracy = sessions.isEmpty
        ? 0
        : sessions.map((s) => s.summary.accuracyPercentage).reduce((a, b) => a + b) / sessions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinician Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppTheme.textMuted),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Clinician Info Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.surfaceBg,
                      child: const Icon(Icons.medical_services_rounded, color: AppTheme.primaryTeal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUser?.name ?? 'Dr. Sarah Chen, PT, DPT',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textLight,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Chief Physiotherapist • Orthopedic Care',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Patient Roster Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Patient Roster',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${firestore.allPatients.length} patients',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: firestore.allPatients.map((p) {
                    final isSelected = p.patientId == _selectedPatientId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: isSelected ? AppTheme.darkBg : AppTheme.surfaceBg,
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
                        backgroundColor: AppTheme.surfaceBg,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryTeal : AppTheme.cardBorder,
                          width: 1,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.darkBg : AppTheme.textLight,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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

              // 3. Active Patient Snapshot Card (At a Glance)
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.surfaceBg,
                              child: Text(
                                initials,
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryAccent, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  healthProfile?.patientName ?? 'Alex Rivera',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppTheme.textLight,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Age ${healthProfile?.age ?? 28} • ${healthProfile?.affectedBodyPart ?? "Right Biceps"}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.stateCorrect.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.stateCorrect.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Active Care',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.stateCorrect,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      healthProfile?.conditionNotes ?? 'Mild distal biceps tendinopathy.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textLight, height: 1.35),
                    ),
                    const SizedBox(height: 14),

                    // At-a-Glance 3-Stat Strip
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TARGET AREA', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  (healthProfile?.affectedBodyPart ?? 'Right Elbow').split(' / ').first,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textLight),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 26, color: AppTheme.cardBorder),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SESSIONS', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${sessions.length} recorded',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryAccent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 26, color: AppTheme.cardBorder),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('AVG ACCURACY', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    sessions.isEmpty ? '—' : '${avgAccuracy.toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.stateCorrect),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Fast Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.person_search_rounded, size: 16),
                            label: const Text('Health Profile'),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_task_rounded, size: 16),
                            label: const Text('Create Plan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: AppTheme.darkBg,
                            ),
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
              const SizedBox(height: 20),

              // 4. Active Prescribed Plans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Exercise Plans',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${plans.length} prescribed',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (plans.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'No active exercise plans assigned yet.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                )
              else
                ...plans.map((p) => _buildPlanItem(context, p)),
              const SizedBox(height: 20),

              // 5. Recent Exercise Sessions & AI Summaries
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Completed Sessions & AI Review',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${sessions.length} recorded',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (sessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'No completed patient sessions recorded yet.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                )
              else
                ...sessions.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.summary.exerciseName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.stateCorrect.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.stateCorrect.withOpacity(0.25)),
                                ),
                                child: Text(
                                  '${s.summary.accuracyPercentage.toStringAsFixed(0)}% Accuracy',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.stateCorrect,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.summary.exerciseType == ExerciseType.rep
                                ? 'Valid: ${s.summary.validReps} / ${s.summary.targetReps} reps  •  Incomplete: ${s.summary.invalidAttempts}'
                                : 'Hold: ${s.summary.correctHoldSeconds.toStringAsFixed(0)}s  •  Pauses: ${s.summary.incorrectHoldSeconds.toStringAsFixed(0)}s',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.summary.aiSummaryText,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textLight, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.analytics_outlined, size: 15),
                              label: const Text('Review AI Summary', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
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
                    )),
              const SizedBox(height: 20),

              // 6. Subtle Regulatory Note at Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 15, color: AppTheme.primaryTeal),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        AppConstants.clinicalScopeBoundaryStatement,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, ExercisePlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.exerciseName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.textLight,
                ),
              ),
              if (plan.isClinicianOverridden)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.stateInsufficientVisibility.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.stateInsufficientVisibility.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Clinician Override',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.stateInsufficientVisibility,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target: ${plan.effectiveTargetAngle.toStringAsFixed(1)}° (±${plan.extractedAngleTolerance.toStringAsFixed(0)}°)  •  Side: ${plan.bodySide.name.toUpperCase()}',
            style: const TextStyle(fontSize: 13, color: AppTheme.primaryAccent, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            plan.exerciseType == ExerciseType.rep
                ? 'Prescription: ${plan.reps} reps × ${plan.sets} sets'
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
                    Icon(Icons.videocam_rounded, size: 15, color: AppTheme.primaryTeal),
                    SizedBox(width: 4),
                    Text(
                      'Clinician Video Attached',
                      style: TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.play_circle_outline, size: 15),
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
    );
  }
}
