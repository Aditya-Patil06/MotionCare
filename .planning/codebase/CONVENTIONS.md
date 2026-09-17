# Coding Conventions

**Analysis Date:** 2026-09-17

## Naming Patterns

**Files:**
- `lower_snake_case.dart` for all source, asset, and test files: `exercise_engine.dart`, `joint_angle_engine.dart`, `live_exercise_screen.dart`.
- Test files mirror the target implementation with `_test.dart`: `fixture_runner_test.dart`, `bicep_rep_engine_test.dart`.

**Classes & Types:**
- `UpperCamelCase` for all classes, abstract classes, mixins, and enums: `ExerciseEngine`, `JointAngleEngine`, `ReferenceProfile`, `AppUser`, `UserRole`.

**Functions & Methods:**
- `lowerCamelCase` with action verbs indicating intent: `processFrame()`, `computeAngle()`, `analyze()`, `signInAsDoctor()`, `savePlan()`.
- Factory or generation methods use descriptive prefixes: `generateSummary()`, `createState()`.

**Variables & Fields:**
- `lowerCamelCase` for local variables and public class members: `currentAngle`, `validReps`, `targetAngle`, `tolerance`.
- Private fields and methods are prefixed with a leading underscore: `_isProcessingFrame`, `_holdEngine`, `_restoreSession()`.
- Constant values use `lowerCamelCase` or `k`-prefixed constants: `_keyRole`, `_keyPatientId`.

**Enums:**
- Enum class names use `UpperCamelCase` and values use `lowerCamelCase`:
  ```dart
  enum UserRole { patient, doctor }
  enum AiState { idle, ready, correct, incorrect, insufficientVisibility }
  enum IssueCode { none, incompleteMovement, overshoot, postureDeviation, insufficientVisibility }
  ```

## Code Style

**Formatting:**
- Official Dart formatter (`dart format`).
- Trailing commas are required on multi-line parameter lists, argument lists, and widget declaration trees to enforce clean diffs and automated indentation.
- Standard 80-character line wrapping guidelines.

**Linting:**
- Configured via `analysis_options.yaml` extending `package:flutter_lints/flutter.yaml`.
- Clean static analysis enforced across all files (0 warnings, 0 errors reported by `flutter analyze`).
- Deprecated member use suppressed at analyzer level where legacy platform channel bindings require:
  ```yaml
  analyzer:
    exclude:
      - build/**
      - android/**
    errors:
      deprecated_member_use: ignore
  ```

## Import Organization

**Order:**
1. Dart core libraries (`dart:async`, `dart:math`, `dart:convert`, `dart:io`, `dart:ui`).
2. Flutter SDK packages (`package:flutter/foundation.dart`, `package:flutter/material.dart`).
3. External third-party packages (`package:camera/camera.dart`, `package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart`, `package:provider/provider.dart`).
4. Internal relative imports traversing upward: `../../models/enums.dart`, `../angles/joint_angle_engine.dart`.

**Path Aliases:**
- Internal project imports use relative paths (`../../`) rather than `package:physio_app/...` within `lib/` to maintain clean submodule boundaries.
- Root test files use `package:physio_app/...` for testing exported APIs.

## Error Handling

**Patterns:**
- **Defensive Guard Clauses:** Early returns on degenerate inputs (empty lists, zero vectors, missing landmarks):
  ```dart
  if (magBA == 0.0 || magBC == 0.0) {
    return 0.0;
  }
  ```
- **Math Boundary Clamping:** Vector products and trigonometric ratios are strictly clamped to avoid domain errors:
  ```dart
  final double cosine = (dot / (magBA * magBC)).clamp(-1.0, 1.0);
  final double angleRadians = math.acos(cosine);
  ```
- **Graceful Async I/O Catching:** Platform I/O operations (camera access, video playback initialization, SharedPreferences reads) are wrapped in `try-catch` blocks with non-fatal user messaging rather than throwing unhandled exceptions.
- **Null Safety:** Strict Dart Sound Null Safety utilized with explicit non-null assertion (`!`) avoided in favor of null-aware operators (`?.`, `??`) or local type promotion.

## Logging

**Framework:**
- Flutter `debugPrint()` is used exclusively throughout services and UI screens.
- Direct `print()` is avoided to conform to `avoid_print` lint rules and prevent logging sensitive biometric telemetry in production Android logcat.

**Patterns:**
- Errors during camera streaming, pose detection, or auth restoration log concise diagnostic strings:
  ```dart
  debugPrint('ML Kit Pose Detection frame error: $e');
  ```

## Comments

**When to Comment:**
- Header comments at top of file identifying domain purpose and clinical specification section:
  ```dart
  // lib/ai/angles/joint_angle_engine.dart
  // Single source of truth for biomechanical joint angle computation.
  // Specification v7 Section 10: Angle = acos(clamp(dot(BA, BC) / (|BA| * |BC|), -1.0, 1.0)) in degrees.
  ```
- Step-by-step numbered comments inside non-trivial algorithms to clarify data transformations:
  ```dart
  // 1. Evaluate Visibility
  // 2. Compute angle
  // 3. Movement correctness & phase
  // 4. Rep or Hold Engine Processing
  ```

**Dart Doc Comments (`///`):**
- Used on public classes and primary kinematic methods explaining parameters, units of measure (e.g. degrees `[0.0, 180.0]`), and edge-case behavior:
  ```dart
  /// Computes the 3D joint angle at vertex [b] between rays [b]->[a] and [b]->[c].
  /// Returns angle in degrees [0.0, 180.0].
  /// Returns 0.0 if either vector has zero length to prevent NaN.
  ```

## Function Design

**Size:**
- Pure mathematical functions remain compact (<50 lines).
- Frame processing methods decompose tasks into specialized sub-engines (`VisibilityTracker`, `RepEngine`, `HoldEngine`).

**Parameters:**
- Named parameters (`required this.xyz` or `{required ...}`) preferred for any method accepting more than two arguments to prevent positional confusion.
- Default arguments provided for optional clinical tolerances:
  ```dart
  ExerciseEngine({
    required this.rule,
    required this.profile,
    this.prescribedReps = 10,
    this.targetHoldSeconds = 60.0,
    VisibilityTracker? visibilityTracker,
  })
  ```

**Return Values:**
- Methods return immutable domain instances (`EngineFrame`, `ReferenceProfile`, `SessionSummary`) or unmodifiable lists (`List.unmodifiable(_sessionEvents)`).

## Module Design

**Exports:**
- No global barrel files (`index.dart`). Every file imports exactly what it needs directly.
- Encapsulation enforced through file-private classes (`_LiveExerciseScreenState`) and private class fields (`_isProcessingFrame`).

---

*Convention analysis: 2026-09-17*
