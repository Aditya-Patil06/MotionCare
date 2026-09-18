// test/ai/joint_angle_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:motioncare/ai/angles/joint_angle_engine.dart';
import 'package:motioncare/models/landmark.dart';

void main() {
  group('JointAngleEngine Biomechanical Mathematics', () {
    test('Calculates exact 90 degree angle (perpendicular vectors)', () {
      final a = Landmark(x: 0, y: 1, z: 0, likelihood: 1.0);
      final b = Landmark(x: 0, y: 0, z: 0, likelihood: 1.0); // vertex
      final c = Landmark(x: 1, y: 0, z: 0, likelihood: 1.0);

      final angle = JointAngleEngine.computeAngle(a, b, c);
      expect(angle, closeTo(90.0, 0.001));
    });

    test(
      'Calculates exact 180 degree angle (straight limb / collinear opposite)',
      () {
        final a = Landmark(x: 0, y: 1, z: 0, likelihood: 1.0);
        final b = Landmark(x: 0, y: 0, z: 0, likelihood: 1.0); // vertex
        final c = Landmark(x: 0, y: -1, z: 0, likelihood: 1.0);

        final angle = JointAngleEngine.computeAngle(a, b, c);
        expect(angle, closeTo(180.0, 0.001));
      },
    );

    test('Calculates exact 0 degree angle (collinear same direction)', () {
      final a = Landmark(x: 0, y: 1, z: 0, likelihood: 1.0);
      final b = Landmark(x: 0, y: 0, z: 0, likelihood: 1.0); // vertex
      final c = Landmark(x: 0, y: 2, z: 0, likelihood: 1.0);

      final angle = JointAngleEngine.computeAngle(a, b, c);
      expect(angle, closeTo(0.0, 0.001));
    });

    test('Calculates 45 degree angle accurately', () {
      final a = Landmark(x: 1, y: 1, z: 0, likelihood: 1.0);
      final b = Landmark(x: 0, y: 0, z: 0, likelihood: 1.0); // vertex
      final c = Landmark(x: 1, y: 0, z: 0, likelihood: 1.0);

      final angle = JointAngleEngine.computeAngle(a, b, c);
      expect(angle, closeTo(45.0, 0.001));
    });

    test('Calculates 3D angle with depth component z', () {
      final a = Landmark(x: 0, y: 1, z: 0, likelihood: 1.0);
      final b = Landmark(x: 0, y: 0, z: 0, likelihood: 1.0);
      final c = Landmark(x: 0, y: 0, z: 1, likelihood: 1.0);

      final angle = JointAngleEngine.computeAngle(a, b, c);
      expect(angle, closeTo(90.0, 0.001));
    });

    test('Safely handles zero-length vector without NaN or crash', () {
      final a = Landmark(x: 0, y: 0, z: 0, likelihood: 1.0);
      final b = Landmark(x: 0, y: 0, z: 0, likelihood: 1.0); // same as a
      final c = Landmark(x: 1, y: 0, z: 0, likelihood: 1.0);

      final angle = JointAngleEngine.computeAngle(a, b, c);
      expect(angle, equals(0.0));
      expect(angle.isNaN, isFalse);
    });

    test('Cosine clamping prevents numerical domain error for acos', () {
      // Very close points that could yield floating point 1.0000000000000002
      final a = Landmark(x: 1000.0, y: 1000.0, z: 1000.0, likelihood: 1.0);
      final b = Landmark(x: 0.0, y: 0.0, z: 0.0, likelihood: 1.0);
      final c = Landmark(x: 2000.0, y: 2000.0, z: 2000.0, likelihood: 1.0);

      final angle = JointAngleEngine.computeAngle(a, b, c);
      expect(angle, closeTo(0.0, 0.001));
      expect(angle.isNaN, isFalse);
    });
  });
}
