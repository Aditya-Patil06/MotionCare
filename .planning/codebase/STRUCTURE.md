# Codebase Structure

**Analysis Date:** 2026-09-17

## Directory Layout

```text
physio_app/
├── .planning/
│   └── codebase/                        # GSD codebase mapping documents
├── android/                             # Android native host project (Kotlin/Gradle)
│   ├── app/
│   │   ├── build.gradle                 # Android build config & dependencies
│   │   └── src/main/
│   │       └── AndroidManifest.xml      # Camera permissions & application metadata
│   └── build.gradle                     # Top-level Gradle configuration
├── assets/
│   └── demo/
│       └── reference_bicep_curl.mp4     # Offline reference demo video asset
├── lib/
│   ├── ai/                              # Core AI & biomechanical calculation pipelines
│   │   ├── angles/                      # 3D vector joint angle computation
│   │   ├── engine/                      # Central pipeline coordinator & frame dispatcher
│   │   ├── feedback/                    # Directional verbal feedback generation
│   │   ├── holds/                       # Isometric hold duration and stability tracking
│   │   ├── reference/                   # Clinician reference extraction & smoothing
│   │   ├── reps/                        # Repetition counter state machine
│   │   ├── summary/                     # Deterministic session summary generator
│   │   └── visibility/                  # Landmark visibility tracking & hysteresis
│   ├── auth/                            # Authentication screens & login UI
│   ├── core/                            # App-wide themes, styling, and constants
│   ├── doctor/                          # Clinician portal UI and workflows
│   │   ├── dashboard/                   # Doctor home dashboard & patient roster selector
│   │   ├── health_profile/              # Patient health profile viewer/editor
│   │   ├── plans/                       # Exercise prescription & video assignment screen
│   │   └── session_review/              # Historical session telemetry review screen
│   ├── exercises/                       # Exercise rule implementations & boundaries
│   │   ├── bicep_curl/                  # Bicep curl joint definition & rep rule
│   │   └── shoulder_raise/              # Shoulder raise joint definition & hold rule
│   ├── models/                          # Immutable domain models, DTOs, and enums
│   ├── patient/                         # Patient portal UI, exercise HUD, and results
│   │   ├── calibration/                 # Calibration setup screens
│   │   ├── dashboard/                   # Patient home dashboard & plan list
│   │   ├── exercise/                    # Live HUD, guidance painter, clinician video modal
│   │   └── results/                     # Post-exercise session report screen
│   ├── services/                        # App state providers and hardware interfaces
│   │   ├── auth/                        # Session restore and user authentication
│   │   ├── camera/                      # Camera stream adapter and ML Kit pose detector
│   │   └── firestore/                   # Multi-patient reactive state repository
│   └── main.dart                        # Application bootstrap and root AuthGate
├── test/
│   ├── ai/                              # Biomechanical AI engine unit tests
│   ├── fixtures/                        # JSON ground-truth kinematic test vectors
│   ├── services/                        # Auth & state service unit tests
│   ├── patient_assignment_video_test.dart # Multi-patient video prescription tests
│   └── widget_test.dart                 # Top-level widget mounting tests
├── analysis_options.yaml                # Dart static analyzer & flutter_lints config
├── pubspec.yaml                         # Dependencies, asset registrations, and metadata
└── README.md                            # High-level project documentation
```

## Directory Purposes

**`lib/ai/`:**
- Purpose: Pure biomechanical and computer vision computation, free of UI dependencies.
- Contains: Mathematical engines, state machines, hysteresis trackers, and summary generators.
- Key files: `lib/ai/engine/exercise_engine.dart`, `lib/ai/angles/joint_angle_engine.dart`, `lib/ai/reference/reference_analyzer.dart`, `lib/ai/summary/session_summary_generator.dart`.

**`lib/exercises/`:**
- Purpose: Domain definitions of physical exercises, landmark triplets, and physiological constraints.
- Contains: Subclasses of `ExerciseRule` defining joint triplets, ROM limits, and rep/hold evaluation.
- Key files: `lib/exercises/exercise_rule.dart`, `lib/exercises/bicep_curl/bicep_curl_rule.dart`, `lib/exercises/shoulder_raise/shoulder_raise_rule.dart`.

**`lib/models/`:**
- Purpose: Central domain contracts and data models used across all layers.
- Contains: Plain Dart classes, value objects, and enums.
- Key files: `lib/models/enums.dart`, `lib/models/landmark.dart`, `lib/models/movement_event.dart`, `lib/models/plan.dart`, `lib/models/patient_health_profile.dart`, `lib/models/session.dart`, `lib/models/user.dart`.

**`lib/services/`:**
- Purpose: Application infrastructure, device hardware communication, and reactive state stores.
- Contains: `ChangeNotifier` classes, ML Kit adapters, and `SharedPreferences` session managers.
- Key files: `lib/services/auth/auth_service.dart`, `lib/services/firestore/firestore_service.dart`, `lib/services/camera/pose_detector_service.dart`.

**`lib/doctor/`:**
- Purpose: Clinical provider dashboard, health profile auditing, exercise plan creation, and telemetry analytics.
- Contains: Stateful and Stateless Flutter screens and widgets for doctors.
- Key files: `lib/doctor/dashboard/doctor_dashboard.dart`, `lib/doctor/plans/create_plan_screen.dart`, `lib/doctor/health_profile/patient_health_profile_screen.dart`, `lib/doctor/session_review/session_review_screen.dart`.

**`lib/patient/`:**
- Purpose: Patient-facing rehabilitation experience, real-time exercise HUD, and progress reporting.
- Contains: Live camera preview HUD, `CustomPainter` skeleton renderers, and clinician video player dialogs.
- Key files: `lib/patient/dashboard/patient_dashboard.dart`, `lib/patient/exercise/live_exercise_screen.dart`, `lib/patient/exercise/clinician_video_dialog.dart`, `lib/patient/exercise/personalized_guidance_painter.dart`, `lib/patient/results/session_result_screen.dart`.

**`lib/core/`:**
- Purpose: Common themes, color palettes, and global constants.
- Key files: `lib/core/theme.dart`, `lib/core/constants.dart`.

**`test/`:**
- Purpose: Automated test verification including unit, widget, and fixture-driven kinematics suites.
- Key files: `test/ai/fixture_runner_test.dart`, `test/patient_assignment_video_test.dart`, `test/widget_test.dart`.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Root entrypoint, initializes binding, mounts `MultiProvider`, sets `AppTheme.darkTheme`, routes through `AuthGate`.
- `lib/auth/login_screen.dart`: Authentication entry point with tabs for Patient and Doctor logins.

**Configuration:**
- `pubspec.yaml`: Package dependencies, environment bounds (`sdk: ^3.13.3`), and demo video assets.
- `analysis_options.yaml`: Linting configuration (`package:flutter_lints/flutter.yaml`).
- `android/app/src/main/AndroidManifest.xml`: Android runtime permissions (`CAMERA`).

**Core Logic:**
- `lib/ai/engine/exercise_engine.dart`: Central frame processing pipeline.
- `lib/ai/angles/joint_angle_engine.dart`: 3D vector cosine math for joint angles.
- `lib/ai/reference/reference_analyzer.dart`: Reference video kinematic extraction and plausibility filtering.
- `lib/ai/summary/session_summary_generator.dart`: Deterministic clinical summary generator.

**Testing:**
- `test/ai/fixture_runner_test.dart`: Replays recorded telemetry JSON fixtures against the AI kinematic engine.
- `test/patient_assignment_video_test.dart`: End-to-end multi-patient assignment and video playback widget tests.

## Naming Conventions

**Files:**
- Snake case for all Dart files: `exercise_engine.dart`, `live_exercise_screen.dart`, `clinician_video_dialog.dart`.
- Test files mirror implementation with `_test.dart` suffix: `bicep_rep_engine_test.dart`, `visibility_tracker_test.dart`.

**Directories:**
- Snake case or single words: `ai/`, `angles/`, `health_profile/`, `session_review/`.

**Classes & Types:**
- PascalCase for classes and enums: `ExerciseEngine`, `JointAngleEngine`, `UserRole`, `IssueCode`.

**Variables & Functions:**
- camelCase for identifiers and functions: `processFrame()`, `computeAngle()`, `validReps`.
- Private fields and helpers prefixed with underscore: `_isProcessingFrame`, `_restoreSession()`.

## Where to Add New Code

**New Exercise Type (e.g. Squat or Knee Extension):**
1. Define rule: Create `lib/exercises/squat/squat_rule.dart` extending `ExerciseRule`.
2. Define joint definition: Specify primary joint triplets (e.g., hip, knee, ankle) and physiological bounds.
3. If new movement pattern: Add rep or hold engine in `lib/ai/reps/` or `lib/ai/holds/`.
4. Register in UI: Add exercise type option in `lib/doctor/plans/create_plan_screen.dart` and `lib/patient/exercise/live_exercise_screen.dart`.
5. Unit tests: Create `test/ai/squat_rule_test.dart` and fixture files in `test/fixtures/`.

**New Clinical Feature (e.g. Range of Motion Progress Trend Chart):**
1. UI screen or widget: Add to `lib/doctor/session_review/` or `lib/doctor/analytics/`.
2. Telemetry extraction: Read from `SessionRecord.summary` in `FirestoreService`.
3. Widget tests: Add tests in `test/doctor/`.

**New Shared Utility / Helper:**
1. Mathematical or geometric helpers: Place in `lib/ai/angles/` or `lib/core/`.
2. General UI helpers / dialogs: Place in `lib/core/` or specific feature module.

## Special Directories

**`.planning/`:**
- Purpose: Stores GSD project specifications, roadmap, and codebase mapping documents.
- Generated: No (authored / maintained).
- Committed: Yes.

**`assets/demo/`:**
- Purpose: Bundled offline reference videos (`reference_bicep_curl.mp4`) for clinical demo and offline fallback.
- Generated: No.
- Committed: Yes.

**`test/fixtures/`:**
- Purpose: Golden JSON test fixtures containing frame-by-frame angles and expected state machine outputs.
- Generated: No.
- Committed: Yes.

**`build/`:**
- Purpose: Flutter build output directory (intermediates, compiled APKs, bundle outputs).
- Generated: Yes.
- Committed: No (`.gitignore`).

---

*Structure analysis: 2026-09-17*
