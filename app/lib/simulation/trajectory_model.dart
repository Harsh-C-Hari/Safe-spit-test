// trajectory_model.dart — SAFE//SPIT
//
// PLANNED: trajectory and wind deviation calculations (Phase 4/5).
// RULE 2: No Flutter imports.
// RULE 11: Determinism — seeded, reproducible.
// RULE 15: Wind does NOT affect the lock (deltaDeg/isClearToEject).
//          Wind affects impactPosition/deviationM only (D-5, TV-09).

import 'dart:math' as math;

/// A 2D point for trajectory rendering and impact position.
class TrajectoryPoint {
  final double x; // horizontal offset (m)
  final double y; // vertical offset (m) — positive = up

  const TrajectoryPoint(this.x, this.y);

  @override
  String toString() => 'TrajectoryPoint($x, $y)';
}

/// Computes a simple parabolic trajectory arc for HUD visualization.
/// This is a fictional/display-only model — not real fluid dynamics.
///
/// Returns a list of [TrajectoryPoint] for rendering the arc overlay.
/// The list has [steps] points from launch to approximate impact.
List<TrajectoryPoint> computeTrajectoryArc({
  required double pitchDeg,
  required double speedKmh,
  int steps = 20,
}) {
  // Convert to radians
  final double pitchRad = pitchDeg * math.pi / 180.0;
  // Fictional initial speed (scaled from vehicle speed, not real physics)
  final double v0 = 2.0 + speedKmh * 0.01; // m/s fictional
  final double vx = v0 * math.cos(pitchRad);
  final double vy = v0 * math.sin(pitchRad);
  const double g = 9.8; // m/s² fictional gravity

  final List<TrajectoryPoint> points = [];
  final double tMax = (2.0 * vy) / g; // time to impact (fictional)
  for (int i = 0; i <= steps; i++) {
    final double t = (i / steps) * tMax;
    final double x = vx * t;
    final double y = vy * t - 0.5 * g * t * t;
    points.add(TrajectoryPoint(x, y));
  }
  return points;
}

/// Seeded pseudo-random number generator for deterministic scenario values.
/// Implements a simple xorshift32 — reproducible across Dart and TypeScript (D-11).
class ScenarioRng {
  int _state;

  ScenarioRng(String seed) : _state = _seedToInt(seed);

  static int _seedToInt(String seed) {
    // Treat the 6-char hex seed as a 24-bit integer, with a known salt.
    final hex = seed.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '0');
    final paddedHex = hex.padLeft(6, '0').substring(0, 6);
    return int.parse(paddedHex, radix: 16) + 1; // never 0
  }

  /// Next float in [0.0, 1.0).
  double nextDouble() {
    _state ^= _state << 13;
    _state ^= _state >> 17;
    _state ^= _state << 5;
    // Mask to 32-bit positive integer range
    _state = _state & 0x7FFFFFFF;
    return _state / 0x7FFFFFFF;
  }

  /// Next float in [min, max).
  double nextRange(double min, double max) => min + nextDouble() * (max - min);
}

/// Computes wind-induced lateral deviation at impact (PLANNED, D-5).
/// Wind does NOT affect targetPitchDeg or isClearToEject.
/// Returns deviation in metres — positive = rightward of target.
double computeWindDeviation({
  required String seed,
  required double windSpeedKmh,
  required double windDirectionDeg,
  required double windSensitivity,
  required double targetDistanceM,
}) {
  if (windSpeedKmh <= 0) return 0.0;

  final rng = ScenarioRng(seed);
  // Consume one value for turbulence variation (deterministic from seed)
  final turbulenceVariation = (rng.nextDouble() - 0.5) * 0.2;

  // Wind component perpendicular to launch direction (headingDeg=0 assumed for simplicity)
  final windRad = windDirectionDeg * math.pi / 180.0;
  final lateralWind = windSpeedKmh * math.sin(windRad);

  // Fictional deviation formula — proportional to lateral wind, distance, and sensitivity
  final deviation = lateralWind * windSensitivity * (targetDistanceM / 50.0) * 0.05;
  return deviation * (1.0 + turbulenceVariation);
}
