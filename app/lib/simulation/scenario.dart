// scenario.dart — SAFE//SPIT
//
// PLANNED: ScenarioInput and SimulationResult types (Phase 4).
// These are the cross-platform contract types validated by shared-spec/test-vectors.json.
//
// RULE 2: No Flutter imports.
// RULE 11: No DateTime.now(), no Random() — determinism is a feature.

import 'safe_spit_calculator.dart';

/// Input to a single simulation run. Fully determines the output.
/// Corresponds to shared-spec/scenario.schema.json.
class ScenarioInput {
  final String schemaVersion;
  final String seed; // 6-char uppercase hex (D-19)
  final VehicleProfile vehicle;
  final double speedKmh;
  final double pitchDeg; // actualPitchDeg from sensor abstraction
  final double rollDeg;
  final double yawDeg;
  final double headingDeg;
  final double windSpeedKmh;
  final double windDirectionDeg;
  final double targetDistanceM;
  final String mode; // 'precision', 'crosswind', 'target_strike', etc.

  const ScenarioInput({
    this.schemaVersion = '0.1.0',
    required this.seed,
    required this.vehicle,
    required this.speedKmh,
    required this.pitchDeg,
    this.rollDeg = 0.0,
    this.yawDeg = 0.0,
    this.headingDeg = 0.0,
    this.windSpeedKmh = 0.0,
    this.windDirectionDeg = 0.0,
    this.targetDistanceM = 50.0,
    this.mode = 'precision',
  });

  factory ScenarioInput.fromJson(Map<String, dynamic> json) {
    return ScenarioInput(
      schemaVersion: json['schemaVersion'] as String? ?? '0.1.0',
      seed: json['seed'] as String,
      vehicle: VehicleProfile.fromJson(json['vehicle'] as Map<String, dynamic>),
      speedKmh: (json['speedKmh'] as num).toDouble(),
      pitchDeg: (json['pitchDeg'] as num).toDouble(),
      rollDeg: (json['rollDeg'] as num?)?.toDouble() ?? 0.0,
      yawDeg: (json['yawDeg'] as num?)?.toDouble() ?? 0.0,
      headingDeg: (json['headingDeg'] as num?)?.toDouble() ?? 0.0,
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      windDirectionDeg: (json['windDirectionDeg'] as num?)?.toDouble() ?? 0.0,
      targetDistanceM: (json['targetDistanceM'] as num?)?.toDouble() ?? 50.0,
      mode: json['mode'] as String? ?? 'precision',
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'seed': seed,
        'vehicle': vehicle.toJson(),
        'speedKmh': speedKmh,
        'pitchDeg': pitchDeg,
        'rollDeg': rollDeg,
        'yawDeg': yawDeg,
        'headingDeg': headingDeg,
        'windSpeedKmh': windSpeedKmh,
        'windDirectionDeg': windDirectionDeg,
        'targetDistanceM': targetDistanceM,
        'mode': mode,
      };
}

/// Output of a single simulation run.
/// Corresponds to shared-spec/result.schema.json.
/// PROVEN fields: targetPitchDeg, deltaDeg, isClearToEject.
/// PLANNED fields: lockQuality, trajectory, impactPosition, deviationM, score.
class SimulationResult {
  final double targetPitchDeg; // PROVEN
  final double deltaDeg; // PROVEN
  final bool isClearToEject; // PROVEN
  final double lockQuality; // PLANNED: 0.0..1.0
  final double deviationM; // PLANNED: wind-induced lateral deviation
  final ScoreBreakdown? score; // PLANNED

  const SimulationResult({
    required this.targetPitchDeg,
    required this.deltaDeg,
    required this.isClearToEject,
    this.lockQuality = 0.0,
    this.deviationM = 0.0,
    this.score,
  });

  Map<String, dynamic> toJson() => {
        'targetPitchDeg': targetPitchDeg,
        'deltaDeg': deltaDeg,
        'isClearToEject': isClearToEject,
        'lockQuality': lockQuality,
        'deviationM': deviationM,
        if (score != null) 'score': score!.toJson(),
      };
}

/// Score breakdown for a completed launch. PLANNED (Phase 9).
class ScoreBreakdown {
  final int total;
  final int precision; // from lockQuality
  final int impact; // from deviationM (lower = better)
  final int timing; // from timeToLockMs
  final int stability; // from lock hold duration
  final int style; // cosmetic, not used for ranking

  const ScoreBreakdown({
    required this.total,
    required this.precision,
    required this.impact,
    required this.timing,
    required this.stability,
    required this.style,
  });

  Map<String, dynamic> toJson() => {
        'total': total,
        'precision': precision,
        'impact': impact,
        'timing': timing,
        'stability': stability,
        'style': style,
      };
}
