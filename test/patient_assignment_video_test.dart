import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motioncare/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Doctor assigns plan to patient and patient receives plan and video',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MotionCareApp());
      await tester.pumpAndSettle();

      // Sign in as Doctor
      final doctorSignInBtn = find.text('Sign In to Doctor Dashboard');
      await tester.ensureVisible(doctorSignInBtn);
      await tester.tap(doctorSignInBtn);
      await tester.pumpAndSettle();

      // Verify on Clinician Dashboard with Active Patient Roster
      expect(find.text('Clinician Dashboard'), findsOneWidget);
      expect(find.text('Active Patient Roster'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsWidgets);
      expect(find.text('Maya Lin'), findsOneWidget);
      expect(find.text('David Kim'), findsOneWidget);

      // Switch active patient to Maya Lin
      await tester.tap(find.text('Maya Lin'));
      await tester.pumpAndSettle();

      // Verify Maya Lin is now active
      expect(
        find.textContaining('Left Shoulder / Rotator Cuff'),
        findsOneWidget,
      );

      // Tap "Create Plan"
      final createPlanBtn = find.text('Create Plan');
      await tester.ensureVisible(createPlanBtn);
      await tester.tap(createPlanBtn);
      await tester.pumpAndSettle();

      // Verify on Create Exercise Plan screen with Target Patient Assignment
      expect(find.text('Create Exercise Plan'), findsOneWidget);
      expect(find.text('Target Patient Assignment'), findsOneWidget);

      // Tap Clinical Reference Video to analyze
      final analyzeBtn = find.text('Use Clinical Pre-loaded Demo Video');
      await tester.ensureVisible(analyzeBtn);
      await tester.tap(analyzeBtn);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Confirm and Assign Plan to Patient
      final assignBtn = find.text('Confirm Target & Assign Plan');
      await tester.ensureVisible(assignBtn);
      await tester.tap(assignBtn);
      await tester.pumpAndSettle();

      // Doctor Dashboard now shows prescribed plan for Maya Lin
      expect(find.text('Clinician Dashboard'), findsOneWidget);
      expect(find.text('1 prescribed'), findsOneWidget);
      expect(find.text('Clinician Video Attached'), findsOneWidget);

      // Doctor logs out
      await tester.tap(find.byTooltip('Sign Out to Login Page'));
      await tester.pumpAndSettle();

      // Switch to Patient tab on Login Screen
      await tester.tap(find.text('Patient'));
      await tester.pumpAndSettle();

      // Select Maya Lin account
      final mayaChip = find.widgetWithText(ChoiceChip, 'Maya Lin');
      await tester.ensureVisible(mayaChip);
      await tester.tap(mayaChip);
      await tester.pumpAndSettle();

      // Sign in to Patient Portal
      final patientSignInBtn = find.text('Sign In to Patient Portal');
      await tester.ensureVisible(patientSignInBtn);
      await tester.tap(patientSignInBtn);
      await tester.pumpAndSettle();

      // Verify Maya Lin Patient Dashboard
      expect(find.text('Patient Exercise Home'), findsOneWidget);
      expect(find.text('Maya Lin'), findsOneWidget);
      expect(find.text('Doctor Video Demonstration Available'), findsOneWidget);
      expect(find.text('Watch Video'), findsOneWidget);

      // Tap Watch Video
      final watchVideoBtn = find.text('Watch Video');
      await tester.ensureVisible(watchVideoBtn);
      await tester.tap(watchVideoBtn);
      await tester.pumpAndSettle();

      // Verify Clinician Video Dialog popped up
      expect(find.textContaining('Clinician Demo'), findsOneWidget);
      expect(find.textContaining('Prescribed Joint Angle'), findsOneWidget);
      expect(find.text('Start Monitored Exercise'), findsOneWidget);

      // Close Dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify back on Patient Exercise Home
      expect(find.text('Patient Exercise Home'), findsOneWidget);
    },
  );
}
