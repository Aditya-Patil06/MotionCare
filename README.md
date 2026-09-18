# MotionCare

> **AI-Powered Physiotherapy Companion — Move • Recover • Live Better**

[![Flutter](https://img.shields.io/badge/Flutter-3.29%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![CI](https://github.com/Aditya-Patil06/MotionCare/actions/workflows/flutter.yml/badge.svg)](https://github.com/Aditya-Patil06/MotionCare/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)]()

MotionCare is a computer-vision-powered mobile physiotherapy companion that bridges the gap between clinical appointments and home rehabilitation. By combining real-time on-device biomechanical pose estimation with clinician-directed exercise calibration and cloud telemetry, MotionCare empowers patients to perform rehabilitation exercises with precision, safety, and confidence.

---

## Table of Contents

- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [Key Features](#key-features)
- [AI & Computer Vision Pipeline](#ai--computer-vision-pipeline)
  - [Hybrid Pipeline Architecture](#hybrid-pipeline-architecture)
  - [Biomechanical Angle Mathematics](#biomechanical-angle-mathematics)
  - [Anti-Flicker Landmark Gatekeeper](#anti-flicker-landmark-gatekeeper)
  - [Clinician Reference Comparison](#clinician-reference-comparison)
  - [Edge / Cloud Fallback Strategy](#edge--cloud-fallback-strategy)
- [Supported Exercises](#supported-exercises)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation & Running](#installation--running)
- [Running Tests & Static Analysis](#running-tests--static-analysis)
- [Continuous Integration](#continuous-integration)
- [Demo Mode & Offline Testing](#demo-mode--offline-testing)
- [Medical & Safety Disclaimer](#medical--safety-disclaimer)
- [Limitations & Roadmap](#limitations--roadmap)

---

## The Problem

Physical therapy and musculoskeletal rehabilitation are critical to post-injury recovery, surgical rehabilitation, and chronic mobility preservation. However, current home rehabilitation models suffer from three systemic failures:

1. **Severe Non-Adherence**: Clinical research demonstrates that **up to 70% of patients fail to complete prescribed home physiotherapy regimens**, driven by confusion, boredom, and lack of accountability.
2. **Improper Form & Secondary Injury**: When exercising alone without real-time visual feedback, patients often utilize incorrect compensation patterns (e.g., lumbar extension during shoulder abduction or trunk swing during bicep flexion), reinforcing suboptimal motor pathways and risking re-injury.
3. **The Clinical Blindspot**: Physical therapists and orthopedic surgeons have zero objective telemetry between scheduled appointments. Patient progress is measured via subjective, retrospective self-reporting rather than verified range-of-motion metrics.

---

## The Solution

**MotionCare** transforms any standard smartphone camera into an intelligent physiotherapy clinic. 

- **For Clinicians**: A comprehensive clinical portal to inspect patient health profiles, record "gold standard" exercise demonstration videos, extract individualized target joint angles and tolerances, and review objective telemetry logs.
- **For Patients**: An intuitive, medical-grade mobile interface providing real-time skeleton tracking, personalized ghost guidance lines, target range sectors, audio-visual form correction cues, and automatic rep/hold counting.

---

## Key Features

- **Dual-Role Experience**:
  - **Clinician Portal**: Manage patient rosters, review historical injury data, record clinical demonstration videos, and configure custom range-of-motion tolerances.
  - **Patient Companion**: Access assigned therapy plans, watch clinician reference videos side-by-side, and execute supervised exercise sessions.
- **Real-Time On-Device Pose Tracking**: Evaluates 33 full-body anatomical landmarks at 30+ frames per second with zero external sensors required.
- **Personalized Visual Guidance HUD**: Dynamic canvas rendering anatomical target sectors, limb trajectory ghost lines, and color-coded feedback (green = compliant, amber = warning, red = incorrect form).
- **Repetition & Isometric Hold State Machines**: Deterministic finite state machines (FSM) validate complete repetitions and track uninterrupted isometric holds while rejecting incomplete or compensatory movements.
- **Clinician Video & Reference Extraction**: Clinician recordings are analyzed on-device to derive baseline target angles and acceptable standard deviations for patient comparison.
- **Factually Grounded Clinical Summaries**: Automatically generates post-session rehabilitation summaries detailing total reps, compliance percentage, range of motion peaks, and compensatory faults.

---

## AI & Computer Vision Pipeline

```
+-------------------------------------------------------------------------+
|                        MOTIONCARE AI PIPELINE                           |
+-------------------------------------------------------------------------+
                                     |
                          [Camera Video Stream]
                                     |
                                     v
                 [Google ML Kit / MediaPipe Pose Estimator]
                 (Extracts 33 3D anatomical body landmarks)
                                     |
                                     v
                        [Visibility Gatekeeper]
              (5-frame hysteresis filter against occlusion)
                                     |
                                     v
                         [Joint Angle Engine]
              (3D vector dot product & cosine calculation)
                                     |
                 +-------------------+-------------------+
                 |                                       |
                 v                                       v
      [Exercise State Engine]             [Personalized Guidance]
    - Flexion / Extension Tracking      - Anatomical Skeleton Overlay
    - Isometric Hold Accumulator        - Target Angular Sector
    - Compensation Detection            - Real-Time Color Feedback
                 |                                       |
                 +-------------------+-------------------+
                                     |
                                     v
                         [Session Telemetry Log]
                                     |
                 +-------------------+-------------------+
                 |                                       |
                 v                                       v
       [Edge Summary Engine]                 [Cloud Intelligence]
   - Reps, Hold Durations, ROM           - Firebase Telemetry Sync
   - Compensation Pattern Analysis       - Gemini Clinical Synthesis
```

### Hybrid Pipeline Architecture

MotionCare utilizes a two-tier hybrid edge/cloud architecture designed for zero-latency execution and clinical fidelity:
- **Tier 1 (Edge Real-Time)**: All frame-by-frame pose extraction, biomechanical angle calculations, rep counting, and visual guidance run entirely on-device using Google ML Kit Pose Detection (MediaPipe BlazePose backend). Processing takes under 25ms per frame, ensuring immediate feedback without streaming sensitive camera feeds to remote servers.
- **Tier 2 (Cloud Clinical Intelligence)**: Aggregated kinematic telemetry events (timestamps, peak joint angles, compensation occurrences) sync to Cloud Firestore, where Google Gemini API models synthesize longitudinal recovery trajectories for clinician review.

### Biomechanical Angle Mathematics

Joint angles are computed in 3D Euclidean space using vector trigonometry across anatomical landmark triplets (e.g., Shoulder $\to$ Elbow $\to$ Wrist for elbow flexion):

Given three landmarks $A = (x_A, y_A, z_A)$, $B = (x_B, y_B, z_B)$ (the vertex), and $C = (x_C, y_C, z_C)$:

1. Construct displacement vectors:
   $$\vec{u} = A - B = (x_A - x_B, y_A - y_B, z_A - z_B)$$
   $$\vec{v} = C - B = (x_C - x_B, y_C - y_B, z_C - z_B)$$

2. Compute the scalar angle using the dot product and vector magnitudes:
   $$\theta = \arccos\left(\frac{\vec{u} \cdot \vec{v}}{\|\vec{u}\| \|\vec{v}\|}\right) \times \frac{180^\circ}{\pi}$$

Calculated angles are clamped and validated against physiological plausibility bounds defined per exercise.

### Anti-Flicker Landmark Gatekeeper

Camera jitter, brief occlusion, or clothing folds can cause single-frame landmark dropouts. MotionCare features a hysteresis-based visibility tracker:
- Requires key tracking landmarks to exceed a minimum likelihood threshold ($p \ge 0.65$).
- Buffers tracking quality over 5 consecutive frames. Occasional single-frame drops do not terminate active repetitions or penalize patient scores, eliminating UI flickering.

### Clinician Reference Comparison

When a clinician records a reference exercise, MotionCare's `ReferenceAnalyzer`:
1. Scans the video stream for landmark trajectories.
2. Identifies inflection points (maximum inflection for flexion exercises, steady hold plateaus for isometric exercises).
3. Computes the baseline target angle ($\theta_{\text{target}}$) and extracts natural human variation to set a personalized tolerance corridor (typically $\pm 10^\circ$ to $\pm 15^\circ$).
4. Compares patient execution directly against this clinician-prescribed profile.

### Edge / Cloud Fallback Strategy

- **Autonomous Edge Operation**: MotionCare does not require active internet access during exercise execution. Pose estimation, guidance rendering, audio-visual feedback, and rep tracking are 100% operational offline.
- **Resilient Cloud Synchronization**: Telemetry is buffered locally using persistent storage and transparently synchronizes with Cloud Firestore when network connectivity is restored.

---

## Supported Exercises

| Exercise | Monitored Joints | Measurement Mode | Form Checks & Compensations |
| :--- | :--- | :--- | :--- |
| **Bicep Curl** | Shoulder $\to$ Elbow $\to$ Wrist | Dynamic Reps (Flexion / Extension) | Incomplete extension, elbow flare, torso swing compensation |
| **Lateral Shoulder Raise** | Hip $\to$ Shoulder $\to$ Elbow | Isometric Hold / Reps | Excessive elevation ($>90^\circ$), neck shrugging, asymmetrical tilt |
| **Knee Extension** | Hip $\to$ Knee $\to$ Ankle | Dynamic Reps & Terminal Hold | Incomplete quadricep extension, pelvic rotation |
| **Squat** | Hip $\to$ Knee $\to$ Ankle & Torso | Dynamic Reps | Valgus knee collapse, excessive forward lean, incomplete depth |

---

## System Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                              FLUTTER UI                                │
│   ┌───────────────────────────┐    ┌────────────────────────────────┐  │
│   │     Clinician Portal      │    │        Patient Portal          │  │
│   │ - Patient Roster & Charts │    │ - Daily Prescription Plan      │  │
│   │ - Reference Video Capture │    │ - Live Exercise Screen         │  │
│   │ - Custom Angle Tolerances │    │ - Telemetry & Recovery Charts  │  │
│   └─────────────┬─────────────┘    └───────────────┬────────────────┘  │
│                 │                                  │                   │
│                 v                                  v                   │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                    Provider State Management                    │  │
│   │           (AuthService, FirestoreService, PlanManager)          │  │
│   └─────────────────────────────┬───────────────────────────────────┘  │
└─────────────────────────────────┼──────────────────────────────────────┘
                                  │
                                  v
┌────────────────────────────────────────────────────────────────────────┐
│                        CORE AI & LOGIC ENGINE                          │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │           Camera Stream & Pose Detector Service                │   │
│   │          (Google ML Kit Pose Detection / MediaPipe)            │   │
│   └─────────────────────────────┬──────────────────────────────────┘   │
│                                 │                                      │
│                                 v                                      │
│   ┌─────────────────────────────┴──────────────────────────────────┐   │
│   │                      AI Subsystems                             │   │
│   │ - JointAngleEngine: 3D vector trigonometric calculations       │   │
│   │ - VisibilityTracker: 5-frame hysteresis gatekeeper             │   │
│   │ - BicepRepEngine / ShoulderHoldEngine: Finite state machines   │   │
│   │ - ReferenceAnalyzer: Inflection extraction from reference video│   │
│   │ - PersonalizedGuidancePainter: Canvas HUD overlay              │   │
│   │ - SessionSummaryGenerator: Grounded clinical report producer   │   │
│   └────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.29+ / Dart 3.13+)
- **Architecture**: Provider-based reactive state management with clean separation of AI, Presentation, and Data layers
- **Computer Vision & On-Device ML**:
  - `google_mlkit_pose_detection` (MediaPipe BlazePose model, 33 3D skeletal landmarks)
  - `camera` (Hardware camera stream handling)
  - `video_player` (Demonstration video replay)
- **Cloud Infrastructure**:
  - `shared_preferences` & Local storage caching
  - Firebase Firestore rules & cloud synchronization schema
  - Google Gemini API integration for clinician summary generation
- **Design System**: Material 3 customized with MotionCare medical seafoam (`#319F78`), slate neutrals, and high-contrast clinical indicators.

---

## Repository Structure

```
motioncare/
├── .github/
│   └── workflows/
│       └── flutter.yml              # Multi-step GitHub Actions CI workflow
├── android/                         # Android native runner & permissions
├── assets/
│   └── demo/                        # Built-in demo fixtures & sample video
├── lib/
│   ├── ai/
│   │   ├── angles/                  # 3D trigonometric joint angle calculations
│   │   ├── engine/                  # Base exercise engine contract
│   │   ├── feedback/                # Real-time visual/audio cue generator
│   │   ├── holds/                   # Isometric hold duration timers
│   │   ├── reference/               # Clinician video landmark analyzer
│   │   ├── reps/                    # Repetition counter finite state machine
│   │   ├── summary/                 # Clinical session summary generator
│   │   └── visibility/              # Hysteresis visibility gatekeeper
│   ├── auth/                        # Login, registration, role switcher
│   ├── core/                        # Global theme, constants, branded widgets
│   ├── doctor/                      # Clinician dashboard, plan builder, recording
│   ├── exercises/                   # Exercise-specific biomechanical rules
│   ├── models/                      # Landmark, Session, Plan, User data models
│   ├── patient/                     # Patient dashboard, live exercise HUD, results
│   ├── services/                    # Auth, Camera stream, Firestore services
│   └── main.dart                    # Application entrypoint (MotionCareApp)
├── test/
│   ├── ai/                          # Engine, math, painter, and summary unit tests
│   ├── doctor/                      # Clinician interface and recording tests
│   ├── fixtures/                    # 8 canonical JSON kinematic test fixtures
│   ├── services/                    # Authentication and data service tests
│   ├── patient_assignment_video_test.dart  # End-to-end clinical assignment test
│   └── widget_test.dart             # Root navigation and login widget test
├── pubspec.yaml                     # Dependencies and asset registrations
└── README.md                        # Documentation
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.29.0 or higher recommended)
- [Dart SDK](https://dart.dev/get-dart) (3.13.3 or higher)
- Android Studio / VS Code with Flutter extensions
- Android device or emulator with Camera support (API level 21+) or iOS device (iOS 12.0+)

### Installation & Running

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Aditya-Patil06/MotionCare.git
   cd MotionCare
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

---

## Running Tests & Static Analysis

MotionCare is built with rigorous test coverage spanning biomechanical math, state machines, and end-to-end user workflows.

### Run All Tests
Execute all 44 unit, widget, and fixture regression tests:
```bash
flutter test
```

### Static Analysis
Run Flutter static analysis to verify code quality:
```bash
flutter analyze
```

### Code Formatting
Ensure strict formatting standards:
```bash
# Check formatting
dart format --output=none --set-exit-if-changed .

# Auto-format files
dart format .
```

---

## Continuous Integration

Continuous Integration is automated via GitHub Actions (`.github/workflows/flutter.yml`). On every push and pull request to the `main` branch, the CI pipeline executes:

1. Environment setup with Flutter stable channel
2. Dependency installation (`flutter pub get`)
3. Code formatting compliance verification (`dart format`)
4. Static analysis and zero-warning verification (`flutter analyze`)
5. Full automated test suite execution (`flutter test`)

---

## Demo Mode & Offline Testing

MotionCare includes preconfigured accounts and simulation modes for instant testing without manual database provisioning:

- **Clinician Login**:
  - Switch to the **Doctor** tab on the login screen.
  - Select the default clinician credentials (`doctor@physio.ai`).
  - Access the patient roster, assign exercise plans, and record reference demonstration videos.
- **Patient Login**:
  - Switch to the **Patient** tab.
  - Choose from test profiles: `Alex Rivera` (Right Bicep Recovery), `Maya Lin` (Rotator Cuff), or `David Kim`.
  - Review assigned doctor videos and launch the live exercise session.
- **Automated Fixture Replay**:
  - Tests in `test/ai/fixture_runner_test.dart` replay 8 pre-recorded landmark fixtures (`curl_correct_3reps.json`, `curl_overshoot.json`, `hold_correct_pause_resume.json`, etc.) without requiring physical camera input.

---

## Medical & Safety Disclaimer

> [!CAUTION]
> **Assistive Tool Notice**: MotionCare is designed as an assistive exercise tracking and biofeedback tool to support prescribed physical therapy. It **does not provide medical diagnosis, prescription, or clinical decision-making** and is not a substitute for professional medical advice, examination, or rehabilitation supervised by a licensed healthcare provider.
>
> Patients should immediately halt exercise and consult their physician or physical therapist if they experience sharp pain, dizziness, numbness, or abnormal discomfort.

---

## Limitations & Roadmap

- [x] On-device 33-landmark 3D pose estimation
- [x] Clinician reference recording and peak angle extraction
- [x] Dynamic rep counting and isometric hold state machines
- [x] Automated clinical session summary generation
- [ ] **Multi-Camera Triangulation**: Dual-angle tracking (frontal + sagittal plane) to detect subtle trunk compensations.
- [ ] **Wearable IMU Sensor Fusion**: Bluetooth integration with Apple Watch / smart bands for muscle activation and velocity tracking.
- [ ] **Automated Range-of-Motion Progression**: AI-driven adaptive plan adjustment based on weekly compliance curves.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
