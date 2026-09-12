// simulation_engine_test.dart — SAFE//SPIT
//
// Tests for the full simulation engine — validates the test vectors from
// shared-spec/test-vectors.json against the Dart implementation.

import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/simulation/simulation_engine.dart';
import 'package:safespit/simulation/scenario.dart';

void main() {
  group('SimulationEngine — test vectors', () {
    // Helper to create a Car scenario
    ScenarioInput carScenario({
      required String seed,
      required double speedKmh,
      required double pitchDeg,
      double windSpeedKmh = 0.0,
      double windDirectionDeg = 0.0,
      String mode = 'precision',
    }) {
      return ScenarioInput(
        seed: seed,
        speedKmh: speedKmh,
        pitchDeg: pitchDeg,
        windSpeedKmh: windSpeedKmh,
        windDirectionDeg: windDirectionDeg,
        mode: mode,
      );
    }

    test('0 km/h → targetPitch=0.0, locked', () {
      final result = simulate(carScenario(
            seed: '000000', speedKmh: 0.0, pitchDeg: 0.0));
          expect(result.targetPitchDeg, closeTo(0.0, 1e-6));
      expect(result.deltaDeg, closeTo(0.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    test('10 km/h → targetPitch=45.0, locked', () {
      final result = simulate(carScenario(
            seed: '000001', speedKmh: 10.0, pitchDeg: 45.0));
          expect(result.targetPitchDeg, closeTo(45.0, 1e-6));
      expect(result.deltaDeg, closeTo(0.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    test('20 km/h → targetPitch=90.0 (clamp), locked', () {
      final result = simulate(carScenario(
            seed: '000002', speedKmh: 20.0, pitchDeg: 90.0));
          expect(result.targetPitchDeg, closeTo(90.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-04
    test('TV-04: deltaDeg=4.9 → isClearToEject=true', () {
      final result = simulate(carScenario(
            seed: '000003', speedKmh: 10.0, pitchDeg: 40.1));
          expect(result.targetPitchDeg, closeTo(45.0, 1e-6));
          expect(result.deltaDeg, closeTo(4.9, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-05
    test('TV-05: deltaDeg=5.0 → isClearToEject=true (inclusive)', () {
      final result = simulate(carScenario(
          seed: '000004', speedKmh: 10.0, pitchDeg: 40.0));
      expect(result.deltaDeg, closeTo(5.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    // TV-06
    test('TV-06: deltaDeg=5.1 → isClearToEject=false', () {
      final result = simulate(carScenario(
          seed: '000005', speedKmh: 10.0, pitchDeg: 39.9));
      expect(result.deltaDeg, closeTo(5.1, 1e-6));
      expect(result.isClearToEject, isFalse);
    });

    test('negative speed clamped to 0 → targetPitch=0.0', () {
      final result = simulate(carScenario(
            seed: '000006', speedKmh: -10.0, pitchDeg: 0.0));
          expect(result.targetPitchDeg, closeTo(0.0, 1e-6));
      expect(result.isClearToEject, isTrue);
    });

    test('20 km/h target remains capped at 90 degrees', () {
      final result = simulate(carScenario(
            seed: '000007', speedKmh: 100.0, pitchDeg: 90.0));
          expect(result.targetPitchDeg, closeTo(90.0, 1e-6));
    });

    // TV-09: Wind does NOT affect targetPitch
    test('TV-09: wind does not affect targetPitchDeg (Rule 15, D-5)', () {
      final noWind = simulate(carScenario(
          seed: '000001', speedKmh: 50.0, pitchDeg: 70.0));
      final withWind = simulate(carScenario(
          seed: '000008',
          speedKmh: 50.0,
          pitchDeg: 70.0,
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
        speedKmh: 15.0,
        pitchDeg: 67.5,
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
      expect(r1.targetPitchDeg, closeTo(67.5, 1e-6));
    });
  });

  group('SimulationEngine — lockQuality', () {
    test('lockQuality=1.0 when pitch exactly matches target', () {
      final result = simulate(ScenarioInput(
        seed: '000000',
        speedKmh: 50.0,
        pitchDeg: 90.0,
      ));
      expect(result.lockQuality, closeTo(1.0, 1e-6));
    });

    test('lockQuality=0.0 when not locked', () {
      final result = simulate(ScenarioInput(
        seed: '000000',
        speedKmh: 50.0,
        pitchDeg: 0.0, // way off target
      ));
      expect(result.lockQuality, closeTo(0.0, 1e-6));
    });

    test('lockQuality between 0 and 1 at tolerance edge', () {
      final result = simulate(ScenarioInput(
        seed: '000000',
        speedKmh: 50.0,
        pitchDeg: 85.0, // delta=5.0, exactly at edge
      ));
      expect(result.lockQuality, greaterThanOrEqualTo(0.0));
      expect(result.lockQuality, lessThanOrEqualTo(1.0));
    });
  });
}
