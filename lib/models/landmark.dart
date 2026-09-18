// lib/models/landmark.dart
// Unified landmark and biomechanics data contracts

import 'enums.dart';

class Landmark {
  final double x;
  final double y;
  final double z;
  final double likelihood;

  const Landmark({
    required this.x,
    required this.y,
    this.z = 0.0,
    required this.likelihood,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'z': z,
    'likelihood': likelihood,
  };

  factory Landmark.fromJson(Map<String, dynamic> json) => Landmark(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    z: (json['z'] as num?)?.toDouble() ?? 0.0,
    likelihood: (json['likelihood'] as num).toDouble(),
  );
}

class PoseFrame {
  final DateTime timestamp;
  final Map<String, Landmark> landmarks;

  const PoseFrame({required this.timestamp, required this.landmarks});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'landmarks': landmarks.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory PoseFrame.fromJson(Map<String, dynamic> json) => PoseFrame(
    timestamp: DateTime.parse(json['timestamp'] as String),
    landmarks: (json['landmarks'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, Landmark.fromJson(v as Map<String, dynamic>)),
    ),
  );
}

class JointTriple {
  final String a; // First landmark (e.g. shoulder)
  final String b; // Joint vertex (e.g. elbow)
  final String c; // Third landmark (e.g. wrist)

  const JointTriple({required this.a, required this.b, required this.c});

  Map<String, dynamic> toJson() => {'a': a, 'b': b, 'c': c};

  factory JointTriple.fromJson(Map<String, dynamic> json) => JointTriple(
    a: json['a'] as String,
    b: json['b'] as String,
    c: json['c'] as String,
  );
}

class JointDefinition {
  final String primaryJoint;
  final BodySide bodySide;
  final JointTriple jointTriple;

  const JointDefinition({
    required this.primaryJoint,
    required this.bodySide,
    required this.jointTriple,
  });

  Map<String, dynamic> toJson() => {
    'primaryJoint': primaryJoint,
    'bodySide': bodySide.name,
    'jointTriple': jointTriple.toJson(),
  };

  factory JointDefinition.fromJson(Map<String, dynamic> json) =>
      JointDefinition(
        primaryJoint: json['primaryJoint'] as String,
        bodySide: BodySide.values.firstWhere(
          (e) => e.name == json['bodySide'],
          orElse: () => BodySide.auto,
        ),
        jointTriple: JointTriple.fromJson(
          json['jointTriple'] as Map<String, dynamic>,
        ),
      );
}

class BiomechanicsBounds {
  final double minPlausibleAngle;
  final double maxPlausibleAngle;
  final double targetMinAngle;
  final double targetMaxAngle;

  const BiomechanicsBounds({
    required this.minPlausibleAngle,
    required this.maxPlausibleAngle,
    required this.targetMinAngle,
    required this.targetMaxAngle,
  });

  bool isAnglePlausible(double angle) =>
      angle >= minPlausibleAngle && angle <= maxPlausibleAngle;

  bool isTargetPlausible(double targetAngle) =>
      targetAngle >= targetMinAngle && targetAngle <= targetMaxAngle;

  Map<String, dynamic> toJson() => {
    'minPlausibleAngle': minPlausibleAngle,
    'maxPlausibleAngle': maxPlausibleAngle,
    'targetMinAngle': targetMinAngle,
    'targetMaxAngle': targetMaxAngle,
  };

  factory BiomechanicsBounds.fromJson(Map<String, dynamic> json) =>
      BiomechanicsBounds(
        minPlausibleAngle: (json['minPlausibleAngle'] as num).toDouble(),
        maxPlausibleAngle: (json['maxPlausibleAngle'] as num).toDouble(),
        targetMinAngle: (json['targetMinAngle'] as num).toDouble(),
        targetMaxAngle: (json['targetMaxAngle'] as num).toDouble(),
      );
}

class AngleSample {
  final DateTime timestamp;
  final double angle;
  final bool visibilityValid;

  const AngleSample({
    required this.timestamp,
    required this.angle,
    this.visibilityValid = true,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'angle': angle,
    'visibilityValid': visibilityValid,
  };

  factory AngleSample.fromJson(Map<String, dynamic> json) => AngleSample(
    timestamp: DateTime.parse(json['timestamp'] as String),
    angle: (json['angle'] as num).toDouble(),
    visibilityValid: json['visibilityValid'] as bool? ?? true,
  );
}
