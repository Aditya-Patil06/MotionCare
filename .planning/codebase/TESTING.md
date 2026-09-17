# Testing Patterns

**Analysis Date:** 2026-09-17

## Test Framework

**Runner:**
- Flutter Test Runner (`flutter_test` SDK)
- Config: Configured natively via `pubspec.yaml` and `analysis_options.yaml`

**Assertion Library:**
- `package:flutter_test/flutter_test.dart` matchers (`expect`, `equals`, `closeTo`, `greaterThanOrEqualTo`, `lessThanOrEqualTo`, `isTrue`, `isFalse`, `findsOneWidget`, `findsNothing`)

**Run Commands:**
```bash
flutter test                                   # Run all automated tests (unit, fixture, widget)
flutter test test/ai/fixture_runner_test.dart  # Run kinematic fixture test suite
flutter test --coverage                        # Run tests and generate LCOV coverage report
```

## Test File Organization

**Location:**
- Dedicated `test/` directory separated from `lib/` source code.

**Naming:**
- Every test file is named after the unit or component under test with a `_test.dart` suffix: `bicep_rep_engine_test.dart`, `joint_angle_test.dart`, `visibility_tracker_test.dart`.

**Structure:**
```text
test/
├── ai/
│   ├── bicep_rep_engine_test.dart           # Concentric/eccentric rep transitions
│   ├── fixture_runner_test.dart             # Golden replay harness for JSON fixtures
│   ├── joint_angle_test.dart                # Vector angle math & edge cases
│   ├── reference_analyzer_test.dart         # Peak detection & plausibility validation
│   ├── session_summary_generator_test.dart  # Clinical metrics & deterministic text
│   ├── shoulder_hold_engine_test.dart       # Hold duration accumulation & recovery
│   └── visibility_tracker_test.dart         # Hysteresis state machine tests
├── fixtures/
│   ├── curl_correct_3reps.json              # 3 clean reps with full extension
│   ├── curl_incomplete.json                 # Incomplete rep ROM failure
│   ├── curl_noisy_short.json                # Low confidence / noisy signal
│   ├── curl_overshoot.json                  # Excessive flexion overshoot
│   ├── curl_reference_doctor.json           # Ideal clinical reference recording
│   ├── curl_visibility_loss.json            # Transient landmark occlusion
│   ├── hold_correct_pause_resume.json       # Pause on posture break, resume on fix
│   └── session_summary_mixed_events.json    # Mixed error distribution summary
├── services/
│   └── auth_service_test.dart               # Role switching & session persistence
├── patient_assignment_video_test.dart       # Multi-patient video assignment flow
└── widget_test.dart                         # Top-level widget tree smoke tests
```

## Test Structure

**Suite Organization:**
```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/ai/angles/joint_angle_engine.dart';
import 'package:physio_app/models/landmark.dart';

void main() {
  group('JointAngleEngine', () {
    test('computes orthogonal 90 degree angle correctly', () {
      final a = Landmark(x: 0.0, y: 1.0, z: 0.0);
      final b = Landmark(x: 0.0, y: 0.0, z: 0.0);
      final c = Landmark(x: 1.0, y: 0.0, z: 0.0);

      final angle = JointAngleEngine.computeAngle(a, b, c);

      expect(angle, closeTo(90.0, 0.001));
    });

    test('returns 0.0 for degenerate zero-length vectors without crashing', () {
      final a = Landmark(x: 0.0, y: 0.0, z: 0.0);
      final b = Landmark(x: 0.0, y: 0.0, z: 0.0);
      final c = Landmark(x: 1.0, y: 0.0, z: 0.0);

      final angle = JointAngleEngine.computeAngle(a, b, c);

      expect(angle, equals(0.0));
    });
  });
}
```

**Patterns:**
- **Setup Pattern:** Pure mathematical engines are instantiated per-test without static leakage.
- **Fixture Replay Pattern:** Telemetry fixtures are read synchronously from `test/fixtures/`, parsed with `jsonDecode`, and replayed frame-by-frame through `rule.repEngine.processSample()`.
- **Assertion Pattern:** Kinematic angles use `closeTo(expected, tolerance)` to accommodate floating-point rounding.

## Mocking

**Framework:**
- Minimalist in-memory state objects and Flutter test platform channels. Heavy third-party mock frameworks (e.g. Mockito) are avoided.

**Patterns:**
```dart
// Mocking SharedPreferences for isolated session testing
setUp(() {
  SharedPreferences.setMockInitialValues({});
});
```

**What to Mock:**
- Hardware device services: Camera hardware stream, ML Kit native platform channels, and local disk cache (`SharedPreferences.setMockInitialValues()`).
- Video player platform controllers when testing widget trees.

**What NOT to Mock:**
- Kinematic calculations: `JointAngleEngine`, `ReferenceAnalyzer`, `BicepRepEngine`, `ShoulderHoldEngine`, and `SessionSummaryGenerator` are never mocked; tests run against real implementations.
- `FirestoreService`: The in-memory reactive repository is used directly in integration tests.

## Fixtures and Factories

**Test Data Structure (`test/fixtures/*.json`):**
```json
{
  "exerciseId": "bicep_curl",
  "targetAngle": 45.0,
  "tolerance": 10.0,
  "frames": [
    { "timestampMs": 0, "angle": 160.0, "visibility": true },
    { "timestampMs": 100, "angle": 120.0, "visibility": true },
    { "timestampMs": 200, "angle": 44.0, "visibility": true }
  ],
  "expected": {
    "validReps": 1,
    "invalidAttempts": 0,
    "finalPhase": "extended"
  }
}
```

**Location:**
- Located in `test/fixtures/`. Loaded via `File('test/fixtures/<name>.json').readAsStringSync()`.

## Coverage

**Requirements:**
- Core AI kinematics, angle calculations, rep engines, and summary generators require 100% test coverage across all branches and edge cases.
- Overall repository test suite passes with 40/40 tests green and 0 analyzer issues.

**View Coverage:**
```bash
flutter test --coverage
# HTML report can be generated via:
# genhtml coverage/lcov.info -o coverage/html
```

## Test Types

**Unit Tests:**
- Scope: `JointAngleEngine`, `BicepRepEngine`, `ShoulderHoldEngine`, `VisibilityTracker`, `ReferenceAnalyzer`, `SessionSummaryGenerator`.
- Approach: Verifies pure logic, zero-vector edge cases, phase transitions, and deterministic summary calculations.

**Fixture Replay Tests:**
- Scope: `test/ai/fixture_runner_test.dart`.
- Approach: Replays actual temporal patient exercise sequences (valid reps, incomplete attempts, overshoot, visibility dropout) to guarantee regression protection.

**Widget Integration Tests:**
- Scope: `test/widget_test.dart`, `test/patient_assignment_video_test.dart`.
- Approach: Mounts the Flutter widget tree using `WidgetTester`, verifies role selection, patient dashboard rendering, clinician video modal presentation, and multi-patient roster switching.

**E2E Tests on Physical Devices:**
- Verified directly via ADB on connected hardware (e.g. Redmi 13 Android 14) to validate camera initialization and real-time ML Kit frame rate.

## Common Patterns

**Async Testing:**
```dart
testWidgets('Assigns exercise plan and verifies video reception', (tester) async {
  final firestoreService = FirestoreService();
  final authService = AuthService();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: firestoreService),
      ],
      child: const MaterialApp(home: DoctorDashboard()),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Dr. Sarah Chen, PT, DPT'), findsOneWidget);
});
```

**Error Testing:**
```dart
test('low visibility frames trigger low confidence and review prompt', () {
  final analyzer = const ReferenceAnalyzer(
    bounds: BiomechanicsBounds(
      minPlausibleAngle: 20.0,
      maxPlausibleAngle: 180.0,
      targetMinAngle: 25.0,
      targetMaxAngle: 110.0,
    ),
  );

  final profile = analyzer.analyze(samples: [], exerciseId: 'bicep_curl');

  expect(profile.confidence, equals(0.0));
  expect(profile.isPlausible, isFalse);
  expect(profile.reviewPrompt, contains('Re-recording required'));
});
```

---

*Testing analysis: 2026-09-17*
