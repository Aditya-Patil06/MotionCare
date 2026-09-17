// lib/ai/visibility/visibility_tracker.dart
// Specification v7 Section 12: Visibility System with Hysteresis.
// 5 consecutive failing frames -> visibility failure
// 3 consecutive passing frames -> visibility restored

import '../../models/enums.dart';
import '../../models/landmark.dart';

class VisibilityResult {
  final bool isValid;
  final int consecutiveFailCount;
  final int consecutivePassCount;
  final List<String> missingLandmarks;
  final List<String> lowConfidenceLandmarks;
  final List<String> outOfBoundsLandmarks;
  final IssueCode issueCode;

  const VisibilityResult({
    required this.isValid,
    required this.consecutiveFailCount,
    required this.consecutivePassCount,
    this.missingLandmarks = const [],
    this.lowConfidenceLandmarks = const [],
    this.outOfBoundsLandmarks = const [],
    this.issueCode = IssueCode.none,
  });
}

class VisibilityTracker {
  final double confidenceThreshold;
  final int failThreshold;
  final int passThreshold;
  final double? imageWidth;
  final double? imageHeight;

  bool _isCurrentlyValid = false;
  int _consecutiveFails = 0;
  int _consecutivePasses = 0;

  VisibilityTracker({
    this.confidenceThreshold = 0.60,
    this.failThreshold = 5,
    this.passThreshold = 3,
    this.imageWidth,
    this.imageHeight,
    bool initialValidState = false,
  }) : _isCurrentlyValid = initialValidState;

  bool get isCurrentlyValid => _isCurrentlyValid;
  int get consecutiveFails => _consecutiveFails;
  int get consecutivePasses => _consecutivePasses;

  void reset({bool initialValid = false}) {
    _isCurrentlyValid = initialValid;
    _consecutiveFails = 0;
    _consecutivePasses = 0;
  }

  /// Evaluates visibility for the given [landmarks] against the [requiredLandmarkKeys].
  VisibilityResult evaluate({
    required Map<String, Landmark> landmarks,
    required List<String> requiredLandmarkKeys,
  }) {
    final List<String> missing = [];
    final List<String> lowConfidence = [];
    final List<String> outOfBounds = [];

    for (final key in requiredLandmarkKeys) {
      final lm = landmarks[key];
      if (lm == null) {
        missing.add(key);
        continue;
      }

      // Confidence check
      if (lm.likelihood < confidenceThreshold) {
        lowConfidence.add(key);
      }

      // Bounds check
      if (imageWidth != null && imageHeight != null) {
        // Pixel coordinates check
        if (lm.x < 0 || lm.x > imageWidth! || lm.y < 0 || lm.y > imageHeight!) {
          outOfBounds.add(key);
        }
      } else {
        // Normalized 0.0 - 1.0 coordinates check if within standard unit range
        if (lm.x < 0.0 || lm.x > 1.0 || lm.y < 0.0 || lm.y > 1.0) {
          // If coordinates are clearly pixel values (e.g. > 10.0), don't falsely reject
          if (lm.x < 0.0 || lm.y < 0.0) {
            outOfBounds.add(key);
          }
        }
      }
    }

    final bool framePassed =
        missing.isEmpty && lowConfidence.isEmpty && outOfBounds.isEmpty;

    if (framePassed) {
      _consecutiveFails = 0;
      _consecutivePasses++;
      if (_consecutivePasses >= passThreshold) {
        _isCurrentlyValid = true;
      }
    } else {
      _consecutivePasses = 0;
      _consecutiveFails++;
      if (_consecutiveFails >= failThreshold) {
        _isCurrentlyValid = false;
      }
    }

    return VisibilityResult(
      isValid: _isCurrentlyValid,
      consecutiveFailCount: _consecutiveFails,
      consecutivePassCount: _consecutivePasses,
      missingLandmarks: missing,
      lowConfidenceLandmarks: lowConfidence,
      outOfBoundsLandmarks: outOfBounds,
      issueCode: _isCurrentlyValid
          ? IssueCode.none
          : IssueCode.insufficientVisibility,
    );
  }
}
