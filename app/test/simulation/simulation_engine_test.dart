// simulation_engine_test.dart — SAFE//SPIT
//
// Tests for the full simulation engine — validates the test vectors from
// shared-spec/test-vectors.json against the Dart implementation.

import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/simulation/simulation_engine.dart';
import 'package:safespit/simulation/scenario.dart';
import 'package:safespit/simulation/vehicle_profiles.dart';

void main() {
  group('SimulationEngine — test vectors', () {
    // Helper to create a Car scenario
    ScenarioInput _carScenario({
      required String seed,
      required double speedKmh,
      required double pitchDeg,
      double windSpeedKmh = 0.0,
      double windDirectionDeg = 0.0,
      String mode = 'precision',
    }) {
      return ScenarioInput(
        seed: seed,
        vehicle: VehicleProfiles.car,
        speedKmh: speedKmh,
        pitchDeg: pitchDeg,
        windSpeedKmh: windSpeedKmh,
        windDirectionDeg: windDirectionDeg,
        mode: mode,
      );
    }

    // TV-01
    test('TV-01: 0 km/h → targetPitch=45.0, locked', () {
      final result = simulate(_carScenario(
          seed: '000000', speedKmh: 0.0, pitchDeg: 45.0));
      expect(result.targetPitchDeg, closeTo(45.0, 1e-6));
      expect(result.deltaDeg, closeTo(0.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-02
    test('TV-02: 50 km/h → targetPitch=57.0, locked', () {
      final result = simulate(_carScenario(
          seed: '000001', speedKmh: 50.0, pitchDeg: 57.0));
      expect(result.targetPitchDeg, closeTo(57.0, 1e-6));
      expect(result.deltaDeg, closeTo(0.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-03
    test('TV-03: 200 km/h → targetPitch=85.0 (clamp), locked', () {
      final result = simulate(_carScenario(
          seed: '000002', speedKmh: 200.0, pitchDeg: 85.0));
      expect(result.targetPitchDeg, closeTo(85.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-04
    test('TV-04: deltaDeg=4.9 → isClearToEject=true', () {
      final result = simulate(_carScenario(
          seed: '000003', speedKmh: 50.0, pitchDeg: 52.1));
      expect(result.targetPitchDeg, closeTo(57.0, 1e-6));
      expect(result.deltaDeg, closeTo(4.9, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-05
    test('TV-05: deltaDeg=5.0 → isClearToEject=true (inclusive)', () {
      final result = simulate(_carScenario(
          seed: '000004', speedKmh: 50.0, pitchDeg: 52.0));
      expect(result.deltaDeg, closeTo(5.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-06
    test('TV-06: deltaDeg=5.1 → isClearToEject=false', () {
      final result = simulate(_carScenario(
          seed: '000005', speedKmh: 50.0, pitchDeg: 51.9));
      expect(result.deltaDeg, closeTo(5.1, 1e-6));
      expect(result.isClearToEject, isFalse);
    });

    // TV-07
    test('TV-07: negative speed clamped to 0 → targetPitch=45.0', () {
      final result = simulate(_carScenario(
          seed: '000006', speedKmh: -10.0, pitchDeg: 45.0));
      expect(result.targetPitchDeg, closeTo(45.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-08
    test('TV-08: Car identity at 100 km/h → targetPitch=69.0', () {
      final result = simulate(_carScenario(
          seed: '000007', speedKmh: 100.0, pitchDeg: 69.0));
      expect(result.targetPitchDeg, closeTo(69.0, 1e-6));
    });

    // TV-09: Wind does NOT affect targetPitch
    test('TV-09: wind does not affect targetPitchDeg (Rule 15, D-5)', () {
      final noWind = simulate(_carScenario(
          seed: '000001', speedKmh: 50.0, pitchDeg: 57.0));
      final withWind = simulate(_carScenario(
          seed: '000008',
          speedKmh: 50.0,
          pitchDeg: 57.0,
          windSpeedKmh: 30.0,
          windDirectionDeg: 90.0,
          mode: 'crosswind'));
      expect(withWind.targetPitchDeg, closeTo(noWind.targetPitchDeg, 1e-6));
      // But wind should cause non-zero deviation
      expect(withWind.deviationM, greaterThan(0.0));
    });

    // TV-10: Determinism
    test('TV-10: same inputs produce identical results (determinism)', () {
      final scenario = ScenarioInput(
        seed: 'ABC123',
        vehicle: VehicleProfiles.car,
        speedKmh: 75.0,
        pitchDeg: 63.0,
        windSpeedKmh: 5.0,
        windDirectionDeg: 180.0,
        mode: 'precision',
      );
      final r1 = simulate(scenario);
      final r2 = simulate(scenario);
      expect(r1.targetPitchDeg, closeTo(r2.targetPitchDeg, 1e-10));
      expect(r1.deltaDeg, closeTo(r2.deltaDeg, 1e-10));
      expect(r1.isClearToEject, equals(r2.isClearToEject));
      expect(r1.lockQuality, closeTo(r2.lockQuality, 1e-10));
      expect(r1.deviationM, closeTo(r2.deviationM, 1e-10));
      // TV-10 expected: targetPitchDeg = 45 + 75/5*1.2 = 63.0
      expect(r1.targetPitchDeg, closeTo(63.0, 1e-6));
    });
  });

  group('SimulationEngine — lockQuality', () {
    test('lockQuality=1.0 when pitch exactly matches target', () {
      final result = simulate(ScenarioInput(
        seed: '000000',
        vehicle: VehicleProfiles.car,
        speedKmh: 50.0,
        pitchDeg: 57.0,
      ));
      expect(result.lockQuality, closeTo(1.0, 1e-6));
    });

    test('lockQuality=0.0 when not locked', () {
      final result = simulate(ScenarioInput(
        seed: '000000',
        vehicle: VehicleProfiles.car,
        speedKmh: 50.0,
        pitchDeg: 0.0, // way off target
      ));
      expect(result.lockQuality, closeTo(0.0, 1e-6));
    });

    test('lockQuality between 0 and 1 at tolerance edge', () {
      final result = simulate(ScenarioInput(
        seed: '000000',
        vehicle: VehicleProfiles.car,
        speedKmh: 50.0,
        pitchDeg: 52.0, // delta=5.0, exactly at edge
      ));
      expect(result.lockQuality, greaterThanOrEqualTo(0.0));
      expect(result.lockQuality, lessThanOrEqualTo(1.0));
    });
  });
}
