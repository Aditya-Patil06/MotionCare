// test/ai/fixture_runner_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motioncare/ai/holds/shoulder_hold_engine.dart';
import 'package:motioncare/ai/reference/reference_analyzer.dart';
import 'package:motioncare/ai/summary/session_summary_generator.dart';
import 'package:motioncare/exercises/bicep_curl/bicep_curl_rule.dart';
import 'package:motioncare/models/enums.dart';
import 'package:motioncare/models/landmark.dart';
import 'package:motioncare/models/movement_event.dart';
import 'package:motioncare/models/reference_profile.dart';

void main() {
  group('Specification v7 Section 38 Fixture Test Suite', () {
    test('curl_correct_3reps.json verifies clean 3-rep sequence', () {
      final file = File('test/fixtures/curl_correct_3reps.json');
      final data = jsonDecode(file.readAsStringSync());

      final rule = BicepCurlRule(preferredSide: BodySide.right);
      final profile = ReferenceProfile(
        exerciseId: data['exerciseId'],
        targetAngle: (data['targetAngle'] as num).toDouble(),
        tolerance: (data['tolerance'] as num).toDouble(),
        confidence: 0.95,
      );

      final now = DateTime.now();
      for (final frame in data['frames']) {
        final double angle = (frame['angle'] as num).toDouble();
        final bool vis = frame['visibility'] as bool;
        final int ms = frame['timestampMs'] as int;

        // Feed sample to rule rep engine directly
        rule.repEngine.processSample(
          currentAngle: angle,
          profile: profile,
          isVisibilityValid: vis,
          timestamp: now.add(Duration(milliseconds: ms)),
        );
      }

      expect(rule.repEngine.validReps, equals(data['expected']['validReps']));
      expect(
        rule.repEngine.invalidAttempts,
        equals(data['expected']['invalidAttempts']),
      );
      expect(rule.repEngine.phase.name, equals(data['expected']['finalPhase']));
    });

    test('curl_incomplete.json flags incomplete rep without incrementing valid reps', () {
      final file = File('test/fixtures/curl_incomplete.json');
      final data = jsonDecode(file.readAsStringSync());

      final rule = BicepCurlRule(preferredSide: BodySide.right);
      final profile = ReferenceProfile(
        exerciseId: data['exerciseId'],
        targetAngle: (data['targetAngle'] as num).toDouble(),
        tolerance: (data['tolerance'] as num).toDouble(),
        confidence: 0.95,
      );

      final now = DateTime.now();
      for (final frame in data['frames']) {
        final double angle = (frame['angle'] as num).toDouble();
        final bool vis = frame['visibility'] as bool;
        final int ms = frame['timestampMs'] as int;

        rule.repEngine.processSample(
          currentAngle: angle,
          profile: profile,
          isVisibilityValid: vis,
          timestamp: now.add(Duration(milliseconds: ms)),
        );
      }

      expect(rule.repEngine.validReps, equals(data['expected']['validReps']));
      expect(
        rule.repEngine.invalidAttempts,
        equals(data['expected']['invalidAttempts']),
      );
      expect(
        rule.repEngine.lastIssueCode.name,
        equals(data['expected']['issueCode']),
      );
    });

    test('curl_overshoot.json captures overshoot issue', () {
      final file = File('test/fixtures/curl_overshoot.json');
      final data = jsonDecode(file.readAsStringSync());

      final rule = BicepCurlRule(preferredSide: BodySide.right);
      final profile = ReferenceProfile(
        exerciseId: data['exerciseId'],
        targetAngle: (data['targetAngle'] as num).toDouble(),
        tolerance: (data['tolerance'] as num).toDouble(),
        confidence: 0.95,
      );

      final now = DateTime.now();
      for (final frame in data['frames']) {
        final double angle = (frame['angle'] as num).toDouble();
        final bool vis = frame['visibility'] as bool;
        final int ms = frame['timestampMs'] as int;

        rule.repEngine.processSample(
          currentAngle: angle,
          profile: profile,
          isVisibilityValid: vis,
          timestamp: now.add(Duration(milliseconds: ms)),
        );
      }

      expect(rule.repEngine.validReps, equals(data['expected']['validReps']));
      expect(
        rule.repEngine.invalidAttempts,
        equals(data['expected']['invalidAttempts']),
      );
      expect(
        rule.repEngine.lastIssueCode.name,
        equals(data['expected']['issueCode']),
      );
    });

    test('curl_visibility_loss.json ensures visibility drop does not penalize patient', () {
      final file = File('test/fixtures/curl_visibility_loss.json');
      final data = jsonDecode(file.readAsStringSync());

      final rule = BicepCurlRule(preferredSide: BodySide.right);
      final profile = ReferenceProfile(
        exerciseId: data['exerciseId'],
        targetAngle: (data['targetAngle'] as num).toDouble(),
        tolerance: (data['tolerance'] as num).toDouble(),
        confidence: 0.95,
      );

      final now = DateTime.now();
      bool sawInsufficientVisibility = false;

      for (final frame in data['frames']) {
        final double angle = (frame['angle'] as num).toDouble();
        final bool vis = frame['visibility'] as bool;
        final int ms = frame['timestampMs'] as int;

        rule.repEngine.processSample(
          currentAngle: angle,
          profile: profile,
          isVisibilityValid: vis,
          timestamp: now.add(Duration(milliseconds: ms)),
        );

        if (rule.repEngine.lastIssueCode == IssueCode.insufficientVisibility) {
          sawInsufficientVisibility = true;
        }
      }

      expect(rule.repEngine.validReps, equals(data['expected']['validReps']));
      expect(
        rule.repEngine.invalidAttempts,
        equals(data['expected']['invalidAttempts']),
      );
      expect(sawInsufficientVisibility, isTrue);
    });

    test('curl_reference_doctor.json extracts target angle accurately with high confidence', () {
      final file = File('test/fixtures/curl_reference_doctor.json');
      final data = jsonDecode(file.readAsStringSync());

      final analyzer = const ReferenceAnalyzer(
        bounds: BiomechanicsBounds(
          minPlausibleAngle: 20.0,
          maxPlausibleAngle: 180.0,
          targetMinAngle: 25.0,
          targetMaxAngle: 110.0,
        ),
      );

      final now = DateTime.now();
      final List<AngleSample> samples = [];
      for (final frame in data['frames']) {
        samples.add(
          AngleSample(
            timestamp: now.add(
              Duration(milliseconds: frame['timestampMs'] as int),
            ),
            angle: (frame['angle'] as num).toDouble(),
            visibilityValid: frame['visibility'] as bool,
          ),
        );
      }

      final profile = analyzer.analyze(
        samples: samples,
        exerciseId: data['exerciseId'],
      );

      expect(
        profile.targetAngle,
        closeTo(data['expected']['extractedTargetApprox'], 2.0),
      );
      expect(
        profile.confidence,
        greaterThanOrEqualTo(data['expected']['minConfidence']),
      );
      expect(profile.isPlausible, equals(data['expected']['isPlausible']));
    });

    test('curl_noisy_short.json triggers low confidence rejection/review', () {
      final file = File('test/fixtures/curl_noisy_short.json');
      final data = jsonDecode(file.readAsStringSync());

      final analyzer = const ReferenceAnalyzer(
        bounds: BiomechanicsBounds(
          minPlausibleAngle: 20.0,
          maxPlausibleAngle: 180.0,
          targetMinAngle: 25.0,
          targetMaxAngle: 110.0,
        ),
      );

      final now = DateTime.now();
      final List<AngleSample> samples = [];
      for (final frame in data['frames']) {
        samples.add(
          AngleSample(
            timestamp: now.add(
              Duration(milliseconds: frame['timestampMs'] as int),
            ),
            angle: (frame['angle'] as num).toDouble(),
            visibilityValid: frame['visibility'] as bool,
          ),
        );
      }

      final profile = analyzer.analyze(
        samples: samples,
        exerciseId: data['exerciseId'],
      );

      expect(
        profile.confidence,
        lessThanOrEqualTo(data['expected']['maxConfidence']),
      );
      expect(profile.isPlausible, equals(data['expected']['isPlausible']));
      expect(profile.reviewPrompt, contains('Re-recording required'));
    });

    test('hold_correct_pause_resume.json handles hold accumulation and pause/resume', () {
      final file = File('test/fixtures/hold_correct_pause_resume.json');
      final data = jsonDecode(file.readAsStringSync());

      final engine = ShoulderHoldEngine(
        targetHoldSeconds: (data['targetHoldSeconds'] as num).toDouble(),
      );

      for (final tick in data['ticks']) {
        final double dur = (tick['durationSeconds'] as num).toDouble();
        final aiState = AiState.values.firstWhere(
          (e) => e.name == tick['aiState'],
        );
        final issue = IssueCode.values.firstWhere(
          (e) => e.name == tick['issueCode'],
        );

        engine.processTick(
          aiState: aiState,
          issueCode: issue,
          deltaSeconds: dur,
        );
      }

      expect(
        engine.correctHoldSeconds,
        equals(data['expected']['correctHoldSeconds']),
      );
      expect(
        engine.incorrectHoldSeconds,
        equals(data['expected']['incorrectHoldSeconds']),
      );
      expect(
        engine.postureBreakCount,
        equals(data['expected']['postureBreaks']),
      );
      expect(engine.recoveryCount, equals(data['expected']['recoveries']));
      expect(engine.isCompleted, equals(data['expected']['isCompleted']));
    });

    test('session_summary_mixed_events.json matches summary calculations', () {
      final file = File('test/fixtures/session_summary_mixed_events.json');
      final data = jsonDecode(file.readAsStringSync());

      final List<RepEvent> reps = [];
      final now = DateTime.now();
      for (final r in data['reps']) {
        reps.add(
          RepEvent(
            repIndex: r['repIndex'] as int,
            isValid: r['isValid'] as bool,
            peakAngle: (r['peakAngle'] as num).toDouble(),
            targetAngle: (r['targetAngle'] as num).toDouble(),
            issueCode: IssueCode.values.firstWhere(
              (e) => e.name == r['issueCode'],
            ),
            timestamp: now,
          ),
        );
      }

      final summary = SessionSummaryGenerator.generate(
        sessionId: data['sessionId'],
        planId: data['planId'],
        patientId: data['patientId'],
        exerciseName: data['exerciseName'],
        exerciseType: ExerciseType.values.firstWhere(
          (e) => e.name == data['exerciseType'],
        ),
        prescribedReps: data['prescribedReps'] as int,
        validReps: data['expected']['validReps'] as int,
        invalidAttempts: data['expected']['invalidAttempts'] as int,
        targetHoldSeconds: 0.0,
        correctHoldSeconds: 0.0,
        incorrectHoldSeconds: 0.0,
        visibilityLossSeconds: (data['visibilityLossSeconds'] as num)
            .toDouble(),
        events: const [],
        repEvents: reps,
      );

      expect(summary.validReps, equals(data['expected']['validReps']));
      expect(
        summary.invalidAttempts,
        equals(data['expected']['invalidAttempts']),
      );
      expect(summary.accuracyPercentage, equals(data['expected']['accuracy']));
      expect(summary.commonIssue.name, equals(data['expected']['commonIssue']));
    });
  });
}
