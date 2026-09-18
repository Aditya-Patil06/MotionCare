// test/ai/guidance_painter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motioncare/models/enums.dart';
import 'package:motioncare/models/landmark.dart';
import 'package:motioncare/patient/exercise/personalized_guidance_painter.dart';

void main() {
  group('PersonalizedGuidancePainter Movement Guidelines', () {
    testWidgets(
      'Renders Bicep Curl guidelines with target sector and ghost line',
      (tester) async {
        final landmarks = {
          'right_shoulder': const Landmark(x: 0.5, y: 0.3, likelihood: 0.99),
          'right_elbow': const Landmark(x: 0.5, y: 0.55, likelihood: 0.99),
          'right_wrist': const Landmark(x: 0.5, y: 0.80, likelihood: 0.95),
          'right_hip': const Landmark(x: 0.5, y: 0.70, likelihood: 0.95),
          'left_shoulder': const Landmark(x: 0.35, y: 0.3, likelihood: 0.90),
          'left_elbow': const Landmark(x: 0.35, y: 0.55, likelihood: 0.90),
          'left_wrist': const Landmark(x: 0.35, y: 0.80, likelihood: 0.90),
          'left_hip': const Landmark(x: 0.35, y: 0.70, likelihood: 0.90),
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 480,
                child: CustomPaint(
                  painter: PersonalizedGuidancePainter(
                    landmarks: landmarks,
                    currentAngle: 120.0,
                    targetAngle: 42.0,
                    tolerance: 12.0,
                    aiState: AiState.incorrect,
                    bodySide: BodySide.right,
                    exerciseId: 'bicep_curl',
                    isFrontCamera: false,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      },
    );

    testWidgets(
      'Renders Shoulder Raise guidelines with shoulder vertex and abducted arm',
      (tester) async {
        final landmarks = {
          'right_shoulder': const Landmark(x: 0.6, y: 0.35, likelihood: 0.99),
          'right_elbow': const Landmark(x: 0.8, y: 0.35, likelihood: 0.99),
          'right_wrist': const Landmark(x: 0.95, y: 0.35, likelihood: 0.95),
          'right_hip': const Landmark(x: 0.6, y: 0.70, likelihood: 0.95),
          'left_shoulder': const Landmark(x: 0.4, y: 0.35, likelihood: 0.90),
          'left_elbow': const Landmark(x: 0.4, y: 0.55, likelihood: 0.90),
          'left_wrist': const Landmark(x: 0.4, y: 0.80, likelihood: 0.90),
          'left_hip': const Landmark(x: 0.4, y: 0.70, likelihood: 0.90),
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 480,
                child: CustomPaint(
                  painter: PersonalizedGuidancePainter(
                    landmarks: landmarks,
                    currentAngle: 90.0,
                    targetAngle: 85.0,
                    tolerance: 15.0,
                    aiState: AiState.correct,
                    bodySide: BodySide.right,
                    exerciseId: 'shoulder_raise',
                    isFrontCamera: true,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      },
    );

    testWidgets(
      'Handles unscaled pixel coordinates from camera stream gracefully',
      (tester) async {
        final landmarks = {
          'right_shoulder': const Landmark(
            x: 360.0,
            y: 250.0,
            likelihood: 0.99,
          ),
          'right_elbow': const Landmark(x: 360.0, y: 450.0, likelihood: 0.99),
          'right_wrist': const Landmark(x: 360.0, y: 650.0, likelihood: 0.95),
          'right_hip': const Landmark(x: 360.0, y: 600.0, likelihood: 0.95),
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 480,
                child: CustomPaint(
                  painter: PersonalizedGuidancePainter(
                    landmarks: landmarks,
                    currentAngle: 180.0,
                    targetAngle: 42.0,
                    tolerance: 12.0,
                    aiState: AiState.incorrect,
                    bodySide: BodySide.right,
                    exerciseId: 'bicep_curl',
                    previewImageSize: const Size(720, 1280),
                    isFrontCamera: true,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      },
    );
  });
}
