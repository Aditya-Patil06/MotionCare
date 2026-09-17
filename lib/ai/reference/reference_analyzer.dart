// lib/ai/reference/reference_analyzer.dart
// Specification v7 Section 15 & 16: Biomechanical Reference Analyzer
// 10 FPS sampling, median smoothing (w=5), prominence peak detection, confidence scoring, plausibility rejection.

import 'dart:math' as math;
import '../../models/enums.dart';
import '../../models/landmark.dart';
import '../../models/reference_profile.dart';

class ReferenceAnalyzer {
  final BiomechanicsBounds bounds;
  final double prominenceThreshold;
  final double minPeakSeparationSeconds;
  final double peakWindowDegrees;
  final int minSamplesInPeakWindow;

  const ReferenceAnalyzer({
    required this.bounds,
    this.prominenceThreshold = 30.0,
    this.minPeakSeparationSeconds = 0.6,
    this.peakWindowDegrees = 8.0,
    this.minSamplesInPeakWindow = 3,
  });

  /// Analyzes a time-series of angle samples extracted from reference video or live recording.
  ReferenceProfile analyze({
    required List<AngleSample> samples,
    required String exerciseId,
    BodySide bodySide = BodySide.right,
    ExtractionMethod extractionMethod = ExtractionMethod.videoFile,
  }) {
    if (samples.isEmpty) {
      return ReferenceProfile(
        exerciseId: exerciseId,
        targetAngle: 90.0,
        tolerance: 12.0,
        confidence: 0.0,
        isPlausible: false,
        reviewPrompt: 'Re-recording required: No angle samples available.',
        bodySide: bodySide,
        extractionMethod: extractionMethod,
        qualityMetadata: {'sampleCount': 0},
      );
    }

    // 1. Calculate raw visibility ratio
    final int visibleCount = samples.where((s) => s.visibilityValid).length;
    final double visibilityRatio = visibleCount / samples.length;

    // 2. Filter valid visibility samples
    final List<AngleSample> validSamples =
        samples.where((s) => s.visibilityValid).toList();

    if (validSamples.length < 10) {
      return ReferenceProfile(
        exerciseId: exerciseId,
        targetAngle: 90.0,
        tolerance: 12.0,
        confidence: 0.1,
        isPlausible: false,
        reviewPrompt:
            'Re-recording required: Insufficient valid visibility samples (${validSamples.length} frames).',
        bodySide: bodySide,
        extractionMethod: extractionMethod,
        qualityMetadata: {
          'totalSamples': samples.length,
          'validSamples': validSamples.length,
          'visibilityRatio': visibilityRatio,
        },
      );
    }

    // 3. Trim initial 1 second (approximately first 10 frames at 10 FPS)
    final DateTime startTime = validSamples.first.timestamp;
    final List<AngleSample> trimmedSamples = validSamples.where((s) {
      final elapsed = s.timestamp.difference(startTime).inMilliseconds / 1000.0;
      return elapsed >= 1.0;
    }).toList();

    final List<AngleSample> workingSeries =
        trimmedSamples.length >= 10 ? trimmedSamples : validSamples;

    // 4. Median Smoothing (Window size = 5)
    final List<double> smoothedAngles = _applyMovingMedian(
      workingSeries.map((s) => s.angle).toList(),
      windowSize: 5,
    );

    // 5. Peak Detection (Finding minimum elbow angle for bicep curl)
    final List<int> peakIndices = _detectPeaks(
      workingSeries,
      smoothedAngles,
      prominence: prominenceThreshold,
      minSeparationSeconds: minPeakSeparationSeconds,
    );

    // 6. Validate peaks with peak window (±8°) and extract representative angles
    final List<double> validPeakAngles = [];
    for (final idx in peakIndices) {
      final double peakAngle = smoothedAngles[idx];
      final double windowMin = peakAngle - peakWindowDegrees;
      final double windowMax = peakAngle + peakWindowDegrees;

      final windowSamples = smoothedAngles.where(
        (a) => a >= windowMin && a <= windowMax,
      ).toList();

      if (windowSamples.length >= minSamplesInPeakWindow) {
        windowSamples.sort();
        final double representative = windowSamples[windowSamples.length ~/ 2];
        validPeakAngles.add(representative);
      }
    }

    // 7. Determine Target Angle
    double extractedTarget;
    bool hasValidPeaks = validPeakAngles.isNotEmpty;

    if (hasValidPeaks) {
      validPeakAngles.sort();
      extractedTarget = validPeakAngles[validPeakAngles.length ~/ 2];
    } else {
      // Fallback: Use minimum angle observed if significant range, else median
      final sortedAll = List<double>.from(smoothedAngles)..sort();
      final double minObserved = sortedAll.first;
      final double maxObserved = sortedAll.last;
      if (maxObserved - minObserved >= prominenceThreshold) {
        extractedTarget = minObserved;
      } else {
        extractedTarget = sortedAll[sortedAll.length ~/ 2];
      }
    }

    // 8. Plausibility Check (Section 11: Do NOT clamp! Reject implausible targets!)
    final bool isPlausible = bounds.isTargetPlausible(extractedTarget);

    // 9. Calculate Confidence Factors (Section 16)
    // Visibility weight: 0.25
    final double wVisibility = (visibilityRatio).clamp(0.0, 1.0) * 0.25;

    // Sample count weight: 0.15 (ideal >= 50 samples)
    final double wSampleCount =
        (workingSeries.length / 50.0).clamp(0.0, 1.0) * 0.15;

    // Movement completeness weight: 0.25 (at least 1 valid detected rep with prominence)
    final double wCompleteness = hasValidPeaks
        ? (validPeakAngles.length >= 2 ? 1.0 : 0.75) * 0.25
        : 0.10 * 0.25;

    // Peak stability weight: 0.20
    double peakStability = 0.5;
    if (validPeakAngles.length >= 2) {
      final double mean =
          validPeakAngles.reduce((a, b) => a + b) / validPeakAngles.length;
      final double variance = validPeakAngles
              .map((a) => math.pow(a - mean, 2))
              .reduce((a, b) => a + b) /
          validPeakAngles.length;
      final double stdDev = math.sqrt(variance);
      // Low stdDev (<5°) means high stability
      peakStability = (1.0 - (stdDev / 15.0)).clamp(0.0, 1.0);
    } else if (hasValidPeaks) {
      peakStability = 0.8;
    } else {
      peakStability = 0.2;
    }
    final double wStability = peakStability * 0.20;

    // Plausibility weight: 0.15
    final double wPlausibility = (isPlausible ? 1.0 : 0.0) * 0.15;

    final double totalConfidence = (wVisibility +
            wSampleCount +
            wCompleteness +
            wStability +
            wPlausibility)
        .clamp(0.0, 1.0);

    // Routing Prompt (Section 16)
    String prompt;
    if (!isPlausible) {
      prompt =
          'Implausible target detected (${extractedTarget.toStringAsFixed(1)}°). Range must be ${bounds.targetMinAngle.toStringAsFixed(0)}° - ${bounds.targetMaxAngle.toStringAsFixed(0)}°. Clinician review or override required.';
    } else if (totalConfidence >= 0.70) {
      prompt =
          'Acceptable extraction confidence (${(totalConfidence * 100).toStringAsFixed(0)}%). Clinician confirmation required.';
    } else if (totalConfidence >= 0.40) {
      prompt =
          'Moderate extraction confidence (${(totalConfidence * 100).toStringAsFixed(0)}%). Review or re-recording recommended.';
    } else {
      prompt =
          'Low extraction confidence (${(totalConfidence * 100).toStringAsFixed(0)}%). Re-recording strongly recommended.';
    }

    return ReferenceProfile(
      exerciseId: exerciseId,
      targetAngle: double.parse(extractedTarget.toStringAsFixed(1)),
      tolerance: 12.0,
      confidence: double.parse(totalConfidence.toStringAsFixed(2)),
      isPlausible: isPlausible,
      reviewPrompt: prompt,
      bodySide: bodySide,
      extractionMethod: extractionMethod,
      qualityMetadata: {
        'totalRawSamples': samples.length,
        'validSamples': validSamples.length,
        'visibilityRatio': visibilityRatio,
        'detectedRepCount': validPeakAngles.length,
        'detectedPeakAngles': validPeakAngles,
        'confidenceBreakdown': {
          'visibility': wVisibility,
          'sampleCount': wSampleCount,
          'completeness': wCompleteness,
          'stability': wStability,
          'plausibility': wPlausibility,
        },
      },
    );
  }

  /// Moving median smoothing over [windowSize]
  List<double> _applyMovingMedian(List<double> data, {int windowSize = 5}) {
    if (data.length < windowSize) return List<double>.from(data);

    final List<double> result = List<double>.from(data);
    final int half = windowSize ~/ 2;

    for (int i = half; i < data.length - half; i++) {
      final List<double> window = data.sublist(i - half, i + half + 1);
      window.sort();
      result[i] = window[half];
    }
    return result;
  }

  /// Detects peaks (local minima for curl flexion) with prominence and separation constraints
  List<int> _detectPeaks(
    List<AngleSample> samples,
    List<double> angles, {
    required double prominence,
    required double minSeparationSeconds,
  }) {
    final List<int> peaks = [];
    if (angles.length < 3) return peaks;

    // Identify local minima
    for (int i = 1; i < angles.length - 1; i++) {
      final double curr = angles[i];
      final double prev = angles[i - 1];
      final double next = angles[i + 1];

      // Local minimum condition
      if (curr <= prev && curr <= next) {
        // Check baseline prominence: Look backward and forward for maxima
        double leftMax = curr;
        for (int l = i - 1; l >= 0; l--) {
          if (angles[l] > leftMax) leftMax = angles[l];
        }
        double rightMax = curr;
        for (int r = i + 1; r < angles.length; r++) {
          if (angles[r] > rightMax) rightMax = angles[r];
        }

        final double currentProminence =
            math.min(leftMax - curr, rightMax - curr);

        if (currentProminence >= prominence) {
          // Check separation from last detected peak
          if (peaks.isNotEmpty) {
            final int lastIdx = peaks.last;
            final double elapsed = samples[i]
                    .timestamp
                    .difference(samples[lastIdx].timestamp)
                    .inMilliseconds /
                1000.0;
            if (elapsed < minSeparationSeconds) {
              // If too close, keep the deeper minimum
              if (curr < angles[lastIdx]) {
                peaks[peaks.length - 1] = i;
              }
              continue;
            }
          }
          peaks.add(i);
        }
      }
    }
    return peaks;
  }
}
