// test/ai/visibility_tracker_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:motioncare/ai/visibility/visibility_tracker.dart';
import 'package:motioncare/models/enums.dart';
import 'package:motioncare/models/landmark.dart';

void main() {
  group('VisibilityTracker Hysteresis and Gatekeeper', () {
    late VisibilityTracker tracker;
    final validLandmarks = {
      'shoulder': Landmark(x: 0.5, y: 0.2, likelihood: 0.95),
      'elbow': Landmark(x: 0.5, y: 0.5, likelihood: 0.90),
      'wrist': Landmark(x: 0.5, y: 0.8, likelihood: 0.85),
    };
    final requiredKeys = ['shoulder', 'elbow', 'wrist'];

    setUp(() {
      tracker = VisibilityTracker(
        confidenceThreshold: 0.60,
        failThreshold: 5,
        passThreshold: 3,
        initialValidState: true,
      );
    });

    test('Remains valid under continuous valid frames', () {
      final res = tracker.evaluate(
        landmarks: validLandmarks,
        requiredLandmarkKeys: requiredKeys,
      );
      expect(res.isValid, isTrue);
      expect(res.issueCode, equals(IssueCode.none));
    });

    test('Hysteresis: 4 consecutive failures do NOT drop valid state (anti-flicker)', () {
      final badLandmarks = {
        'shoulder': Landmark(x: 0.5, y: 0.2, likelihood: 0.95),
        'elbow': Landmark(x: 0.5, y: 0.5, likelihood: 0.20), // low confidence
        'wrist': Landmark(x: 0.5, y: 0.8, likelihood: 0.85),
      };

      for (int i = 1; i <= 4; i++) {
        final res = tracker.evaluate(
          landmarks: badLandmarks,
          requiredLandmarkKeys: requiredKeys,
        );
        expect(
          res.isValid,
          isTrue,
          reason: 'Frame $i should not trip threshold',
        );
      }
      expect(tracker.consecutiveFails, equals(4));
    });

    test(
      'Hysteresis: 5th consecutive failure drops to insufficientVisibility',
      () {
        final badLandmarks = {
          'shoulder': Landmark(x: 0.5, y: 0.2, likelihood: 0.95),
          // missing elbow completely
          'wrist': Landmark(x: 0.5, y: 0.8, likelihood: 0.85),
        };

        for (int i = 1; i <= 4; i++) {
          tracker.evaluate(
            landmarks: badLandmarks,
            requiredLandmarkKeys: requiredKeys,
          );
        }
        final res5 = tracker.evaluate(
          landmarks: badLandmarks,
          requiredLandmarkKeys: requiredKeys,
        );
        expect(res5.isValid, isFalse);
        expect(res5.issueCode, equals(IssueCode.insufficientVisibility));
        expect(res5.missingLandmarks, contains('elbow'));
      },
    );

    test(
      'Hysteresis: 3 consecutive passes required to restore valid state',
      () {
        // Start in invalid state
        tracker.reset(initialValid: false);
        expect(tracker.isCurrentlyValid, isFalse);

        // Pass 1
        var res = tracker.evaluate(
          landmarks: validLandmarks,
          requiredLandmarkKeys: requiredKeys,
        );
        expect(res.isValid, isFalse);
        expect(tracker.consecutivePasses, equals(1));

        // Pass 2
        res = tracker.evaluate(
          landmarks: validLandmarks,
          requiredLandmarkKeys: requiredKeys,
        );
        expect(res.isValid, isFalse);
        expect(tracker.consecutivePasses, equals(2));

        // Pass 3 -> Restored
        res = tracker.evaluate(
          landmarks: validLandmarks,
          requiredLandmarkKeys: requiredKeys,
        );
        expect(res.isValid, isTrue);
        expect(res.issueCode, equals(IssueCode.none));
      },
    );
  });
}
