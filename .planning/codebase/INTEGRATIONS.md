# External Integrations

**Analysis Date:** 2026-09-17

## APIs & External Services

**On-Device Machine Learning:**
- Google ML Kit Pose Detection (`google_mlkit_pose_detection: ^0.13.0`)
  - Purpose: High-speed real-time 33-point skeletal landmark detection from camera frame buffers.
  - SDK/Client: `PoseDetector` from `package:google_mlkit_pose_detection`
  - Auth: None (on-device local inference model run by Google Play Services / embedded native C++ runtime).
  - Key Integration: `lib/services/camera/pose_detector_service.dart` transforms NV21 `CameraImage` frames into `InputImage` and returns mapped `Landmark` models with confidence scores.

**Video Playback & Streaming:**
- Android Media3 / ExoPlayer (`video_player: ^2.9.2`)
  - Purpose: Native hardware-accelerated playback of clinician demonstration MP4 recordings and clinical reference videos.
  - SDK/Client: `VideoPlayerController` (`.file()`, `.asset()`, `.networkUrl()`)
  - Key Integration: `lib/patient/exercise/clinician_video_dialog.dart` displays looped video demonstrations alongside target biomechanical angles and clinical pacing cues.

**Camera Hardware Subsystem:**
- Android Camera2 API (`camera: ^0.11.0+2`)
  - Purpose: Video capture and live image streaming at medium resolution without audio recording overhead.
  - Key Integration: `lib/patient/exercise/live_exercise_screen.dart` streams live frames to the pose detection engine and renders custom skeletal overlay on top of `CameraPreview`.

## Data Storage

**Databases:**
- Cloud Firestore (Schema defined; active in-memory provider implementation)
  - Schema: Root-level security rules configured in `firestore.rules`.
  - Collections: `health_profiles`, `exercise_plans`, `session_records`, `users`.
  - Client: `FirestoreService` (`lib/services/firestore/firestore_service.dart`), implementing reactive in-memory document state with multi-patient rosters (`pat_alex_rivera`, `pat_maya_lin`, `pat_david_kim`), real-time `ChangeNotifier` updates, and serialization matching Cloud Firestore REST/SDK formats.

**File Storage:**
- Android Internal Storage / App Cache (`/data/user/0/.../cache/`)
  - Purpose: Storing clinician-recorded reference video demonstrations (`.mp4`) captured via `image_picker`.
  - Fallback: Pre-loaded offline asset bundle (`assets/demo/reference_bicep_curl.mp4`).

**Caching:**
- `SharedPreferences` (`shared_preferences: ^2.3.2`)
  - Purpose: Persisting active user authentication role (`auth_active_role`), patient account identifier (`auth_active_patient_id`), and patient name (`auth_active_patient_name`) across application restarts.

## Authentication & Identity

**Auth Provider:**
- Role-Based Authentication System (`lib/services/auth/auth_service.dart`)
  - Implementation: Provider-based state management supporting distinct Clinician (`UserRole.doctor`) and Patient (`UserRole.patient`) roles.
  - Deterministic Demo Accounts:
    - Clinician: `doc_sarah_chen` (`doctor@physio.ai`)
    - Patients: `pat_alex_rivera`, `pat_maya_lin`, `pat_david_kim`
  - Session Persistence: Stored via `SharedPreferences`, restored automatically on cold application start.
  - Navigation Guard: Explicit logout required to switch roles; inline accidental profile-switching controls strictly prevented.

## Monitoring & Observability

**Error Tracking:**
- Local Flutter framework error handling (`FlutterError.onError`, `debugPrint`).
- Biomechanical error classification (`lib/models/enums.dart`: `IssueCode` covering `incompleteMovement`, `overshoot`, `postureBreak`, `insufficientVisibility`, `generalFormBreak`).

**AI Session Summaries:**
- In-app deterministic clinical summary generator (`lib/ai/summary/session_summary_generator.dart`) producing objective rep accuracy, posture pause durations, and clinician review recommendations.

## CI/CD & Deployment

**Hosting & Distribution:**
- Android Debug APK output: `build/app/outputs/flutter-apk/app-debug.apk`.
- ADB deployment target: Physical Android devices (e.g. Redmi 13 `f2f916d5`) via `adb install -r`.

## Environment Configuration

**Required Permissions (`android/app/src/main/AndroidManifest.xml`):**
- `android.permission.CAMERA` (Required for real-time pose tracking and video recording)
- `android.permission.READ_MEDIA_VIDEO` / `READ_EXTERNAL_STORAGE` (For attaching demonstration videos)
- `android.permission.INTERNET` (For network reference video fallback and future Cloud Firestore sync)
- `RECORD_AUDIO` permission deliberately excluded (respects zero-bloat/privacy design).

## Webhooks & Callbacks

**Incoming:**
- Hardware camera frame callbacks: `startImageStream((CameraImage image) => ...)` processed on-device.

**Outgoing:**
- Reactive state dispatch: `notifyListeners()` on `AuthService` and `FirestoreService`.

---

*Integration audit: 2026-09-17*
