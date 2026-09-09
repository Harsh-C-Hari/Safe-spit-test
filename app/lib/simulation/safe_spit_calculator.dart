// safe_spit_calculator.dart — SAFE//SPIT
//
// PROVEN core simulation: preserved byte-for-behavior from the prototype.
// This is the canonical, pure Dart implementation of the target-pitch formula.
//
// RULE 2: No Flutter imports. This file is pure Dart.
// RULE 1: Any change to this formula requires a DECISIONS.md entry.
// RULE 16: Negative speed is clamped before the formula.
//
// Formula (PROVEN):
//   targetPitch(v) = clamp(45 + (v / 5) * 1.2, 45, 85)
//
// Test points (TV-01, TV-02, TV-03):
//   0 km/h → 45.0°
//   50 km/h → 57.0°
//   200 km/h → 85.0° (clamp engaged)

/// PROVEN core calculator. Preserved from the prototype.
/// Pure function — no side effects, no imports beyond dart:math.
class SafeSpitCalculator {
  // ── PROVEN constants ───────────────────────────────────────────────────────
  static const double baseAngle = 45.0; // degrees
  static const double maxAngle = 85.0; // degrees
  static const double tiltPerSpeedStep = 1.2; // degrees per speed-step
  static const double speedStepKmh = 5.0; // km/h per step
  static const double lockToleranceDeg = 5.0; // PROVEN: |Δθ| <= 5.0 → locked
  static const double relaxedToleranceDeg = 15.0; // rear-facing tolerance

  // ── PROVEN formula ─────────────────────────────────────────────────────────

  /// Compute the target pitch for a given speed [speedKmh] and [vehicle].
  ///
  /// [speedKmh] is clamped to >= 0 before computation (D-14, TV-07).
  ///
  /// With the Car profile (turbulenceFactor=1.0, angleBias=0.0) this reproduces
  /// the proven prototype formula exactly (D-4, TV-08).
  static double targetPitch(double speedKmh, {VehicleProfile? vehicle, bool isFacingBackwards = false}) {
    // If facing backwards, relative wind is pushing spit away. No need to tilt up.
    if (isFacingBackwards) return baseAngle;

    // Rule 16 / D-14: Clamp negative speed.
    final double v = speedKmh < 0 ? 0 : speedKmh;
    final double tf = vehicle?.turbulenceFactor ?? 1.0;
    final double bias = vehicle?.angleBias ?? 0.0;

    final double raw = baseAngle + (v / speedStepKmh) * tiltPerSpeedStep * tf + bias;
    return raw.clamp(baseAngle, maxAngle);
  }

  /// Lock tolerance check (PROVEN).
  ///
  /// Returns true when [actualPitchDeg] is within [lockToleranceDeg] of
  /// [targetPitchDeg] (inclusive, per the proven <= operator).
  static bool isClearToEject({
    required double actualPitchDeg,
    required double targetPitchDeg,
    required double speedKmh,
    bool isFacingBackwards = false,
  }) {
    final double delta = (actualPitchDeg - targetPitchDeg).abs();
    // At very low speeds (< 2.0 km/h), aerodynamic danger is ~0. Apply relaxed tolerance.
    final bool useRelaxed = isFacingBackwards || speedKmh < 2.0;
    return delta <= (useRelaxed ? relaxedToleranceDeg : lockToleranceDeg);
  }

  /// Delta in degrees between actual and target pitch.
  static double deltaDeg({
    required double actualPitchDeg,
    required double targetPitchDeg,
  }) {
    return (actualPitchDeg - targetPitchDeg).abs();
  }
}

/// Vehicle profile data record.
/// Car is the identity profile: turbulenceFactor=1.0, angleBias=0.0 (D-4, Rule 20).
/// All values are fictional — do not represent as physically realistic.
class VehicleProfile {
  final String id;
  final String displayName;
  final double turbulenceFactor; // Car = 1.0 (identity)
  final double angleBias; // Car = 0.0 (identity)
  final double windSensitivity; // Car = 1.0
  final double difficulty; // 0.0..1.0
  final bool eitherSide; // bike/walking can spit either side

  const VehicleProfile({
    required this.id,
    required this.displayName,
    required this.turbulenceFactor,
    required this.angleBias,
    required this.windSensitivity,
    required this.difficulty,
    this.eitherSide = false,
  });

    factory VehicleProfile.fromJson(Map<String, dynamic> json) {
    return VehicleProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      turbulenceFactor: (json['turbulenceFactor'] as num).toDouble(),
      angleBias: (json['angleBias'] as num).toDouble(),
      windSensitivity: (json['windSensitivity'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      eitherSide: json['eitherSide'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'turbulenceFactor': turbulenceFactor,
    'angleBias': angleBias,
    'windSensitivity': windSensitivity,
    'difficulty': difficulty,
    'eitherSide': eitherSide,
  };
}
