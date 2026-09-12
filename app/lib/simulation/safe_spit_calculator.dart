// safe_spit_calculator.dart — SAFE//SPIT
//
// PROVEN core simulation: preserved byte-for-behavior from the prototype.
// This is the canonical, pure Dart implementation of the target-pitch formula.
//
// RULE 2: No Flutter imports. This file is pure Dart.
// RULE 1: Any change to this formula requires a DECISIONS.md entry.
// RULE 16: Negative speed is clamped before the formula.
//
// Formula:
//   targetPitch(v) = clamp(v * 4.5, 0, 90)
//
// Test points (TV-01, TV-02, TV-03):
//   0 km/h → 0.0° (vertical)
//   10 km/h → 45.0°
//   20 km/h → 90.0° (clamp engaged)

/// PROVEN core calculator. Preserved from the prototype.
/// Pure function — no side effects, no imports beyond dart:math.
class SafeSpitCalculator {
  static const double minAngle = 0.0;
  static const double maxAngle = 90.0; // degrees
  static const double anglePerKmh = 4.5;
  static const double lockToleranceDeg = 5.0; // PROVEN: |Δθ| <= 5.0 → locked
  static const double relaxedToleranceDeg = 15.0; // rear-facing tolerance

  // ── INVERTED FORMULA ───────────────────────────────────────────────────────

  /// Compute the target pitch from the phone's current speed.
  ///
  /// Zero speed points vertically up. The target rises with speed and is
  /// constrained to the inclusive range [0, 90] degrees.
  static double targetPitch(double speedKmh, {bool isFacingBackwards = false}) {
    final double v = speedKmh < 0 ? 0 : speedKmh;
    return (v * anglePerKmh).clamp(minAngle, maxAngle);
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
    // For targets aiming near straight UP (pitch near 0) or straight DOWN (pitch near 180),
    // we enforce a strict roll tolerance.
    if (targetPitchDeg < 45.0 || targetPitchDeg > 135.0) {
      double r = rollDeg % 360.0;
      if (r > 180) r -= 360.0;
      
      // Roll could be ~0 (face up/upright) or ~180 (face down).
      // Check distance to 0 and distance to 180.
      final double distTo0 = r.abs();
      final double distTo180 = (r.abs() - 180.0).abs();
      if (distTo0 > 15.0 && distTo180 > 15.0) return false;
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
