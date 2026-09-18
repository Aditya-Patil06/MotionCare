// test/ai/reference_analyzer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:motioncare/ai/reference/reference_analyzer.dart';
import 'package:motioncare/models/landmark.dart';

void main() {
  group('ReferenceAnalyzer Biomechanical Extraction & Validation', () {
    const bicepBounds = BiomechanicsBounds(
      minPlausibleAngle: 20.0,
      maxPlausibleAngle: 180.0,
      targetMinAngle: 25.0,
      targetMaxAngle: 110.0,
    );

    late ReferenceAnalyzer analyzer;

    setUp(() {
      analyzer = const ReferenceAnalyzer(bounds: bicepBounds);
    });

    test('Extracts valid target angle from clean 3-rep reference series', () {
      final now = DateTime.now();
      final List<AngleSample> samples = [];

      // 3 complete curls at ~10 FPS (100ms interval):
      // Rep 1: 160 -> 42 -> 160
      // Rep 2: 160 -> 44 -> 160
      // Rep 3: 160 -> 43 -> 160
      final profileAngles = [
        // Setup 1 second
        160.0, 160.0, 160.0, 160.0, 160.0, 160.0, 160.0, 160.0, 160.0, 160.0,
        // Rep 1
        155.0,
        130.0,
        100.0,
        70.0,
        48.0,
        42.0,
        42.0,
        43.0,
        65.0,
        95.0,
        130.0,
        160.0,
        160.0, 160.0, 160.0,
        // Rep 2
        150.0,
        120.0,
        90.0,
        60.0,
        47.0,
        44.0,
        44.0,
        45.0,
        70.0,
        110.0,
        145.0,
        160.0,
        160.0, 160.0, 160.0,
        // Rep 3
        152.0,
        125.0,
        85.0,
        65.0,
        46.0,
        43.0,
        43.0,
        44.0,
        75.0,
        115.0,
        150.0,
        160.0,
        160.0, 160.0,
      ];

      for (int i = 0; i < profileAngles.length; i++) {
        samples.add(
          AngleSample(
            timestamp: now.add(Duration(milliseconds: i * 100)),
            angle: profileAngles[i],
            visibilityValid: true,
          ),
        );
      }

      final profile = analyzer.analyze(
        samples: samples,
        exerciseId: 'bicep_curl',
      );

      expect(profile.isPlausible, isTrue);
      expect(profile.targetAngle, closeTo(43.0, 2.0));
      expect(profile.confidence, greaterThanOrEqualTo(0.70));
      expect(
        profile.reviewPrompt,
        contains('Acceptable extraction confidence'),
      );
    });

    test(
      'Rejects implausible target without silent clamping (e.g. 15 degrees)',
      () {
        final now = DateTime.now();
        final List<AngleSample> samples = [];

        // Reps that go into physically implausible hyper-flexion (15°)
        final profileAngles = [
          160.0,
          160.0,
          160.0,
          160.0,
          160.0,
          160.0,
          160.0,
          160.0,
          160.0,
          160.0,
          140.0,
          100.0,
          50.0,
          20.0,
          15.0,
          15.0,
          16.0,
          60.0,
          120.0,
          160.0,
          160.0,
          160.0,
          160.0,
          140.0,
          100.0,
          50.0,
          20.0,
          15.0,
          15.0,
          16.0,
          60.0,
          120.0,
          160.0,
        ];

        for (int i = 0; i < profileAngles.length; i++) {
          samples.add(
            AngleSample(
              timestamp: now.add(Duration(milliseconds: i * 100)),
              angle: profileAngles[i],
              visibilityValid: true,
            ),
          );
        }

        final profile = analyzer.analyze(
          samples: samples,
          exerciseId: 'bicep_curl',
        );

        // Must NOT be clamped to 25.0
        expect(profile.targetAngle, closeTo(15.0, 2.0));
        expect(profile.isPlausible, isFalse);
        expect(profile.reviewPrompt, contains('Implausible target detected'));
      },
    );

    test('Moving median filter removes sporadic single-frame noise spikes', () {
      final now = DateTime.now();
      final List<AngleSample> samples = [];

      // Clean reps with sporadic single-frame tracking glitches
      final profileAngles = [
        160.0,
        160.0,
        160.0,
        160.0,
        160.0,
        160.0,
        160.0,
        160.0,
        160.0,
        160.0,
        155.0,
        130.0,
        10.0 /* GLITCH */,
        70.0,
        52.0,
        50.0,
        50.0,
        51.0,
        65.0,
        95.0,
        130.0,
        160.0,
        160.0,
        160.0,
        150.0,
        120.0,
        90.0,
        179.0 /* GLITCH */,
        53.0,
        50.0,
        50.0,
        52.0,
        70.0,
        110.0,
        145.0,
        160.0,
      ];

      for (int i = 0; i < profileAngles.length; i++) {
        samples.add(
          AngleSample(
            timestamp: now.add(Duration(milliseconds: i * 100)),
            angle: profileAngles[i],
            visibilityValid: true,
          ),
        );
      }

      final profile = analyzer.analyze(
        samples: samples,
        exerciseId: 'bicep_curl',
      );

      expect(profile.isPlausible, isTrue);
      expect(profile.targetAngle, closeTo(50.0, 2.0));
    });

    test('Clinician override works and marks profile as overridden', () {
      final baseProfile = analyzer.analyze(
        samples: [
          for (int i = 0; i < 20; i++)
            AngleSample(
              timestamp: DateTime.now().add(Duration(milliseconds: i * 100)),
              angle: 60.0,
            ),
        ],
        exerciseId: 'bicep_curl',
      );

      final overridden = baseProfile.copyWithOverride(75.0);
      expect(overridden.targetAngle, equals(75.0));
      expect(overridden.isClinicianOverride, isTrue);
      expect(
        overridden.reviewPrompt,
        contains('Clinician Override: Manually set to 75.0°'),
      );
    });
  });
}
