<!-- refreshed: 2026-09-17 -->
# Architecture

**Analysis Date:** 2026-09-17

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                        Presentation Layer (UI)                          │
├──────────────────────────┬──────────────────────────┬───────────────────┤
│    Auth / Role Gate      │    Doctor Portal HUD     │ Patient Portal HUD│
│ `lib/auth/login_screen`  │  `lib/doctor/dashboard`  │`lib/patient/dash` │
│                          │  `lib/doctor/plans`      │`lib/patient/live` │
│                          │  `lib/doctor/session_rev`│`lib/patient/res`  │
└────────────┬─────────────┴────────────┬─────────────┴─────────┬─────────┘
             │                          │                       │
             ▼                          ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Application & State Services                         │
├─────────────────────────────────────────┬───────────────────────────────┤
│             AuthService                 │       FirestoreService        │
│    `lib/services/auth/auth_service`     │`lib/services/firestore/`      │
│  (Session restore & role management)    │ (In-memory reactive store)    │
└────────────────────┬────────────────────┴───────────────┬───────────────┘
                     │                                    │
                     ▼                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                 AI & Biomechanical Intelligence Pipeline                │
├───────────────────┬───────────────────┬───────────────────┬─────────────┤
│  ExerciseEngine   │ JointAngleEngine  │ ReferenceAnalyzer │Summary Gen  │
│`lib/ai/engine/`   │ `lib/ai/angles/`  │ `lib/ai/ref/`     │`lib/ai/sum/`│
│(Frame coordinator)│(3D vector math)   │(Peak/ROM extract) │(Deterministic)
├───────────────────┼───────────────────┼───────────────────┼─────────────┤
│  BicepRepEngine   │ShoulderHoldEngine │ VisibilityTracker │FeedbackEng  │
│ `lib/ai/reps/`    │ `lib/ai/holds/`   │ `lib/ai/vis/`     │`lib/ai/feed`│
└────────────┬──────┴───────────┬───────┴───────────┬───────┴─────────────┘
             │                  │                   │
             ▼                  ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Hardware & Platform Integration                      │
├───────────────────────────────┬─────────────────────────────────────────┤
│       Google ML Kit Pose      │           Camera & Video Player         │
│`lib/services/camera/pose_det` │   `camera: ^0.12.1`, `video_player`     │
│(33 landmark pose estimation)  │   (NV21 camera stream, offline player)  │
└───────────────────────────────┴─────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `ExerciseEngine` | Coordinates per-frame biomechanical validation, state transitions, rep/hold counters, and telemetry event logging | `lib/ai/engine/exercise_engine.dart` |
| `JointAngleEngine` | Pure 3D vector math computing joint interior angles via dot products of 3-landmark triplets | `lib/ai/angles/joint_angle_engine.dart` |
| `ReferenceAnalyzer` | Extracts target angle, ROM tolerance, and confidence from clinician reference recordings using median filtering and peak detection | `lib/ai/reference/reference_analyzer.dart` |
| `SessionSummaryGenerator` | Deterministically compiles clinical session metrics, accuracy %, and clinician review suggestions strictly from recorded events | `lib/ai/summary/session_summary_generator.dart` |
| `BicepRepEngine` | State machine tracking concentric flexion, hold apex, eccentric extension, and rep counting | `lib/ai/reps/bicep_rep_engine.dart` |
| `ShoulderHoldEngine` | Accumulates valid hold seconds, pauses during posture breaks, and tracks recovery events | `lib/ai/holds/shoulder_hold_engine.dart` |
| `VisibilityTracker` | Hysteresis filter (fail=5, pass=3) preventing premature error penalization during temporary landmark dropouts | `lib/ai/visibility/visibility_tracker.dart` |
| `FeedbackEngine` | Generates concise, directional patient feedback prompts based on current joint angle, target, and issue codes | `lib/ai/feedback/feedback_engine.dart` |
| `PoseDetectorService` | Wraps Google ML Kit Pose Detection, drops queued frames to prevent buffer bloat, and maps `PoseLandmark` to immutable domain landmarks | `lib/services/camera/pose_detector_service.dart` |
| `AuthService` | Manages login state, persists active role and patient ID to `SharedPreferences`, restores sessions on startup | `lib/services/auth/auth_service.dart` |
| `FirestoreService` | Reactive state store providing multi-patient roster, clinical health profiles, exercise plans, and session summaries | `lib/services/firestore/firestore_service.dart` |
| `PersonalizedGuidancePainter` | Custom painter rendering landmark skeletons, dynamic angle arcs, target thresholds, and visual boundary corridors | `lib/patient/exercise/personalized_guidance_painter.dart` |

## Pattern Overview

**Overall:** Layered Clean Architecture with Biomechanical State Machine Pipeline and Reactive Provider State Management.

**Key Characteristics:**
- **Deterministic Biomechanics:** Joint kinematics, ROM bounds, and rep phases use pure mathematical calculations (no black-box or non-deterministic LLM calls in the real-time frame loop).
- **Unidirectional Data Flow:** Camera hardware frames flow strictly down through ML Kit, landmark extraction, joint vector math, exercise state machine, and into UI painters and event logs.
- **Role Separation:** Strict boundary between Patient UI (real-time HUD, visual cues, rehabilitation tasks) and Doctor UI (health profiles, plan creation with video assignment, session telemetry review).
- **Graceful Degradation:** Production builds require real camera frames and display informative error guidance if unavailable; synthetic simulation is strictly constrained to `kDebugMode`.

## Layers

**Presentation Layer (UI):**
- Purpose: Renders clinician and patient interfaces, interactive camera HUDs, video players, and telemetry dashboards.
- Location: `lib/doctor/`, `lib/patient/`, `lib/auth/`
- Contains: Flutter widgets (`StatefulWidget`, `StatelessWidget`), `CustomPainter` implementations, modal dialogs.
- Depends on: Application services (`AuthService`, `FirestoreService`), models, and AI engine frames.
- Used by: End users (clinicians and patients).

**Application & State Layer:**
- Purpose: Maintains session state, orchestrates authentication, and manages multi-patient plans and historical sessions.
- Location: `lib/services/`
- Contains: `ChangeNotifier` service providers (`AuthService`, `FirestoreService`), camera streaming adapters (`PoseDetectorService`).
- Depends on: Platform plugins (`camera`, `google_mlkit_pose_detection`, `shared_preferences`).
- Used by: Presentation layer widgets via `context.watch<T>()` and `context.read<T>()`.

**AI & Biomechanics Pipeline Layer:**
- Purpose: Extracts spatial landmarks, calculates 3D joint angles, assesses posture compliance, counts repetitions, tracks hold duration, and generates audit reports.
- Location: `lib/ai/`, `lib/exercises/`
- Contains: Pure Dart kinematic engines, rule interfaces (`ExerciseRule`), state machines, and mathematical utilities.
- Depends on: Domain models (`Landmark`, `MovementEvent`, `ReferenceProfile`, `SessionSummary`).
- Used by: Live exercise screens and clinician plan creation screens.

**Domain Models Layer:**
- Purpose: Defines typed immutable contracts for domain entities.
- Location: `lib/models/`
- Contains: Plain Dart classes (`AppUser`, `ExercisePlan`, `SessionRecord`, `PatientHealthProfile`, `ReferenceProfile`, `Landmark`).
- Depends on: Core constants and standard Dart libraries.
- Used by: All layers across the entire application.

## Data Flow

### Primary Request Path (Live Patient Exercise Pipeline)

1. Camera captures NV21 image stream (`lib/patient/exercise/live_exercise_screen.dart:101`).
2. `PoseDetectorService` checks `_isProcessingFrame` flag and drops duplicate frames to prevent latency accumulation (`lib/services/camera/pose_detector_service.dart:24`).
3. Google ML Kit processes the `InputImage` and returns 33 spatial pose landmarks (`lib/services/camera/pose_detector_service.dart:38`).
4. `ExerciseEngine.processFrame` executes visibility checks with `VisibilityTracker` hysteresis filter (`lib/ai/engine/exercise_engine.dart:90`).
5. If visible, `JointAngleEngine.computeAngle` computes the 3D joint angle using the specified landmark triplet (`lib/ai/angles/joint_angle_engine.dart:12`).
6. The exercise rule (`BicepCurlRule` or `ShoulderRaiseRule`) checks angle bounds against the prescribed `ReferenceProfile` (`lib/ai/engine/exercise_engine.dart:162`).
7. `BicepRepEngine` or `ShoulderHoldEngine` updates the movement state machine and records `RepEvent` or `SessionEvent` (`lib/ai/engine/exercise_engine.dart:168`).
8. `PersonalizedGuidancePainter` renders skeleton lines, target arcs, and real-time color-coded feedback to the screen (`lib/patient/exercise/personalized_guidance_painter.dart:1`).
9. When prescribed repetitions or hold durations are met, `SessionSummaryGenerator.generate` deterministically computes final metrics (`lib/ai/summary/session_summary_generator.dart:12`).
10. `FirestoreService.saveSession` persists the session record, updating the clinician review queue (`lib/services/firestore/firestore_service.dart:168`).

### Secondary Flow (Doctor Reference Video Calibration & Plan Assignment)

1. Clinician selects exercise type, target patient, and uploads or assigns demonstration video (`lib/doctor/plans/create_plan_screen.dart:1`).
2. Video frames are analyzed or clinician provides target biomechanical parameters.
3. `ReferenceAnalyzer.analyze` applies moving median smoothing (window size 5) and peak prominence detection to extract the optimal target angle and tolerance (`lib/ai/reference/reference_analyzer.dart:26`).
4. `BiomechanicsBounds` validates physiological plausibility; implausible targets are rejected rather than silently clamped (`lib/ai/reference/reference_analyzer.dart:134`).
5. Clinician confirms or overrides the extracted target angle and tolerance (`lib/doctor/plans/create_plan_screen.dart`).
6. `FirestoreService.savePlan` stores the finalized `ExercisePlan` linked to the chosen `patientId` (`lib/services/firestore/firestore_service.dart:149`).
7. Patient dashboard reactively updates via `FirestoreService` listener and displays the assigned exercise plan and reference video (`lib/patient/dashboard/patient_dashboard.dart`).

**State Management:**
- Root level `MultiProvider` declared in `lib/main.dart:23` supplies `AuthService` and `FirestoreService`.
- UI components consume services via `Provider.of<T>(context)` or extension methods `context.watch<T>()` and `context.read<T>()`.
- Local screen state (such as camera active status, active dialogs, and video player controllers) is managed via standard Flutter `StatefulWidget` states.

## Key Abstractions

**`ExerciseRule` (`lib/exercises/exercise_rule.dart`):**
- Purpose: Abstract interface defining joint definitions, landmark triplets, physiological boundaries, and rep/hold evaluation logic.
- Implementations: `BicepCurlRule` (`lib/exercises/bicep_curl/bicep_curl_rule.dart`), `ShoulderRaiseRule` (`lib/exercises/shoulder_raise/shoulder_raise_rule.dart`).
- Pattern: Strategy Pattern with Template Method.

**`ReferenceProfile` (`lib/models/reference_profile.dart`):**
- Purpose: Encapsulates baseline biomechanical targets (target angle, tolerance band, body side, confidence score, clinician override flags).
- Pattern: Value Object / Data Transfer Object.

**`EngineFrame` (`lib/models/movement_event.dart`):**
- Purpose: Immutable snapshot of single-frame AI evaluation results passed directly to UI painters and telemetry recorders.
- Pattern: Snapshot / Value Object.

## Entry Points

**Application Entry Point:**
- Location: `lib/main.dart:13` (`void main()`)
- Triggers: OS application launch.
- Responsibilities: Calls `WidgetsFlutterBinding.ensureInitialized()`, mounts `MultiProvider`, initializes `AppTheme.darkTheme`, and renders `AuthGate`.

**Role Gate (`AuthGate`):**
- Location: `lib/main.dart:38`
- Triggers: Auth state changes or app start.
- Responsibilities: Renders `LoginScreen` if unauthenticated, `DoctorDashboard` if `currentUser.isDoctor`, or `PatientDashboard` if `currentUser.isPatient`.

## Architectural Constraints

- **Threading:** Flutter Dart single-threaded event loop. Google ML Kit performs heavy C++ inference off the main thread across Android platform channels. Frame dropping (`_isProcessingFrame`) in `PoseDetectorService` prevents queuing delays.
- **Global State:** State is limited to `AuthService` and `FirestoreService` instances managed by `MultiProvider`. No global mutable singletons.
- **Medical Safety Guardrails:** AI never diagnoses pathology or prescribes medical treatments. AI produces observations and clinician review prompts. Clinicians retain full override authority on all plans and targets.
- **Camera Frame Format:** Android frames are received in NV21 format (`ImageFormatGroup.nv21`) and converted to ML Kit `InputImage` using device sensor orientation.

## Anti-Patterns

### Clamping Implausible Biomechanical Angles

**What happens:** Forcing out-of-bounds angles (e.g. 5° or 210° on elbow flexion) into legal ranges with `.clamp()`.
**Why it's wrong:** Silently corrupts data, masks tracking failure, and risks injury if a patient is pushed toward an impossible range.
**Do this instead:** Validate using `BiomechanicsBounds.isTargetPlausible()` and reject implausible targets, triggering a re-recording prompt (`lib/ai/reference/reference_analyzer.dart:134`).

### Using Synthetic Simulation in Production

**What happens:** Generating fake sinusoidal landmark frames when real hardware cameras fail.
**Why it's wrong:** Deceives patients and clinicians with fabricated compliance scores.
**Do this instead:** Restrict synthetic generation strictly to `kDebugMode` and show an explicit camera permission error in release builds (`lib/patient/exercise/live_exercise_screen.dart:134`).

## Error Handling

**Strategy:** Defensive boundary checking with non-crashing fallbacks and clear clinical status indicators.

**Patterns:**
- **Camera Unavailable:** Caught in `_initializeCameraOrSimulation()`, populating user-facing `_cameraErrorMessage` banner.
- **Zero-Length Landmark Vectors:** Detected in `JointAngleEngine.computeAngle` to avoid division by zero and `NaN` propagation.
- **Visibility Loss:** Filtered through `VisibilityTracker` with hysteresis (fail=5 frames) so temporary occlusion does not penalize valid repetition scores.

## Cross-Cutting Concerns

**Logging:** Debug prints guarded by framework conventions; error messages routed through `debugPrint`.
**Validation:** Strict biomechanical boundaries defined in `BiomechanicsBounds` and verified prior to plan saving.
**Authentication:** Role-based access control with session persistence via `SharedPreferences`.

---

*Architecture analysis: 2026-09-17*
