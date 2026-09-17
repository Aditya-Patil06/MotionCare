// lib/ai/angles/joint_angle_engine.dart
// Single source of truth for biomechanical joint angle computation.
// Specification v7 Section 10: Angle = acos(clamp(dot(BA, BC) / (|BA| * |BC|), -1.0, 1.0)) in degrees.

import 'dart:math' as math;
import '../../models/landmark.dart';

class JointAngleEngine {
  /// Computes the 3D joint angle at vertex [b] between rays [b]->[a] and [b]->[c].
  /// Returns angle in degrees [0.0, 180.0].
  /// Returns 0.0 if either vector has zero length to prevent NaN.
  static double computeAngle(Landmark a, Landmark b, Landmark c) {
    // Vector BA = A - B
    final double bax = a.x - b.x;
    final double bay = a.y - b.y;
    final double baz = a.z - b.z;

    // Vector BC = C - B
    final double bcx = c.x - b.x;
    final double bcy = c.y - b.y;
    final double bcz = c.z - b.z;

    // Dot product
    final double dot = (bax * bcx) + (bay * bcy) + (baz * bcz);

    // Magnitudes
    final double magBA = math.sqrt((bax * bax) + (bay * bay) + (baz * baz));
    final double magBC = math.sqrt((bcx * bcx) + (bcy * bcy) + (bcz * bcz));

    // Handle degenerate zero-length vectors
    if (magBA == 0.0 || magBC == 0.0) {
      return 0.0;
    }

    // Cosine clamped strictly to [-1.0, 1.0]
    final double cosine = (dot / (magBA * magBC)).clamp(-1.0, 1.0);

    // Radians to degrees
    final double angleRadians = math.acos(cosine);
    return angleRadians * (180.0 / math.pi);
  }
}
