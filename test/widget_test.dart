// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motioncare/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'App renders Login Screen, signs into Doctor, logs out, and switches to Patient via tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MotionCareApp());
      await tester.pumpAndSettle();

      // Verify Login Screen renders with MotionCare title
      expect(find.text('MotionCare'), findsOneWidget);
      final doctorSignInBtn = find.text('Sign In to Doctor Dashboard');
      expect(doctorSignInBtn, findsOneWidget);

      // Verify no inline profile switch buttons exist on login
      expect(find.text('Switch to Patient Mode (Alex Rivera)'), findsNothing);

      // Sign in as Doctor
      await tester.ensureVisible(doctorSignInBtn);
      await tester.tap(doctorSignInBtn);
      await tester.pumpAndSettle();

      // Verify Doctor Dashboard renders and has NO inline switch arrow button
      expect(find.text('Clinician Dashboard'), findsOneWidget);
      expect(find.text('Patient Mode'), findsNothing);

      // Tap logout to return to login screen
      await tester.tap(find.byTooltip('Sign Out to Login Page'));
      await tester.pumpAndSettle();

      // Verify back on Login Screen
      expect(find.text('MotionCare'), findsOneWidget);

      // Switch to Patient tab
      final patientTab = find.text('Patient');
      expect(patientTab, findsOneWidget);
      await tester.tap(patientTab);
      await tester.pumpAndSettle();

      // Verify sign in button updated for Patient
      final patientSignInBtn = find.text('Sign In to Patient Portal');
      expect(patientSignInBtn, findsOneWidget);

      // Sign in as Patient
      await tester.ensureVisible(patientSignInBtn);
      await tester.tap(patientSignInBtn);
      await tester.pumpAndSettle();

      // Verify Patient Dashboard renders and has NO inline switch arrow button
      expect(find.text('Patient Exercise Home'), findsOneWidget);
      expect(find.text('Clinician Mode'), findsNothing);

      // Tap logout from Patient Dashboard
      await tester.tap(find.byTooltip('Sign Out to Login Page'));
      await tester.pumpAndSettle();

      // Verify back on Login Screen
      expect(find.text('MotionCare'), findsOneWidget);
    },
  );
}
