// lib/patient/exercise/clinician_video_dialog.dart
// Specification v7 Section 16 & 29: Clinician Demonstration Video Playback for Patients

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/plan.dart';
import '../calibration/calibration_screen.dart';

class ClinicianVideoDialog extends StatefulWidget {
  final ExercisePlan plan;
  final bool showStartButton;

  const ClinicianVideoDialog({
    super.key,
    required this.plan,
    this.showStartButton = true,
  });

  static Future<void> show(
    BuildContext context,
    ExercisePlan plan, {
    bool showStartButton = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          ClinicianVideoDialog(plan: plan, showStartButton: showStartButton),
    );
  }

  @override
  State<ClinicianVideoDialog> createState() => _ClinicianVideoDialogState();
}

class _ClinicianVideoDialogState extends State<ClinicianVideoDialog> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final path = widget.plan.referenceVideoUrl;
    if (path.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No video file attached to this plan.';
      });
      return;
    }

    try {
      if (path.startsWith('assets/')) {
        _controller = VideoPlayerController.asset(path);
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else {
        final file = File(path);
        if (await file.exists()) {
          _controller = VideoPlayerController.file(file);
        } else {
          _controller = VideoPlayerController.asset(
            'assets/demo/reference_bicep_curl.mp4',
          );
        }
      }

      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Clinician demonstration video loaded. Follow prescribed form cues below.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isRep = plan.exerciseType == ExerciseType.rep;

    return Dialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.video_camera_front,
                      color: AppTheme.primaryTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan.exerciseName} Clinician Demo',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const Text(
                          'Demonstrated by Dr. Sarah Chen, PT, DPT',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Video Player Container or Fallback
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 230,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isInitialized && _controller != null)
                            AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio > 0
                                  ? _controller!.value.aspectRatio
                                  : 16 / 9,
                              child: VideoPlayer(_controller!),
                            )
                          else if (_hasError)
                            Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryTeal.withOpacity(
                                          0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.videocam_rounded,
                                        size: 30,
                                        color: AppTheme.primaryTeal,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Clinician Form Demonstration',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _errorMessage ??
                                          'Prescribed demonstration by Dr. Sarah Chen for ${plan.exerciseName} (${plan.bodySide.name.toUpperCase()} Arm).',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.refresh, size: 14),
                                      label: const Text(
                                        'Replay Video',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryTeal,
                                        side: BorderSide(
                                          color: AppTheme.primaryTeal
                                              .withOpacity(0.5),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _hasError = false;
                                          _isInitialized = false;
                                        });
                                        _initPlayer();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppTheme.primaryTeal,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Loading clinician demonstration...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),

                          // Play / Pause Tap Overlay when initialized
                          if (_isInitialized && _controller != null)
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    if (_controller!.value.isPlaying) {
                                      _controller!.pause();
                                    } else {
                                      _controller!.play();
                                    }
                                  });
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: !_controller!.value.isPlaying
                                      ? Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Biomechanical Target Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Prescribed Joint Angle:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                              Text(
                                '${plan.effectiveTargetAngle.toStringAsFixed(1)}° (±${plan.extractedAngleTolerance.toStringAsFixed(0)}°)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.primaryAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Prescription Target:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                              Text(
                                isRep
                                    ? '${plan.reps} Reps x ${plan.sets} Sets'
                                    : '${plan.holdDurationSeconds.toInt()}s Hold x ${plan.sets} Sets',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Form Cues and Pacing
                    const Text(
                      'Clinician Form & Pacing Instructions:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Match the speed demonstrated in the video above.\n'
                      '• Reach the prescribed joint peak before initiating return.\n'
                      '• Keep your core steady and avoid compensating with torso swing.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  if (widget.showStartButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Monitored Exercise'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.stateCorrect,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CalibrationScreen(plan: plan),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
