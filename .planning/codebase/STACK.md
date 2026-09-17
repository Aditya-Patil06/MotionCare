# Technology Stack

**Analysis Date:** 2026-09-17

## Languages

**Primary:**
- Dart 3.10+ (`>=3.0.0 <4.0.0`) - Application logic, state management, UI, mathematical joint vector calculations (`lib/`, `test/`)

**Secondary:**
- Kotlin 1.9+ (`JVM 17`) - Android embedding, MainActivity, Gradle build scripts (`android/app/build.gradle.kts`)
- XML - Android manifests, layout themes, camera and storage permissions (`android/app/src/main/AndroidManifest.xml`)

## Runtime

**Environment:**
- Flutter 3.x Engine / Dart VM (debug/profile/release JIT and AOT runtimes)
- Android SDK 34 (Android 14) target, minSdk 21 (Android 5.0 Lollipop)
- Target Hardware: ARM64-v8a, armeabi-v7a (e.g. Redmi 13 Android phone)

**Package Manager:**
- Flutter Pub (`pubspec.yaml`, `pubspec.lock`)
- Lockfile: Present (`pubspec.lock` fully locked and reproducible)

## Frameworks

**Core:**
- Flutter SDK (Material 3 Design System) - Cross-platform UI layout, reactive widget tree, animations, custom canvas painting (`PersonalizedGuidancePainter`)

**State Management & Architecture:**
- Provider (`provider: ^6.1.2`) - Scoped dependency injection and reactive state notification (`AuthService`, `FirestoreService`)

**Testing:**
- Flutter Test (`package:flutter_test`) - Unit tests, fixture test runner, widget tests (`test/`)
- Mockito & Checks compatible

**Build/Dev:**
- Gradle 8.x with Kotlin DSL (`android/build.gradle.kts`, `android/app/build.gradle.kts`)
- Flutter Tools (`flutter build apk --debug`, `flutter analyze`, `flutter test`)

## Key Dependencies

**Critical:**
- `google_mlkit_pose_detection: ^0.13.0` - On-device ML vision pipeline extracting 33 full-body anatomical landmark coordinates (x, y, z, visibility, presence) at real-time video framerates.
- `camera: ^0.11.0+2` - Hardware camera sensor access, front/rear camera selection, NV21 raw preview image stream ingestion (`lib/services/camera/pose_detector_service.dart`).
- `video_player: ^2.9.2` - Android Media3 ExoPlayer integration for playing doctor video demonstrations and clinical reference videos (`lib/patient/exercise/clinician_video_dialog.dart`).

**Infrastructure & Utilities:**
- `shared_preferences: ^2.3.2` - Persistent key-value storage for offline auth role and patient ID session restoration (`lib/services/auth/auth_service.dart`).
- `image_picker: ^1.1.2` - Clinician video recording and file attachment from camera/gallery (`lib/doctor/plans/create_plan_screen.dart`).
- `collection: ^1.19.0` - Functional collection utilities and iterable extensions.

## Configuration

**Environment:**
- Clinical Scope Boundary configuration in `lib/core/constants.dart`.
- App theme, color tokens, and AI state indicators in `lib/core/theme.dart`.

**Build:**
- `pubspec.yaml`: Dependencies, SDK constraints, asset bundling (`assets/demo/`).
- `analysis_options.yaml`: Static analysis rules (`flutter_lints: ^6.0.0`).
- `android/app/build.gradle.kts`: Application ID (`com.antigravity.physio.physio_app`), SDK compile versions, signing configs.

## Platform Requirements

**Development:**
- Flutter SDK 3.x, Dart 3.x
- Android SDK Build-Tools 34, Android Platform Tools (adb)
- Java / JDK 17

**Production:**
- Android 5.0+ (API 21+) physical device with front-facing camera.
- Connected testing hardware: Redmi 13 (`f2f916d5`) running Android.

---

*Stack analysis: 2026-09-17*
