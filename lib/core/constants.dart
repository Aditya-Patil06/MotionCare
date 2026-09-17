// lib/core/constants.dart
// Specification v7 Section 3: Clinical Scope Boundary and Core Constants

class AppConstants {
  static const String appName = 'MotionCare';

  /// Specification v7 Section 3: Mandatory Clinical Scope Boundary Statement
  static const String clinicalScopeBoundaryStatement =
      'This system is an AI-assisted physiotherapy monitoring tool. '
      'It evaluates observed exercise movement against a physiotherapist-provided reference '
      'and does not diagnose medical conditions or independently prescribe, modify, or approve treatment.';

  static const double defaultTolerance = 12.0;
  static const double defaultBicepExtension = 145.0;
}
