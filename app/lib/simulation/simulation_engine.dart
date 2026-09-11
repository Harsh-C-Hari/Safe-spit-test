// simulation_engine.dart — SAFE//SPIT
//
// The top-level pure simulation function.
// Takes ScenarioInput → SimulationResult.
// RULE 2: No Flutter imports.
// RULE 11: Deterministic — same inputs always produce same output.

import 'safe_spit_calculator.dart';
import 'scenario.dart';
import 'trajectory_model.dart';

/// Run a complete simulation tick from a [ScenarioInput].
///
/// This is a pure function — no I/O, no side effects.
/// Suitable for unit testing, replay, and website parity.
SimulationResult simulate(ScenarioInput input) {
  final double baseTargetPitchDeg = SafeSpitCalculator.targetPitch(
    input.speedKmh,
    vehicle: input.vehicle,
    isFacingBackwards: input.isFacingBackwards,
  );

  final double targetPitchDeg = baseTargetPitchDeg;

  final double delta = SafeSpitCalculator.deltaDeg(
    actualPitchDeg: input.pitchDeg,
    targetPitchDeg: targetPitchDeg,
  );

  final bool locked = SafeSpitCalculator.isClearToEject(
    actualPitchDeg: input.pitchDeg,
    targetPitchDeg: targetPitchDeg,
    speedKmh: input.speedKmh,
    rollDeg: input.rollDeg,
    isFacingBackwards: input.isFacingBackwards,
  );

  // ── Lock quality (PLANNED) ──────────────────────────────────────────────
  final double lockTolerance = (input.isFacingBackwards || input.speedKmh < 2.0)
      ? SafeSpitCalculator.relaxedToleranceDeg 
      : SafeSpitCalculator.lockToleranceDeg;

  final double lockQuality = locked
      ? (1.0 - (delta / lockTolerance)).clamp(0.0, 1.0)
      : 0.0;

  // ── Wind deviation (PLANNED, D-5) ───────────────────────────────────────
  // Wind does NOT affect targetPitchDeg or isClearToEject (Rule 15).
  final double deviationM = computeWindDeviation(
    seed: input.seed,
    windSpeedKmh: input.windSpeedKmh,
    windDirectionDeg: input.windDirectionDeg,
    windSensitivity: input.vehicle.windSensitivity,
    targetDistanceM: input.targetDistanceM,
  );

  return SimulationResult(
    targetPitchDeg: targetPitchDeg,
    deltaDeg: delta,
    isClearToEject: locked,
    lockQuality: lockQuality,
    deviationM: deviationM,
  );
}
