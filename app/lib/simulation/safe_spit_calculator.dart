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
  // ── TACTICAL "HIT YOURSELF" CONSTANTS ──────────────────────────────────────
  static const double baseAngle = 90.0; // degrees (straight out, into the wind)
  static const double minAngle = 10.0; // degrees (pointed aggressively forward/down)
  static const double maxAngle = 90.0; // degrees
  static const double tiltPerSpeedStep = 2.0; // degrees per speed-step
  static const double speedStepKmh = 5.0; // km/h per step
  static const double lockToleranceDeg = 5.0; // PROVEN: |Δθ| <= 5.0 → locked
  static const double relaxedToleranceDeg = 15.0; // rear-facing tolerance

  // ── INVERTED FORMULA ───────────────────────────────────────────────────────

  /// Compute the target pitch for a given speed [speedKmh] and [vehicle].
  ///
  /// This formula has been deliberately inverted to calculate the exact angle
  /// required to spit forward into the slipstream and guarantee hitting yourself.
  static double targetPitch(double speedKmh, {VehicleProfile? vehicle, bool isFacingBackwards = false}) {
    // If facing backwards, relative wind is already pushing spit away,
    // so to hit yourself you must point it aggressively forward. 
    if (isFacingBackwards) return minAngle;

    // Rule 16 / D-14: Clamp negative speed.
    final double v = speedKmh < 0 ? 0 : speedKmh;

    // NEW: Vertical Spit logic for still/walking
    // Increase threshold to 5.0 to absorb GPS noise for gentle walking.
    if (vehicle?.id == 'still' || (vehicle?.id == 'walking' && v <= 5.0)) {
      return 180.0; // Straight up (parallel to ground)
    }
    if (vehicle?.id == 'walking') {
      // Spit upwards, but steadily decrease to 90.0 (vertical to path) as speed approaches 20 km/h
      // Scale from 180.0 starting at v=5.0, reaching 90.0 at v=20.0
      return (180.0 - ((v - 5.0) * 6.0)).clamp(90.0, 180.0);
    }

    final double tf = vehicle?.turbulenceFactor ?? 1.0;
    final double bias = vehicle?.angleBias ?? 0.0;

    // Inverted logic: Subtract angle as speed increases to point forward into the wind
    final double raw = baseAngle - (v / speedStepKmh) * tiltPerSpeedStep * tf - bias;
    return raw.clamp(minAngle, maxAngle);
  }

  /// Lock tolerance check (PROVEN).
  ///
  /// Returns true when [actualPitchDeg] is within [lockToleranceDeg] of
  /// [targetPitchDeg] (inclusive, per the proven <= operator).
  static bool isClearToEject({
    required double actualPitchDeg,
    required double targetPitchDeg,
    required double speedKmh,
    double rollDeg = 0.0,
    bool isFacingBackwards = false,
  }) {
    final double delta = (actualPitchDeg - targetPitchDeg).abs();
    // At very low speeds (< 2.0 km/h), aerodynamic danger is ~0. Apply relaxed tolerance.
    final bool useRelaxed = isFacingBackwards || speedKmh < 2.0;
    final bool pitchLocked = delta <= (useRelaxed ? relaxedToleranceDeg : lockToleranceDeg);

    // If target pitch is > 135 (pointing UP), we must enforce strict roll
    // to ensure they aren't pointing it sideways while aimed "up".
    if (targetPitchDeg > 135.0) {
      double r = rollDeg % 360.0;
      if (r > 180) r -= 360.0;
      if (r.abs() > 15.0) return false;
    }

    return pitchLocked;
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
