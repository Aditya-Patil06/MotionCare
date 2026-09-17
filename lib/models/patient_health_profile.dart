// lib/models/patient_health_profile.dart
// Specification v7 Section 7 & 27: Patient Health Profile
// Clinical context reviewed by clinician before exercise plan creation.

class PatientHealthProfile {
  final String patientId;
  final String patientName;
  final int age;
  final String conditionNotes;
  final String affectedBodyPart;
  final String limitations;
  final String previousHistory;
  final String currentSymptoms;
  final String clinicianNotes;
  final String assessmentNotes;
  final DateTime updatedAt;

  const PatientHealthProfile({
    required this.patientId,
    required this.patientName,
    required this.age,
    required this.conditionNotes,
    required this.affectedBodyPart,
    required this.limitations,
    required this.previousHistory,
    required this.currentSymptoms,
    required this.clinicianNotes,
    this.assessmentNotes = '',
    required this.updatedAt,
  });

  PatientHealthProfile copyWith({
    String? patientName,
    int? age,
    String? conditionNotes,
    String? affectedBodyPart,
    String? limitations,
    String? previousHistory,
    String? currentSymptoms,
    String? clinicianNotes,
    String? assessmentNotes,
    DateTime? updatedAt,
  }) {
    return PatientHealthProfile(
      patientId: patientId,
      patientName: patientName ?? this.patientName,
      age: age ?? this.age,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      affectedBodyPart: affectedBodyPart ?? this.affectedBodyPart,
      limitations: limitations ?? this.limitations,
      previousHistory: previousHistory ?? this.previousHistory,
      currentSymptoms: currentSymptoms ?? this.currentSymptoms,
      clinicianNotes: clinicianNotes ?? this.clinicianNotes,
      assessmentNotes: assessmentNotes ?? this.assessmentNotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'patientName': patientName,
        'age': age,
        'conditionNotes': conditionNotes,
        'affectedBodyPart': affectedBodyPart,
        'limitations': limitations,
        'previousHistory': previousHistory,
        'currentSymptoms': currentSymptoms,
        'clinicianNotes': clinicianNotes,
        'assessmentNotes': assessmentNotes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PatientHealthProfile.fromJson(Map<String, dynamic> json) =>
      PatientHealthProfile(
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String,
        age: json['age'] as int? ?? 30,
        conditionNotes: json['conditionNotes'] as String? ?? '',
        affectedBodyPart: json['affectedBodyPart'] as String? ?? '',
        limitations: json['limitations'] as String? ?? '',
        previousHistory: json['previousHistory'] as String? ?? '',
        currentSymptoms: json['currentSymptoms'] as String? ?? '',
        clinicianNotes: json['clinicianNotes'] as String? ?? '',
        assessmentNotes: json['assessmentNotes'] as String? ?? '',
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );
}
