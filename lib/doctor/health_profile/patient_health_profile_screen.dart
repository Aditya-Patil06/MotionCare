// lib/doctor/health_profile/patient_health_profile_screen.dart
// Specification v7 Section 7 & 9: Clinician-facing Patient Health Profile

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/patient_health_profile.dart';
import '../../services/firestore/firestore_service.dart';

class PatientHealthProfileScreen extends StatefulWidget {
  final String patientId;

  const PatientHealthProfileScreen({super.key, required this.patientId});

  @override
  State<PatientHealthProfileScreen> createState() =>
      _PatientHealthProfileScreenState();
}

class _PatientHealthProfileScreenState
    extends State<PatientHealthProfileScreen> {
  late TextEditingController _conditionController;
  late TextEditingController _bodyPartController;
  late TextEditingController _limitationsController;
  late TextEditingController _historyController;
  late TextEditingController _symptomsController;
  late TextEditingController _clinicianNotesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final firestore = context.read<FirestoreService>();
    final profile =
        firestore.getHealthProfile(widget.patientId) ??
        PatientHealthProfile(
          patientId: widget.patientId,
          patientName: 'Demo Patient',
          age: 30,
          conditionNotes: '',
          affectedBodyPart: '',
          limitations: '',
          previousHistory: '',
          currentSymptoms: '',
          clinicianNotes: '',
          updatedAt: DateTime.now(),
        );

    _conditionController = TextEditingController(text: profile.conditionNotes);
    _bodyPartController = TextEditingController(text: profile.affectedBodyPart);
    _limitationsController = TextEditingController(text: profile.limitations);
    _historyController = TextEditingController(text: profile.previousHistory);
    _symptomsController = TextEditingController(text: profile.currentSymptoms);
    _clinicianNotesController = TextEditingController(
      text: profile.clinicianNotes,
    );
  }

  @override
  void dispose() {
    _conditionController.dispose();
    _bodyPartController.dispose();
    _limitationsController.dispose();
    _historyController.dispose();
    _symptomsController.dispose();
    _clinicianNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final firestore = context.read<FirestoreService>();
    final existing = firestore.getHealthProfile(widget.patientId);

    final updated =
        (existing ??
                PatientHealthProfile(
                  patientId: widget.patientId,
                  patientName: 'Demo Patient',
                  age: 30,
                  conditionNotes: '',
                  affectedBodyPart: '',
                  limitations: '',
                  previousHistory: '',
                  currentSymptoms: '',
                  clinicianNotes: '',
                  updatedAt: DateTime.now(),
                ))
            .copyWith(
              conditionNotes: _conditionController.text,
              affectedBodyPart: _bodyPartController.text,
              limitations: _limitationsController.text,
              previousHistory: _historyController.text,
              currentSymptoms: _symptomsController.text,
              clinicianNotes: _clinicianNotesController.text,
              updatedAt: DateTime.now(),
            );

    await firestore.updateHealthProfile(updated);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient Health Profile updated successfully.'),
          backgroundColor: AppTheme.stateCorrect,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final profile = firestore.getHealthProfile(widget.patientId);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.patientName ?? 'Patient Health Profile'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save Profile',
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mandatory Clinical Scope Boundary Card
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryTeal.withOpacity(0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: AppTheme.primaryTeal,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppConstants.clinicalScopeBoundaryStatement,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patient Demographics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryTeal.withOpacity(0.2),
                      child: Text(
                        (profile?.patientName.isNotEmpty ?? false)
                            ? profile!.patientName[0]
                            : 'P',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.patientName ?? 'Alex Rivera',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Age: ${profile?.age ?? 28}  •  Patient ID: ${widget.patientId}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Clinical Health Context',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _conditionController,
              label: 'Condition / Injury Description',
              icon: Icons.healing,
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _bodyPartController,
              label: 'Affected Body Part',
              icon: Icons.accessibility_new,
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _limitationsController,
              label: 'Relevant Limitations / Restrictions',
              icon: Icons.warning_amber,
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _symptomsController,
              label: 'Current Symptoms',
              icon: Icons.sick_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _historyController,
              label: 'Previous Physiotherapy History',
              icon: Icons.history,
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _clinicianNotesController,
              label: 'Clinician Assessment & Protocol Notes',
              icon: Icons.note_alt_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Save Health Profile'),
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryTeal, size: 20),
        filled: true,
        fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.surfaceBg.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryTeal),
        ),
      ),
    );
  }
}
