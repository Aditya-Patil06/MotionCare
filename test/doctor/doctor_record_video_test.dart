// test/doctor/doctor_record_video_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/doctor/plans/doctor_record_video_screen.dart';
import 'package:physio_app/models/enums.dart';

void main() {
  testWidgets('DoctorRecordVideoScreen initializes with guidelines overlay and telemetry HUD', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DoctorRecordVideoScreen(
          exerciseId: 'bicep_curl',
          exerciseName: 'Bicep Curl',
          bodySide: BodySide.right,
          targetAngle: 42.0,
          tolerance: 12.0,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Title & Telemetry Header
    expect(find.text('Record Demo: Bicep Curl'), findsOneWidget);
    expect(find.textContaining('Target: 42° (±12°) • RIGHT'), findsOneWidget);
    expect(find.textContaining('Live Measured:'), findsOneWidget);

    // Verify Guidelines CustomPaint overlay is present
    expect(find.byType(CustomPaint), findsWidgets);

    // Verify Bottom Action Controls
    expect(find.textContaining('Align with skeleton'), findsOneWidget);
  });
}
