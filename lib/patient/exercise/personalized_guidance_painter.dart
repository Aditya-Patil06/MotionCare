// lib/patient/exercise/personalized_guidance_painter.dart
// Specification v7 Section 19: Personalized Target Movement Guidance & Live Pose Overlay
// Draws live skeleton joints, exercise-adaptive target sector, ghost target guideline,
// live angle arc, floating joint degree badges, and directional cues.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/landmark.dart';

class PersonalizedGuidancePainter extends CustomPainter {
  final Map<String, Landmark> landmarks;
  final double currentAngle;
  final double targetAngle;
  final double tolerance;
  final AiState aiState;
  final BodySide bodySide;
  final String exerciseId;
  final Size? previewImageSize;
  final bool isFrontCamera;

  PersonalizedGuidancePainter({
    required this.landmarks,
    required this.currentAngle,
    required this.targetAngle,
    required this.tolerance,
    required this.aiState,
    this.bodySide = BodySide.right,
    this.exerciseId = 'bicep_curl',
    this.previewImageSize,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw Viewport Framing Corner Brackets
    _drawFramingGuides(canvas, size);

    if (landmarks.isEmpty) return;

    Color stateColor;
    switch (aiState) {
      case AiState.correct:
        stateColor = AppTheme.stateCorrect;
        break;
      case AiState.incorrect:
        stateColor = AppTheme.stateIncorrect;
        break;
      case AiState.insufficientVisibility:
        stateColor = AppTheme.stateInsufficientVisibility;
        break;
    }

    // Helper: Map Landmark coordinates to Canvas pixels
    Offset toOffset(Landmark lm) {
      double normX;
      double normY;

      if (previewImageSize != null) {
        final double imgW = math.min(
          previewImageSize!.width,
          previewImageSize!.height,
        );
        final double imgH = math.max(
          previewImageSize!.width,
          previewImageSize!.height,
        );

        if (lm.x > 1.0 || lm.y > 1.0) {
          normX = (lm.x / imgW).clamp(0.0, 1.0);
          normY = (lm.y / imgH).clamp(0.0, 1.0);
        } else {
          normX = lm.x.clamp(0.0, 1.0);
          normY = lm.y.clamp(0.0, 1.0);
        }
      } else {
        if (lm.x > 1.0 || lm.y > 1.0) {
          // Fallback portrait assumptions for unscaled pixels
          normX = (lm.x / 720.0).clamp(0.0, 1.0);
          normY = (lm.y / 1280.0).clamp(0.0, 1.0);
        } else {
          normX = lm.x.clamp(0.0, 1.0);
          normY = lm.y.clamp(0.0, 1.0);
        }
      }

      if (isFrontCamera) {
        normX = 1.0 - normX;
      }

      return Offset(normX * size.width, normY * size.height);
    }

    // 2. Draw Skeleton Limbs
    _drawFullSkeleton(canvas, toOffset, stateColor);

    // 3. Draw Exercise-Specific Movement Guidelines (Target Sector, Ghost Line, Arcs)
    _drawExerciseMovementGuidance(canvas, size, toOffset, stateColor);
  }

  void _drawFramingGuides(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = AppTheme.primaryTeal.withOpacity(0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double cornerLen = 22.0;
    const double pad = 12.0;

    // Top-Left
    canvas.drawLine(
      const Offset(pad, pad),
      const Offset(pad + cornerLen, pad),
      framePaint,
    );
    canvas.drawLine(
      const Offset(pad, pad),
      const Offset(pad, pad + cornerLen),
      framePaint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(size.width - pad - cornerLen, pad),
      framePaint,
    );
    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(size.width - pad, pad + cornerLen),
      framePaint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(pad + cornerLen, size.height - pad),
      framePaint,
    );
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(pad, size.height - pad - cornerLen),
      framePaint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(size.width - pad, size.height - pad),
      Offset(size.width - pad - cornerLen, size.height - pad),
      framePaint,
    );
    canvas.drawLine(
      Offset(size.width - pad, size.height - pad),
      Offset(size.width - pad, size.height - pad - cornerLen),
      framePaint,
    );
  }

  void _drawFullSkeleton(
    Canvas canvas,
    Offset Function(Landmark) toOffset,
    Color stateColor,
  ) {
    final leftShoulder = landmarks['left_shoulder'];
    final rightShoulder = landmarks['right_shoulder'];
    final leftElbow = landmarks['left_elbow'];
    final rightElbow = landmarks['right_elbow'];
    final leftWrist = landmarks['left_wrist'];
    final rightWrist = landmarks['right_wrist'];
    final leftHip = landmarks['left_hip'];
    final rightHip = landmarks['right_hip'];

    final inactiveBonePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final activeBonePaint = Paint()
      ..color = stateColor.withOpacity(0.9)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    void drawBone(Landmark? a, Landmark? b, bool isActive) {
      if (a == null || b == null) return;
      canvas.drawLine(
        toOffset(a),
        toOffset(b),
        isActive ? activeBonePaint : inactiveBonePaint,
      );
    }

    // Torso Frame
    drawBone(leftShoulder, rightShoulder, false);
    drawBone(leftHip, rightHip, false);
    drawBone(leftShoulder, leftHip, false);
    drawBone(rightShoulder, rightHip, false);

    final bool isRightActive = bodySide == BodySide.right;
    final bool isLeftActive = bodySide == BodySide.left;

    // Arms
    drawBone(rightShoulder, rightElbow, isRightActive);
    drawBone(rightElbow, rightWrist, isRightActive);
    drawBone(leftShoulder, leftElbow, isLeftActive);
    drawBone(leftElbow, leftWrist, isLeftActive);

    // Keypoint Joint Nodes
    for (final entry in landmarks.entries) {
      final p = toOffset(entry.value);
      final bool isCurrentSide = entry.key.startsWith(
        bodySide == BodySide.left ? 'left' : 'right',
      );
      final double r = isCurrentSide ? 6.0 : 4.0;

      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = isCurrentSide ? stateColor : Colors.white54
          ..style = PaintingStyle.fill,
      );

      if (isCurrentSide) {
        canvas.drawCircle(
          p,
          r + 3.5,
          Paint()
            ..color = stateColor.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    }
  }

  void _drawExerciseMovementGuidance(
    Canvas canvas,
    Size size,
    Offset Function(Landmark) toOffset,
    Color stateColor,
  ) {
    final String prefix = bodySide == BodySide.left ? 'left' : 'right';

    Landmark? anchorLm; // Anchor A
    Landmark? vertexLm; // Primary Joint B
    Landmark? movingLm; // Moving Limb Endpoint C

    if (exerciseId == 'shoulder_raise') {
      anchorLm = landmarks['${prefix}_hip'];
      vertexLm = landmarks['${prefix}_shoulder'];
      movingLm = landmarks['${prefix}_elbow'];
    } else {
      // Bicep Curl (default)
      anchorLm = landmarks['${prefix}_shoulder'];
      vertexLm = landmarks['${prefix}_elbow'];
      movingLm = landmarks['${prefix}_wrist'];
    }

    if (anchorLm == null || vertexLm == null || movingLm == null) return;

    final pA = toOffset(anchorLm);
    final pB = toOffset(vertexLm);
    final pC = toOffset(movingLm);

    // Vectors
    final double dxA = pA.dx - pB.dx;
    final double dyA = pA.dy - pB.dy;
    final double alphaA = math.atan2(dyA, dxA);

    final double dxC = pC.dx - pB.dx;
    final double dyC = pC.dy - pB.dy;
    final double alphaC = math.atan2(dyC, dxC);

    final double limbLength = math.sqrt((dxC * dxC) + (dyC * dyC));
    final double effectiveLimbLen = limbLength > 30.0 ? limbLength : 90.0;
    final double arcRadius = (effectiveLimbLen * 0.55).clamp(45.0, 95.0);

    // Determine direction of rotation from base ray BA to moving ray BC
    double diff = alphaC - alphaA;
    while (diff > math.pi) {
      diff -= 2 * math.pi;
    }
    while (diff < -math.pi) {
      diff += 2 * math.pi;
    }
    final double rotSign = diff >= 0 ? 1.0 : -1.0;

    final double targetRad = targetAngle * (math.pi / 180.0);
    final double tolRad = tolerance * (math.pi / 180.0);

    // Ideal target orientation
    final double targetDir = alphaA + (rotSign * targetRad);

    // Corridor range angles
    final double minCorridorAngle = alphaA + (rotSign * (targetRad - tolRad));
    final double maxCorridorAngle = alphaA + (rotSign * (targetRad + tolRad));
    final double startAngle = math.min(minCorridorAngle, maxCorridorAngle);
    final double sweepAngle = (maxCorridorAngle - minCorridorAngle).abs();

    // 1. Draw Target Corridor / Acceptable Sector
    final corridorRect = Rect.fromCircle(center: pB, radius: arcRadius);
    final corridorPaint = Paint()
      ..color = AppTheme.primaryTeal.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    canvas.drawArc(corridorRect, startAngle, sweepAngle, true, corridorPaint);

    final corridorBorderPaint = Paint()
      ..color = AppTheme.primaryTeal.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      corridorRect,
      startAngle,
      sweepAngle,
      false,
      corridorBorderPaint,
    );

    // 2. Draw Ideal Ghost Target Guideline
    final targetEnd = Offset(
      pB.dx + effectiveLimbLen * math.cos(targetDir),
      pB.dy + effectiveLimbLen * math.sin(targetDir),
    );

    _drawDashedLine(
      canvas,
      pB,
      targetEnd,
      Paint()
        ..color = AppTheme.primaryAccent
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke,
    );

    // Target Bullseye Node at Target Guideline Endpoint
    canvas.drawCircle(
      targetEnd,
      8.0,
      Paint()
        ..color = AppTheme.primaryTeal
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      targetEnd,
      12.0,
      Paint()
        ..color = AppTheme.primaryAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 3. Draw Live Angle Arc
    final double liveStart = math.min(alphaA, alphaC);
    final double liveSweep = (alphaC - alphaA).abs();
    final double liveArcRadius = arcRadius * 0.85;
    final liveRect = Rect.fromCircle(center: pB, radius: liveArcRadius);

    canvas.drawArc(
      liveRect,
      liveStart,
      liveSweep > math.pi ? (2 * math.pi - liveSweep) : liveSweep,
      false,
      Paint()
        ..color = stateColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // 4. Draw Floating Joint Degree Badge
    _drawJointBadge(canvas, pB, stateColor);

    // 5. Draw Directional Movement Cue
    _drawDirectionalCue(canvas, pB, effectiveLimbLen, stateColor);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    final double distance = (p2 - p1).distance;
    final double dx = (p2.dx - p1.dx) / distance;
    final double dy = (p2.dy - p1.dy) / distance;

    double currentDist = 0.0;
    while (currentDist < distance) {
      final double endDist = math.min(currentDist + dashWidth, distance);
      canvas.drawLine(
        Offset(p1.dx + dx * currentDist, p1.dy + dy * currentDist),
        Offset(p1.dx + dx * endDist, p1.dy + dy * endDist),
        paint,
      );
      currentDist += dashWidth + dashSpace;
    }
  }

  void _drawJointBadge(Canvas canvas, Offset pB, Color stateColor) {
    final String currentStr = '${currentAngle.toStringAsFixed(0)}°';
    final String targetStr =
        'Target: ${targetAngle.toStringAsFixed(0)}°±${tolerance.toStringAsFixed(0)}°';

    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: '$currentStr\n',
          style: TextStyle(
            color: stateColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        TextSpan(
          text: targetStr,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );

    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeOffset = Offset(
      (pB.dx - tp.width / 2).clamp(10.0, 400.0),
      pB.dy - tp.height - 18.0,
    );

    final badgeRect = Rect.fromLTWH(
      badgeOffset.dx - 6,
      badgeOffset.dy - 4,
      tp.width + 12,
      tp.height + 8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)),
      Paint()..color = Colors.black87,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)),
      Paint()
        ..color = stateColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    tp.paint(canvas, badgeOffset);
  }

  void _drawDirectionalCue(
    Canvas canvas,
    Offset pB,
    double limbLength,
    Color stateColor,
  ) {
    String cueText = '';
    Color cueColor = stateColor;

    if (aiState == AiState.correct) {
      cueText = '✓ IN TARGET ZONE';
      cueColor = AppTheme.stateCorrect;
    } else if (exerciseId == 'bicep_curl') {
      if (currentAngle > targetAngle + tolerance) {
        cueText = '↑ CURL HIGHER';
        cueColor = AppTheme.stateIncorrect;
      } else if (currentAngle < targetAngle - tolerance) {
        cueText = '↓ EXTEND SLIGHTLY';
        cueColor = AppTheme.stateIncorrect;
      }
    } else if (exerciseId == 'shoulder_raise') {
      if (currentAngle < targetAngle - tolerance) {
        cueText = '↑ RAISE HIGHER';
        cueColor = AppTheme.stateIncorrect;
      } else if (currentAngle > targetAngle + tolerance) {
        cueText = '↓ LOWER SLIGHTLY';
        cueColor = AppTheme.stateIncorrect;
      }
    }

    if (cueText.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: cueText,
        style: TextStyle(
          color: cueColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cueOffset = Offset(
      (pB.dx - tp.width / 2).clamp(10.0, 400.0),
      pB.dy + 18.0,
    );

    final bgRect = Rect.fromLTWH(
      cueOffset.dx - 6,
      cueOffset.dy - 3,
      tp.width + 12,
      tp.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()..color = Colors.black87,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()
        ..color = cueColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    tp.paint(canvas, cueOffset);
  }

  @override
  bool shouldRepaint(covariant PersonalizedGuidancePainter oldDelegate) {
    return oldDelegate.currentAngle != currentAngle ||
        oldDelegate.aiState != aiState ||
        oldDelegate.landmarks != landmarks ||
        oldDelegate.targetAngle != targetAngle ||
        oldDelegate.tolerance != tolerance ||
        oldDelegate.exerciseId != exerciseId;
  }
}
