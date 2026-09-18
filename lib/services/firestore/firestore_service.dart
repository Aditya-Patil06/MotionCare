// lib/services/firestore/firestore_service.dart
// Specification v7 Section 7, 27, 28: Firestore Persistence Service with Clinician Workflow

import 'package:flutter/foundation.dart';

import '../../models/enums.dart';
import '../../models/patient_health_profile.dart';
import '../../models/plan.dart';
import '../../models/session.dart';

class FirestoreService extends ChangeNotifier {
  // In-memory persistent state (mirroring Cloud Firestore schema)
  final Map<String, PatientHealthProfile> _healthProfiles = {};
  final List<ExercisePlan> _plans = [];
  final List<SessionRecord> _sessions = [];

  FirestoreService() {
    _seedInitialDemoData();
  }

  List<ExercisePlan> get plans => List.unmodifiable(_plans);
  List<SessionRecord> get sessions => List.unmodifiable(_sessions);

  void _seedInitialDemoData() {
    // 1. Initial Health Profile for Demo Patient Alex Rivera
    final profile = PatientHealthProfile(
      patientId: 'pat_alex_rivera',
      patientName: 'Alex Rivera',
      age: 28,
      conditionNotes: 'Mild distal biceps tendinopathy following repetitive eccentric strain during tennis serve.',
      affectedBodyPart: 'Right Elbow / Biceps',
      limitations: 'Avoid rapid terminal extension under high load.',
      previousHistory: 'No prior surgical history. Conservative physical therapy completed 2 years ago.',
      currentSymptoms:
          'Stiffness and mild discomfort during late flexion (VAS 3/10).',
      clinicianNotes: 'Focus on slow, controlled concentric-eccentric repetitions. Strict form monitoring required.',
      assessmentNotes: 'Initial intake baseline assessment completed.',
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    _healthProfiles[profile.patientId] = profile;

    // Additional patient: Maya Lin
    final mayaProfile = PatientHealthProfile(
      patientId: 'pat_maya_lin',
      patientName: 'Maya Lin',
      age: 34,
      conditionNotes: 'Post-arthroscopic subacromial decompression rehabilitation. Strengthening rotator cuff and deltoid stability.',
      affectedBodyPart: 'Left Shoulder / Rotator Cuff',
      limitations: 'Limit active abduction to 90 degrees initially. Avoid abrupt overhead jerks.',
      previousHistory: 'Rotator cuff repair performed 8 weeks ago. Phase 2 physical therapy underway.',
      currentSymptoms: 'Mild fatigue on sustained lateral hold (VAS 2/10). No acute sharp pain.',
      clinicianNotes: 'Prescribe isometric shoulder raise holds at 60-80 degrees. Pacing and posture alignment are key.',
      assessmentNotes: 'Week 8 post-op check passed with good passive ROM.',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    _healthProfiles[mayaProfile.patientId] = mayaProfile;

    // Additional patient: David Kim
    final davidProfile = PatientHealthProfile(
      patientId: 'pat_david_kim',
      patientName: 'David Kim',
      age: 42,
      conditionNotes: 'Lateral epicondylitis (tennis elbow) with associated forearm flexor weakness from computer ergonomics.',
      affectedBodyPart: 'Right Arm / Forearm',
      limitations: 'Avoid heavy isometric grip loading.',
      previousHistory: 'Conservative management for 3 months.',
      currentSymptoms: 'Dull ache after extended mouse usage.',
      clinicianNotes:
          'Focus on eccentric bicep curling and wrist extensor integration.',
      assessmentNotes: 'Grip strength at 85% of unaffected limb.',
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
    );
    _healthProfiles[davidProfile.patientId] = davidProfile;

    // 2. Initial Assigned Plan for Bicep Curl
    final initialPlan = ExercisePlan(
      id: 'plan_bicep_curl_alex',
      doctorId: 'doc_sarah_chen',
      patientId: 'pat_alex_rivera',
      exerciseId: 'bicep_curl',
      exerciseName: 'Bicep Curl',
      exerciseType: ExerciseType.rep,
      referenceVideoUrl: 'assets/demo/reference_bicep_curl.mp4',
      extractedTargetAngle: 42.0,
      extractedAngleTolerance: 12.0,
      extractionConfidence: 0.92,
      bodySide: BodySide.right,
      reps: 10,
      sets: 3,
      status: PlanStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    _plans.add(initialPlan);

    // 3. Initial Baseline Session Record for Progress Visualization
    final baselineSummary = SessionSummary(
      sessionId: 'sess_prev_001',
      planId: initialPlan.id,
      patientId: 'pat_alex_rivera',
      exerciseName: 'Bicep Curl',
      exerciseType: ExerciseType.rep,
      validReps: 8,
      targetReps: 10,
      invalidAttempts: 2,
      accuracyPercentage: 80.0,
      commonIssue: IssueCode.incompleteMovement,
      aiSummaryText: 'Patient completed 8 valid repetitions out of 10 prescribed repetitions. 2 attempts were incomplete and did not reach the target angle. Movement consistency remained stable for completed curls.',
      clinicianReviewSuggestion: 'Consider reviewing whether movement range decreases during later repetitions.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    _sessions.add(
      SessionRecord(
        id: 'sess_prev_001',
        planId: initialPlan.id,
        patientId: 'pat_alex_rivera',
        exerciseId: 'bicep_curl',
        summary: baselineSummary,
        events: const [],
      ),
    );
  }

  // --- Patient Operations ---
  List<PatientHealthProfile> get allPatients => _healthProfiles.values.toList();

  Future<void> addPatient(PatientHealthProfile profile) async {
    _healthProfiles[profile.patientId] = profile;
    notifyListeners();
  }

  // --- Health Profile Operations ---
  PatientHealthProfile? getHealthProfile(String patientId) {
    return _healthProfiles[patientId];
  }

  Future<void> updateHealthProfile(PatientHealthProfile profile) async {
    _healthProfiles[profile.patientId] = profile;
    notifyListeners();
  }

  // --- Plan Operations ---
  List<ExercisePlan> getPlansForPatient(String patientId) {
    return _plans.where((p) => p.patientId == patientId).toList();
  }

  Future<void> savePlan(ExercisePlan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index >= 0) {
      _plans[index] = plan;
    } else {
      _plans.add(plan);
    }
    notifyListeners();
  }

  // --- Session Operations ---
  List<SessionRecord> getSessionsForPatient(String patientId) {
    return _sessions.where((s) => s.patientId == patientId).toList();
  }

  List<SessionRecord> getSessionsForPlan(String planId) {
    return _sessions.where((s) => s.planId == planId).toList();
  }

  Future<void> saveSession(SessionRecord session) async {
    _sessions.insert(0, session);
    notifyListeners();
  }
}
