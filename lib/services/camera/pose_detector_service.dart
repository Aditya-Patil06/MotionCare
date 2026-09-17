import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../models/landmark.dart';

class PoseDetectorService {
  late final PoseDetector _detector;
  bool _isProcessingFrame = false;

  PoseDetectorService({PoseDetectionModel model = PoseDetectionModel.base}) {
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        model: model,
        mode: PoseDetectionMode.stream,
      ),
    );
  }

  bool get isProcessing => _isProcessingFrame;

  /// Processes one camera frame sequentially.
  /// Section 6.1: Drops incoming frames if previous frame is still processing.
  Future<Map<String, Landmark>?> processCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (_isProcessingFrame) {
      // Drop frame to prevent latency buildup
      return null;
    }

    _isProcessingFrame = true;
    try {
      final inputImage = _convertCameraImageToInputImage(image, camera);
      if (inputImage == null) return null;

      final List<Pose> poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) {
        return <String, Landmark>{};
      }

      return _mapPoseToLandmarks(poses.first);
    } catch (e) {
      debugPrint('ML Kit Pose Detection frame error: $e');
      return null;
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Processes an InputImage directly (e.g. from reference video or static frame)
  Future<Map<String, Landmark>?> processInputImage(InputImage inputImage) async {
    try {
      final List<Pose> poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) return <String, Landmark>{};
      return _mapPoseToLandmarks(poses.first);
    } catch (e) {
      debugPrint('ML Kit processInputImage error: $e');
      return null;
    }
  }

  Map<String, Landmark> _mapPoseToLandmarks(Pose pose) {
    final Map<String, Landmark> result = {};

    void addLandmark(String key, PoseLandmarkType type) {
      final lm = pose.landmarks[type];
      if (lm != null) {
        result[key] = Landmark(
          x: lm.x,
          y: lm.y,
          z: lm.z,
          likelihood: lm.likelihood,
        );
      }
    }

    addLandmark('left_shoulder', PoseLandmarkType.leftShoulder);
    addLandmark('right_shoulder', PoseLandmarkType.rightShoulder);
    addLandmark('left_elbow', PoseLandmarkType.leftElbow);
    addLandmark('right_elbow', PoseLandmarkType.rightElbow);
    addLandmark('left_wrist', PoseLandmarkType.leftWrist);
    addLandmark('right_wrist', PoseLandmarkType.rightWrist);
    addLandmark('left_hip', PoseLandmarkType.leftHip);
    addLandmark('right_hip', PoseLandmarkType.rightHip);
    addLandmark('left_knee', PoseLandmarkType.leftKnee);
    addLandmark('right_knee', PoseLandmarkType.rightKnee);
    addLandmark('left_ankle', PoseLandmarkType.leftAnkle);
    addLandmark('right_ankle', PoseLandmarkType.rightAnkle);

    return result;
  }

  InputImage? _convertCameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    try {
      final sensorOrientation = camera.sensorOrientation;
      final imageRotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        // Fallback for NV21 on Android
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: imageRotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Camera image conversion error: $e');
      return null;
    }
  }

  void dispose() {
    _detector.close();
  }
}
