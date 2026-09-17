// lib/doctor/plans/doctor_record_video_screen.dart
// In-App Clinician Reference Video Recorder with Real-Time Movement Guidelines
// Enables doctors to see live skeleton tracking, target sector, ghost guideline, and joint angles
// while recording demonstration videos for patients.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../ai/angles/joint_angle_engine.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/landmark.dart';
import '../../patient/exercise/personalized_guidance_painter.dart';
import '../../services/camera/pose_detector_service.dart';

class DoctorRecordVideoScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final BodySide bodySide;
  final double targetAngle;
  final double tolerance;

  const DoctorRecordVideoScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.bodySide = BodySide.right,
    this.targetAngle = 45.0,
    this.tolerance = 12.0,
  });

  @override
  State<DoctorRecordVideoScreen> createState() => _DoctorRecordVideoScreenState();
}

class _DoctorRecordVideoScreenState extends State<DoctorRecordVideoScreen> {
  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  PoseDetectorService? _poseDetectorService;

  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  String? _cameraErrorMessage;

  // Real-time tracking telemetry
  Map<String, Landmark> _currentLandmarks = {};
  double _currentAngle = 180.0;
  AiState _currentAiState = AiState.insufficientVisibility;

  // Recording State Machine
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  Timer? _simulationTimer;

  // Review / Preview mode
  XFile? _recordedFile;
  VideoPlayerController? _previewVideoController;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        // Default to front camera for demonstration self-view
        final frontIdx = _availableCameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        _selectedCameraIndex = frontIdx >= 0 ? frontIdx : 0;
        await _startCameraController(_availableCameras[_selectedCameraIndex]);
      } else {
        setState(() {
          _cameraErrorMessage = 'No cameras detected on this device.';
        });
        _startSimulatorFallback();
      }
    } catch (e) {
      debugPrint('Doctor recorder camera init error: $e');
      setState(() {
        _cameraErrorMessage = 'Camera unavailable or permission denied: $e';
      });
      _startSimulatorFallback();
    }
  }

  Future<void> _startCameraController(CameraDescription camera) async {
    await _cameraController?.dispose();
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      _poseDetectorService = PoseDetectorService();

      _cameraController!.startImageStream((image) async {
        if (!mounted || _previewVideoController != null) return;

        final landmarks = await _poseDetectorService!.processCameraImage(
          image,
          camera,
        );

        if (landmarks != null && mounted) {
          _processLandmarks(landmarks);
        }
      });

      setState(() {
        _isCameraReady = true;
        _cameraErrorMessage = null;
      });
    } catch (e) {
      debugPrint('Failed to start camera controller: $e');
      setState(() {
        _cameraErrorMessage = 'Failed to initialize camera: $e';
      });
      _startSimulatorFallback();
    }
  }

  void _startSimulatorFallback() {
    if (!kDebugMode) return;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _previewVideoController != null) return;

      final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final double cycle = (math.sin(now * 1.5) + 1.0) / 2.0; // 0..1

      final double angle;
      if (widget.exerciseId == 'shoulder_raise') {
        angle = 20.0 + (cycle * 75.0); // 20° to 95°
      } else {
        angle = 160.0 - (cycle * 118.0); // 160° down to 42°
      }

      final syntheticLandmarks = _generateSyntheticLandmarks(angle);
      _processLandmarks(syntheticLandmarks);
    });
  }

  Map<String, Landmark> _generateSyntheticLandmarks(double angleDeg) {
    final prefix = widget.bodySide == BodySide.left ? 'left' : 'right';
    final oppPrefix = widget.bodySide == BodySide.left ? 'right' : 'left';
    final isLeft = widget.bodySide == BodySide.left;

    final double activeShoulderX = isLeft ? 0.40 : 0.60;
    final double oppShoulderX = isLeft ? 0.60 : 0.40;
    const double shoulderY = 0.32;
    const double hipY = 0.68;

    double activeElbowX;
    double activeElbowY;
    double activeWristX;
    double activeWristY;

    final double angleRad = angleDeg * (math.pi / 180.0);

    if (widget.exerciseId == 'shoulder_raise') {
      final double sideDir = isLeft ? -1.0 : 1.0;
      activeElbowX = activeShoulderX + sideDir * 0.22 * math.sin(angleRad);
      activeElbowY = shoulderY + 0.22 * math.cos(angleRad);
      activeWristX = activeShoulderX + sideDir * 0.40 * math.sin(angleRad);
      activeWristY = shoulderY + 0.40 * math.cos(angleRad);
    } else {
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

  void _processLandmarks(Map<String, Landmark> landmarks) {
    final prefix = widget.bodySide == BodySide.left ? 'left' : 'right';

    double angle = 180.0;
    if (widget.exerciseId == 'shoulder_raise') {
      final hip = landmarks['${prefix}_hip'];
      final shoulder = landmarks['${prefix}_shoulder'];
      final elbow = landmarks['${prefix}_elbow'];
      if (hip != null && shoulder != null && elbow != null) {
        angle = JointAngleEngine.computeAngle(hip, shoulder, elbow);
      }
    } else {
      final shoulder = landmarks['${prefix}_shoulder'];
      final elbow = landmarks['${prefix}_elbow'];
      final wrist = landmarks['${prefix}_wrist'];
      if (shoulder != null && elbow != null && wrist != null) {
        angle = JointAngleEngine.computeAngle(shoulder, elbow, wrist);
      }
    }

    final bool inTarget = (angle >= (widget.targetAngle - widget.tolerance)) &&
        (angle <= (widget.targetAngle + widget.tolerance));

    setState(() {
      _currentLandmarks = landmarks;
      _currentAngle = angle;
      _currentAiState = inTarget ? AiState.correct : AiState.incorrect;
    });
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras.length < 2 || _isRecording) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _startCameraController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready for recording.')),
      );
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 30) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) return;
    _recordingTimer?.cancel();

    try {
      final XFile file = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _recordedFile = file;
      });

      // Load preview player
      final controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      controller.setLooping(true);
      controller.play();

      setState(() {
        _previewVideoController = controller;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  void _retakeVideo() async {
    await _previewVideoController?.dispose();
    setState(() {
      _previewVideoController = null;
      _recordedFile = null;
    });
  }

  void _acceptVideo() {
    if (_recordedFile != null) {
      Navigator.pop(context, _recordedFile!.path);
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _simulationTimer?.cancel();
    _cameraController?.dispose();
    _poseDetectorService?.dispose();
    _previewVideoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFront = _cameraController?.description.lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Record Demo: ${widget.exerciseName}'),
        backgroundColor: Colors.black87,
        actions: [
          if (_previewVideoController == null && _availableCameras.length > 1 && !_isRecording)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: AppTheme.primaryTeal),
              tooltip: 'Switch Camera',
              onPressed: _toggleCamera,
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Stream or Video Preview Player
          if (_previewVideoController != null && _previewVideoController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _previewVideoController!.value.aspectRatio,
                child: VideoPlayer(_previewVideoController!),
              ),
            )
          else if (_isCameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              color: AppTheme.darkBg,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_outlined, size: 54, color: AppTheme.primaryTeal),
                    const SizedBox(height: 12),
                    Text(
                      _cameraErrorMessage ?? 'Initializing camera guidelines...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Real-Time Movement Guidelines Overlay
          if (_previewVideoController == null)
            CustomPaint(
              painter: PersonalizedGuidancePainter(
                landmarks: _currentLandmarks,
                currentAngle: _currentAngle,
                targetAngle: widget.targetAngle,
                tolerance: widget.tolerance,
                aiState: _currentAiState,
                bodySide: widget.bodySide,
                exerciseId: widget.exerciseId,
                previewImageSize: _cameraController?.value.previewSize,
                isFrontCamera: isFront,
              ),
            ),

          // 3. Top Clinical Telemetry HUD
          if (_previewVideoController == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _currentAiState == AiState.correct ? AppTheme.stateCorrect : AppTheme.primaryTeal,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentAiState == AiState.correct ? Icons.check_circle : Icons.accessibility_new,
                      color: _currentAiState == AiState.correct ? AppTheme.stateCorrect : AppTheme.primaryAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target: ${widget.targetAngle.toStringAsFixed(0)}° (±${widget.tolerance.toStringAsFixed(0)}°) • ${widget.bodySide.name.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live Measured: ${_currentAngle.toStringAsFixed(1)}°',
                            style: TextStyle(
                              color: _currentAiState == AiState.correct ? AppTheme.stateCorrect : AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              '00:${_recordingSeconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 4. Bottom Controls (Recording or Review)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _previewVideoController != null
                ? _buildReviewControls()
                : _buildRecordingControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Text(
              _isRecording
                  ? 'Demonstrate 3 clean repetitions within the green corridor'
                  : 'Align with skeleton and tap record when ready',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : AppTheme.primaryTeal,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : AppTheme.primaryTeal).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.fiber_manual_record,
                color: Colors.white,
                size: _isRecording ? 28 : 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Reference Demonstration Recorded',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review playback to ensure accurate movement and posture guidelines were captured.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: _retakeVideo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Accept & Use'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: AppTheme.darkBg,
                  ),
                  onPressed: _acceptVideo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
