import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motioncare/models/user.dart';
import 'package:motioncare/services/auth/auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Persistence & Restoration', () {
    test('Default session is unauthenticated', () async {
      final auth = AuthService();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('Persists and restores Doctor session', () async {
      final auth = AuthService();
      await auth.signInAsDoctor();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isDoctor, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_active_role'), equals(UserRole.doctor.name));

      // Create new AuthService to simulate app restart
      final restoredAuth = AuthService();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(restoredAuth.isAuthenticated, isTrue);
      expect(restoredAuth.isDoctor, isTrue);
      expect(restoredAuth.currentUser?.id, equals(AuthService.demoDoctor.id));
    });

    test('Persists and restores Patient session with patientId', () async {
      final auth = AuthService();
      await auth.signInAsPatient(patientId: 'pat_custom_123');
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isPatient, isTrue);
      expect(auth.currentUser?.id, equals('pat_custom_123'));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('auth_active_role'),
        equals(UserRole.patient.name),
      );
      expect(
        prefs.getString('auth_active_patient_id'),
        equals('pat_custom_123'),
      );

      // Simulate app restart
      final restoredAuth = AuthService();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(restoredAuth.isAuthenticated, isTrue);
      expect(restoredAuth.isPatient, isTrue);
      expect(restoredAuth.currentUser?.id, equals('pat_custom_123'));
    });

    test('Sign out clears persisted session', () async {
      final auth = AuthService();
      await auth.signInAsDoctor();
      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_active_role'), isNull);
      expect(prefs.getString('auth_active_patient_id'), isNull);

      // Simulate app restart
      final restoredAuth = AuthService();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(restoredAuth.isAuthenticated, isFalse);
    });
  });
}
