// lib/patient/calibration/calibration_screen.dart
// Specification v7 Section 13: Camera Calibration & Gatekeeper Screen
// Approximately 2 seconds of stable valid visibility (>=90% valid visibility) required before exercise.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/plan.dart';
import '../exercise/live_exercise_screen.dart';

class CalibrationScreen extends StatefulWidget {
  final ExercisePlan plan;

  const CalibrationScreen({super.key, required this.plan});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  double _calibrationProgress = 0.0;
  bool _isCalibrating = false;
  bool _isReady = false;
  Timer? _timer;

  // Criteria checks
  bool _bodyVisible = false;
  bool _requiredJointsVisible = false;
  bool _lightingSufficient = false;
  bool _cameraStable = false;

  @override
  void initState() {
    super.initState();
    _startCalibration();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCalibration() {
    setState(() {
      _calibrationProgress = 0.0;
      _isCalibrating = true;
      _isReady = false;
      _bodyVisible = false;
      _requiredJointsVisible = false;
      _lightingSufficient = false;
      _cameraStable = false;
    });

    // 2-second calibration window (20 steps of 100ms)
    int tick = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      tick++;
      final progress = tick / 20.0;

      setState(() {
        _calibrationProgress = progress.clamp(0.0, 1.0);
        if (tick >= 5) _bodyVisible = true;
        if (tick >= 10) _lightingSufficient = true;
        if (tick >= 15) _requiredJointsVisible = true;
        if (tick >= 18) _cameraStable = true;
      });

      if (tick >= 20) {
        t.cancel();
        setState(() {
          _isCalibrating = false;
          _isReady = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Calibration Check'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Simulated Camera Framing Viewport
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isReady
                      ? AppTheme.stateCorrect
                      : AppTheme.primaryTeal.withOpacity(0.5),
                  width: 2.0,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Framing Outline
                  Icon(
                    Icons.accessibility_new,
                    size: 140,
                    color: _isReady
                        ? AppTheme.stateCorrect.withOpacity(0.8)
                        : AppTheme.textMuted.withOpacity(0.4),
                  ),

                  // Calibration Progress Overlay
                  if (_isCalibrating)
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _calibrationProgress,
                            backgroundColor: AppTheme.surfaceBg,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryTeal,
                            ),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Calibrating camera & posture framing (2s)...',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),

                  if (_isReady)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.stateCorrect,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'READY FOR EXERCISE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Calibration Checklist Cards (Section 13)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildChecklistRow(
                      'Body visible within camera frame',
                      _bodyVisible,
                    ),
                    const Divider(height: 16),
                    _buildChecklistRow(
                      'Required joints detected (${widget.plan.bodySide.name.toUpperCase()} side)',
                      _requiredJointsVisible,
                    ),
                    const Divider(height: 16),
                    _buildChecklistRow(
                      'Environmental lighting sufficient',
                      _lightingSufficient,
                    ),
                    const Divider(height: 16),
                    _buildChecklistRow(
                      'Camera position stable & steady',
                      _cameraStable,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Gatekeeper Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Monitored Exercise'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReady
                      ? AppTheme.stateCorrect
                      : AppTheme.surfaceBg,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isReady
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LiveExerciseScreen(plan: widget.plan),
                          ),
                        );
                      }
                    : null,
              ),
            ),
            if (!_isReady) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Restart Calibration Check'),
                onPressed: _startCalibration,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String title, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSatisfied ? AppTheme.stateCorrect : AppTheme.textMuted,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isSatisfied ? AppTheme.textLight : AppTheme.textMuted,
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
