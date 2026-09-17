# Codebase Concerns

**Analysis Date:** 2026-09-17

## Tech Debt

**In-Memory Firestore Simulation:**
- Issue: `FirestoreService` maintains an in-memory repository (`_healthProfiles`, `_plans`, `_sessions`) mirroring the Cloud Firestore schema, rather than connecting directly to a remote Firebase project.
- Files: `lib/services/firestore/firestore_service.dart`
- Impact: Session history, custom health profiles, and newly created plans do not persist across app process restarts (except authentication state in `SharedPreferences`). Multi-device clinician-to-patient synchronization requires a live backend.
- Fix approach: Initialize Firebase (`firebase_core`) and replace in-memory maps with `FirebaseFirestore.instance.collection('...')` while retaining the current reactive ChangeNotifier interface.

**Local Asset Reference Video Bundling:**
- Issue: Reference demonstration videos (`reference_bicep_curl.mp4`) are bundled directly inside `assets/demo/` within the APK.
- Files: `pubspec.yaml:65`, `lib/services/firestore/firestore_service.dart:85`, `assets/demo/reference_bicep_curl.mp4`
- Impact: Inflates application bundle size (~10-20MB per video). Clinicians cannot dynamically record, upload, and stream new exercise videos to remote patients without local filesystem or cloud bucket integration.
- Fix approach: Implement Cloud Storage (e.g. Firebase Cloud Storage or AWS S3 signed URLs) with video upload from `image_picker` and remote streaming URLs.

## Known Bugs

**OEM Camera Rotation & NV21 Decoding Variations:**
- Symptoms: On certain Android OEMs with non-standard camera sensor orientations or custom camera HALs, camera frames may occasionally report 0 landmarks or rotated coordinate axes.
- Files: `lib/services/camera/pose_detector_service.dart:95-132`
- Trigger: Launching live camera exercise on hardware where `camera.sensorOrientation` does not map to 90/270 degrees.
- Workaround: `PoseDetectorService` defaults to `InputImageRotation.rotation0deg` if unmapped, and `_convertCameraImageToInputImage` falls back gracefully to standard NV21 plane bytes.

## Security Considerations

**Mock Authentication & Role Switching:**
- Risk: Login currently authenticates against pre-seeded clinical user models (`demoDoctor`, `demoPatient`) without remote password hashing or JWT validation. Users can switch roles via the login screen.
- Files: `lib/services/auth/auth_service.dart:22-38`, `lib/auth/login_screen.dart`
- Current mitigation: Designed for offline demonstration, unit testing, and isolated clinical evaluation. Role and patient ID are persisted locally via `SharedPreferences`.
- Recommendations: Implement Firebase Authentication (Email/Password + MFA) and enforce role-based authorization via Firestore Security Rules.

**Biometric & Health Telemetry Privacy (HIPAA / GDPR Compliance):**
- Risk: Patient movement telemetry, range of motion angles, and clinical health notes constitute Protected Health Information (PHI).
- Files: `lib/models/patient_health_profile.dart`, `lib/models/movement_event.dart`, `lib/patient/exercise/live_exercise_screen.dart`
- Current mitigation: Raw camera frames are processed purely on-device in memory and are never saved to disk or broadcast over network streams. Only computed scalar kinematics (angles, rep counts) are logged.
- Recommendations: Ensure end-to-end encryption (E2EE) on all data-at-rest when connecting to cloud persistence.

## Performance Bottlenecks

**On-Device Pose Estimation on Entry-Level Hardware:**
- Problem: Running full-body 33-landmark pose estimation on 30 FPS camera streams can lead to thermal throttling and frame drops on budget mobile chipsets.
- Files: `lib/services/camera/pose_detector_service.dart:24-34`
- Cause: Machine learning inference latency per frame (~30-70ms on CPU/GPU).
- Improvement path: A proactive sequential frame gate (`_isProcessingFrame`) is already implemented to drop incoming frames while previous inference is in progress, maintaining a steady 12-16 FPS throughput without memory leak or UI thread stutter. For further gains, evaluate Dart background isolates or NNAPI GPU delegation.

## Fragile Areas

**Coordinate Space Mapping in `PersonalizedGuidancePainter`:**
- Files: `lib/patient/exercise/personalized_guidance_painter.dart`
- Why fragile: Mapping ML Kit landmark coordinates (scaled to camera image aspect ratio, e.g. 720x1280) to screen pixel coordinates (which vary by device aspect ratio and front-camera mirroring) can produce offset skeleton overlays if screen aspect ratios differ significantly from camera preview ratios.
- Safe modification: Use `FittedBox` or proportional aspect-ratio scaling transforms (`canvas.scale()`) matching the `CameraController.value.aspectRatio`.
- Test coverage: Manually verified on Redmi 13 hardware; lacks automated multi-resolution golden screenshot tests.

## Scaling Limits

**In-Memory Session Lists:**
- Current capacity: Several hundred historical exercise sessions in memory.
- Limit: Device heap allocation (~256MB on low-memory Android).
- Scaling path: Introduce query limits and lazy pagination (`limit(20)`) when migrating to Cloud Firestore.

## Dependencies at Risk

**`google_mlkit_pose_detection` (^0.16.1):**
- Risk: Relies on Google Play Services for on-demand vision model downloads.
- Impact: On Android devices lacking Google Play Services (e.g., AOSP builds, custom ROMs), pose detection will fail unless models are bundled statically in the APK.
- Migration plan: Keep model mode as `PoseDetectionModel.base` or configure Gradle to statically bundle the pose detection model dependencies.

## Missing Critical Features

**In-App Clinician Video Recording:**
- Problem: Clinicians currently assign demonstration videos via local video file picker or pre-bundled demo assets.
- Blocks: Recording custom patient exercise demonstrations directly within the application.
- Fix approach: Integrate `camera` recording mode or `image_picker` camera capture in `CreatePlanScreen`.

**Audio / Voice Feedback Prompts:**
- Problem: Directional feedback messages (e.g. "Curl higher into target range") are presented textually and visually on the HUD.
- Blocks: Patients who cannot continuously watch the screen while exercising (e.g. prone or lateral exercises).
- Fix approach: Integrate `flutter_tts` (Text-to-Speech) for audible coaching cues.

## Test Coverage Gaps

**Widget Golden Snapshot Tests:**
- What's not tested: Visual layout rendering on diverse screen form factors (tablets, foldables).
- Files: `lib/patient/exercise/live_exercise_screen.dart`, `lib/doctor/dashboard/doctor_dashboard.dart`
- Risk: Visual layout overflows on atypical aspect ratios.
- Priority: Low (core biomechanics and business flows have 100% passing test coverage).

---

*Concerns audit: 2026-09-17*
