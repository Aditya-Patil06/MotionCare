// lib/patient/exercise/live_exercise_screen.dart
// Specification v7 Section 18, 19, 31, 32: Live Patient Exercise Monitoring HUD

import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ai/engine/exercise_engine.dart';
import '../../core/theme.dart';
import '../../exercises/bicep_curl/bicep_curl_rule.dart';
import '../../exercises/shoulder_raise/shoulder_raise_rule.dart';
import '../../models/enums.dart';
import '../../models/landmark.dart';
import '../../models/movement_event.dart';
import '../../models/plan.dart';
import '../../models/reference_profile.dart';
import '../../models/session.dart';
import '../../services/camera/pose_detector_service.dart';
import '../../services/firestore/firestore_service.dart';
import '../results/session_result_screen.dart';
import 'clinician_video_dialog.dart';
import 'personalized_guidance_painter.dart';

class LiveExerciseScreen extends StatefulWidget {
  final ExercisePlan plan;

  const LiveExerciseScreen({super.key, required this.plan});

  @override
  State<LiveExerciseScreen> createState() => _LiveExerciseScreenState();
}

class _LiveExerciseScreenState extends State<LiveExerciseScreen> {
  late final ExerciseEngine _engine;
  late final ReferenceProfile _profile;

  CameraController? _cameraController;
  PoseDetectorService? _poseDetectorService;
  bool _isCameraReady = false;
  String? _cameraErrorMessage;

  Timer? _simulationTimer;
  EngineFrame? _latestFrame;
  bool _isSessionActive = true;

  // Interactive controls for testing/demo on emulators or real hardware
  double _manualAngleSlider = 160.0;
  bool _isSimulatedDropoutActive = false;

  @override
  void initState() {
    super.initState();

    _profile = ReferenceProfile(
      exerciseId: widget.plan.exerciseId,
      targetAngle: widget.plan.effectiveTargetAngle,
      tolerance: widget.plan.extractedAngleTolerance,
      confidence: widget.plan.extractionConfidence,
      bodySide: widget.plan.bodySide,
      isClinicianOverride: widget.plan.isClinicianOverridden,
    );

    final rule = widget.plan.exerciseType == ExerciseType.rep
        ? BicepCurlRule(preferredSide: widget.plan.bodySide)
        : ShoulderRaiseRule(
            preferredSide: widget.plan.bodySide,
            targetHoldSeconds: widget.plan.holdDurationSeconds,
          );

    _engine = ExerciseEngine(
      rule: rule,
      profile: _profile,
      prescribedReps: widget.plan.reps,
      targetHoldSeconds: widget.plan.holdDurationSeconds,
    );

    _initializeCameraOrSimulation();
  }

  Future<void> _initializeCameraOrSimulation() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.nv21,
        );

        await _cameraController!.initialize();
        _poseDetectorService = PoseDetectorService();

        _cameraController!.startImageStream((image) async {
          if (!_isSessionActive || _isSimulatedDropoutActive) return;

          final landmarks = await _poseDetectorService!.processCameraImage(
            image,
            frontCamera,
          );

          if (landmarks != null && mounted) {
            _onNewFrame(landmarks);
          }
        });

        setState(() => _isCameraReady = true);
        return;
      } else {
        if (mounted) {
          setState(() {
            _cameraErrorMessage = 'No cameras detected on this device. Please connect a camera to monitor exercise.';
          });
        }
      }
    } catch (e) {
      debugPrint('Live camera stream not available or permission denied: $e');
      if (mounted) {
        setState(() {
          _cameraErrorMessage = 'Camera unavailable or permission denied. Please enable camera permissions in settings.';
        });
      }
    }

    // High-fidelity fallback simulator ONLY in kDebugMode for emulators/dev verification.
    // Antigravity Specification v7 strictly forbids synthetic landmarks in production flows.
    if (kDebugMode && !_isCameraReady) {
      _startInteractiveSimulator();
    }
  }

  void _startInteractiveSimulator() {
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isSessionActive) {
        t.cancel();
        return;
      }

      // Handle visibility dropout simulation
      if (_isSimulatedDropoutActive) {
        _onNewFrame({});
        return;
      }

      // If user is manually moving the slider, use manual slider angle
      final double angle = _manualAngleSlider;

      // Generate synthetic landmarks corresponding to this exact angle
      final landmarks = _generateLandmarksForAngle(angle);
      _onNewFrame(landmarks);
    });
  }

  Map<String, Landmark> _generateLandmarksForAngle(double angleDeg) {
    final prefix = widget.plan.bodySide == BodySide.left ? 'left' : 'right';
    final oppPrefix = widget.plan.bodySide == BodySide.left ? 'right' : 'left';
    final isLeft = widget.plan.bodySide == BodySide.left;

    final double activeShoulderX = isLeft ? 0.40 : 0.60;
    final double oppShoulderX = isLeft ? 0.60 : 0.40;
    const double shoulderY = 0.32;
    const double hipY = 0.68;

    double activeElbowX;
    double activeElbowY;
    double activeWristX;
    double activeWristY;

    final double angleRad = angleDeg * (math.pi / 180.0);

    if (widget.plan.exerciseId == 'shoulder_raise') {
      // Shoulder abduction: arm raises outward from hip
      final double sideDir = isLeft ? -1.0 : 1.0;
      activeElbowX = activeShoulderX + sideDir * 0.22 * math.sin(angleRad);
      activeElbowY = shoulderY + 0.22 * math.cos(angleRad);

      activeWristX = activeShoulderX + sideDir * 0.40 * math.sin(angleRad);
      activeWristY = shoulderY + 0.40 * math.cos(angleRad);
    } else {
      // Bicep curl: elbow fixed below shoulder, forearm flexes upward
      activeElbowX = activeShoulderX;
      activeElbowY = shoulderY + 0.22;

      activeWristX = activeElbowX + (isLeft ? -1.0 : 1.0) * 0.20 * math.sin(math.pi - angleRad);
      activeWristY = activeElbowY + 0.20 * math.cos(math.pi - angleRad);
    }

    return {
      '${prefix}_shoulder': Landmark(x: activeShoulderX, y: shoulderY, likelihood: 0.98),
      '${prefix}_elbow': Landmark(x: activeElbowX, y: activeElbowY, likelihood: 0.95),
      '${prefix}_wrist': Landmark(x: activeWristX, y: activeWristY, likelihood: 0.94),
      '${prefix}_hip': Landmark(x: activeShoulderX, y: hipY, likelihood: 0.92),
      '${oppPrefix}_shoulder': Landmark(x: oppShoulderX, y: shoulderY, likelihood: 0.90),
      '${oppPrefix}_elbow': Landmark(x: oppShoulderX, y: shoulderY + 0.22, likelihood: 0.90),
      '${oppPrefix}_wrist': Landmark(x: oppShoulderX, y: shoulderY + 0.42, likelihood: 0.88),
      '${oppPrefix}_hip': Landmark(x: oppShoulderX, y: hipY, likelihood: 0.90),
    };
  }

  void _onNewFrame(Map<String, Landmark> landmarks) {
    final frame = _engine.processFrame(
      landmarks: landmarks,
      timestamp: DateTime.now(),
    );

    setState(() {
      _latestFrame = frame;
    });

    if (_engine.isFinished) {
      _completeSession();
    }
  }

  void _completeSession() async {
    if (!_isSessionActive) return;
    _isSessionActive = false;
    _simulationTimer?.cancel();
    _cameraController?.stopImageStream();

    final firestore = context.read<FirestoreService>();
    final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';

    final summary = _engine.generateSummary(
      sessionId: sessionId,
      planId: widget.plan.id,
      patientId: widget.plan.patientId,
    );

    final record = SessionRecord(
      id: sessionId,
      planId: widget.plan.id,
      patientId: widget.plan.patientId,
      exerciseId: widget.plan.exerciseId,
      summary: summary,
      events: _engine.sessionEvents,
    );

    await firestore.saveSession(record);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionResultScreen(sessionRecord: record),
        ),
      );
    }
  }

  @override
  void dispose() {
    _isSessionActive = false;
    _simulationTimer?.cancel();
    _cameraController?.dispose();
    _poseDetectorService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _latestFrame;
    final isRep = widget.plan.exerciseType == ExerciseType.rep;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.plan.exerciseName} Live Monitor'),
        actions: [
          if (widget.plan.referenceVideoUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: AppTheme.primaryTeal),
              tooltip: 'Doctor Form Demo',
              onPressed: () => ClinicianVideoDialog.show(context, widget.plan),
            ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.stateIncorrect),
            tooltip: 'End Session',
            onPressed: _completeSession,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Live Camera / Skeleton Viewport
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStateColor(frame?.aiState),
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera feed if initialized
                    if (_isCameraReady && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      Container(
                        color: AppTheme.darkBg,
                        child: _cameraErrorMessage != null && !kDebugMode
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.videocam_off_rounded,
                                          size: 48, color: AppTheme.stateIncorrect),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Camera Unavailable',
                                        style: TextStyle(
                                          color: AppTheme.textLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _cameraErrorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: AppTheme.textMuted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),

                    // Personalized Guidance & Skeleton Overlay (Section 19)
                    if (frame != null)
                      CustomPaint(
                        painter: PersonalizedGuidancePainter(
                          landmarks: frame.landmarks,
                          currentAngle: frame.currentAngle,
                          targetAngle: frame.targetAngle,
                          tolerance: frame.tolerance,
                          aiState: frame.aiState,
                          bodySide: widget.plan.bodySide,
                          exerciseId: widget.plan.exerciseId,
                          previewImageSize: _cameraController?.value.previewSize,
                          isFrontCamera: _isCameraReady && _cameraController != null,
                        ),
                      ),

                    // Directional Feedback Pill (Section 31 & 32)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _getStateColor(frame?.aiState).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(_getStateIcon(frame?.aiState),
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                frame?.feedbackMessage ?? 'Position body in camera view',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // State Badge
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStateColor(frame?.aiState),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStateColor(frame?.aiState),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getStateText(frame?.aiState),
                              style: TextStyle(
                                color: _getStateColor(frame?.aiState),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Metrics & Progression HUD (Section 31 & 32)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Target Angle (Personalized from Clinician Reference)
                      _buildHudCard(
                        title: 'Target Angle',
                        value: '${widget.plan.effectiveTargetAngle.toStringAsFixed(1)}°',
                        subtitle: '±${widget.plan.extractedAngleTolerance.toStringAsFixed(0)}° tolerance',
                        color: AppTheme.primaryTeal,
                      ),
                      // Current Measured Angle
                      _buildHudCard(
                        title: 'Live Angle',
                        value: frame != null && frame.isVisibilityValid
                            ? '${frame.currentAngle.toStringAsFixed(1)}°'
                            : '--',
                        subtitle: frame != null && frame.isVisibilityValid
                            ? 'Tracking active'
                            : 'Searching body',
                        color: _getStateColor(frame?.aiState),
                      ),
                      // Reps or Hold Progress
                      _buildHudCard(
                        title: isRep ? 'Repetitions' : 'Hold Time',
                        value: isRep
                            ? '${frame?.validReps ?? 0} / ${widget.plan.reps}'
                            : '${frame?.holdState?.currentHoldSeconds.toInt() ?? 0}s / ${widget.plan.holdDurationSeconds.toInt()}s',
                        subtitle: isRep
                            ? '${frame?.invalidAttempts ?? 0} incomplete'
                            : (frame?.holdState?.isPaused ?? false
                                ? 'PAUSED'
                                : 'ACTIVE'),
                        color: AppTheme.stateCorrect,
                      ),
                    ],
                  ),
                  if (kDebugMode && !_isCameraReady) ...[
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Live Angle Adjuster (Debug Only):',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        Expanded(
                          child: Slider(
                            value: _manualAngleSlider,
                            min: 20.0,
                            max: 180.0,
                            divisions: 32,
                            label: '${_manualAngleSlider.toInt()}°',
                            activeColor: AppTheme.primaryTeal,
                            onChanged: (val) {
                              setState(() => _manualAngleSlider = val);
                            },
                          ),
                        ),
                        Text(
                          '${_manualAngleSlider.toInt()}°',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (kDebugMode && !_isCameraReady)
                        ElevatedButton.icon(
                          icon: Icon(
                            _isSimulatedDropoutActive
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 16,
                          ),
                          label: Text(
                            _isSimulatedDropoutActive
                                ? 'Restore Visibility'
                                : 'Simulate Dropout',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSimulatedDropoutActive
                                ? AppTheme.stateCorrect
                                : AppTheme.surfaceBg,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSimulatedDropoutActive = !_isSimulatedDropoutActive;
                            });
                          },
                        )
                      else
                        const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Finish Session', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                        onPressed: _completeSession,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Color _getStateColor(AiState? state) {
    switch (state) {
      case AiState.correct:
        return AppTheme.stateCorrect;
      case AiState.incorrect:
        return AppTheme.stateIncorrect;
      case AiState.insufficientVisibility:
      case null:
        return AppTheme.stateInsufficientVisibility;
    }
  }

  IconData _getStateIcon(AiState? state) {
    switch (state) {
      case AiState.correct:
        return Icons.check_circle_outline;
      case AiState.incorrect:
        return Icons.error_outline;
      case AiState.insufficientVisibility:
      case null:
        return Icons.visibility_off_outlined;
    }
  }

  String _getStateText(AiState? state) {
    switch (state) {
      case AiState.correct:
        return 'CORRECT';
      case AiState.incorrect:
        return 'INCORRECT';
      case AiState.insufficientVisibility:
      case null:
        return 'INSUFFICIENT VISIBILITY';
    }
  }
}
