// safe_spit_calculator_test.dart — SAFE//SPIT
//
// Phase 1 acceptance tests — the three proven test points MUST pass.
// Also covers all shared-spec/test-vectors.json assertions for Dart.
//
// These are the FIRST tests that run. If any fail, the build is broken.
// RULE 7: Simulation tests must pass before any new mode is added.

import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/simulation/safe_spit_calculator.dart';
import 'package:safespit/simulation/vehicle_profiles.dart';

void main() {
  group('SafeSpitCalculator — PROVEN formula', () {
    // ── TV-01: Zero speed ───────────────────────────────────────────────────
    test('TV-01: targetPitch(0) == 45.0 (proven)', () {
      expect(SafeSpitCalculator.targetPitch(0.0), equals(45.0));
    });

    // ── TV-02: 50 km/h ──────────────────────────────────────────────────────
    test('TV-02: targetPitch(50) == 57.0 (proven)', () {
      expect(SafeSpitCalculator.targetPitch(50.0), equals(57.0));
    });

    // ── TV-03: 200 km/h clamp ───────────────────────────────────────────────
    test('TV-03: targetPitch(200) == 85.0 (proven, clamp)', () {
      expect(SafeSpitCalculator.targetPitch(200.0), equals(85.0));
    });

    // ── TV-07: Negative speed clamped (D-14, Rule 16) ───────────────────────
    test('TV-07: targetPitch(-10) == 45.0 (negative speed clamped)', () {
      expect(SafeSpitCalculator.targetPitch(-10.0), equals(45.0));
    });

    // ── TV-08: Car identity profile (D-4, Rule 20) ──────────────────────────
    test('TV-08: Car profile is identity — targetPitch(100, car) == 69.0', () {
      expect(
        SafeSpitCalculator.targetPitch(100.0, vehicle: VehicleProfiles.car),
        equals(69.0),
      );
    });

    // ── TV-10: Determinism ───────────────────────────────────────────────────
    test('TV-10: same inputs produce same output (determinism)', () {
      const double speed = 75.0;
      final r1 = SafeSpitCalculator.targetPitch(speed);
      final r2 = SafeSpitCalculator.targetPitch(speed);
      expect(r1, equals(r2));
      expect(r1, closeTo(63.0, 1e-6)); // 45 + (75/5)*1.2 = 63.0
    });

    // ── Additional coverage ──────────────────────────────────────────────────
    test('clamp lower: targetPitch(0) never below 45.0', () {
      for (double v = -100; v <= 0; v += 10) {
        expect(SafeSpitCalculator.targetPitch(v), greaterThanOrEqualTo(45.0));
      }
    });

    test('clamp upper: targetPitch(300) never above 85.0', () {
      expect(SafeSpitCalculator.targetPitch(300.0), equals(85.0));
    });

    test('monotonically non-decreasing from 0 to 200', () {
      double prev = 45.0;
      for (double v = 0; v <= 200; v += 5) {
        final pitch = SafeSpitCalculator.targetPitch(v);
        expect(pitch, greaterThanOrEqualTo(prev));
        prev = pitch;
      }
    });
  });

  group('SafeSpitCalculator — isClearToEject (PROVEN tolerance)', () {
    // ── TV-04: Just inside tolerance ────────────────────────────────────────
    test('TV-04: deltaDeg=4.9 → isClearToEject=true', () {
      // targetPitch(50) = 57.0; actualPitch = 52.1 → delta = 4.9
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 52.1, targetPitchDeg: 57.0),
        isTrue,
      );
    });

    // ── TV-05: Exactly on tolerance edge (inclusive <=) ─────────────────────
    test('TV-05: deltaDeg=5.0 → isClearToEject=true (inclusive)', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 52.0, targetPitchDeg: 57.0),
        isTrue,
      );
    });

    // ── TV-06: Just outside tolerance ───────────────────────────────────────
    test('TV-06: deltaDeg=5.1 → isClearToEject=false', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 51.9, targetPitchDeg: 57.0),
        isFalse,
      );
    });

    test('exact match: actualPitch == targetPitch → locked', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 57.0, targetPitchDeg: 57.0),
        isTrue,
      );
    });
  });

  group('SafeSpitCalculator — vehicle modifiers (PLANNED)', () {
    // TV-08 parity: Car identity
    test('Car: turbulenceFactor=1.0, angleBias=0.0 reproduces base formula', () {
      for (double v in [0.0, 50.0, 100.0, 200.0]) {
        final base = SafeSpitCalculator.targetPitch(v);
        final withCar = SafeSpitCalculator.targetPitch(v, vehicle: VehicleProfiles.car);
        expect(withCar, closeTo(base, 1e-10));
      }
    });

    // Bus has a higher turbulenceFactor — should give higher pitch at same speed
    test('Bus: higher turbulenceFactor gives higher pitch (fictional)', () {
      final carPitch = SafeSpitCalculator.targetPitch(50.0, vehicle: VehicleProfiles.car);
      final busPitch = SafeSpitCalculator.targetPitch(50.0, vehicle: VehicleProfiles.bus);
      expect(busPitch, greaterThan(carPitch));
    });

    // All vehicles: result still clamped within [45, 85]
    test('All vehicles: result always within [45, 85]', () {
      for (final vehicle in VehicleProfiles.all) {
        for (double v = 0; v <= 300; v += 50) {
          final pitch = SafeSpitCalculator.targetPitch(v, vehicle: vehicle);
          expect(pitch, greaterThanOrEqualTo(45.0));
          expect(pitch, lessThanOrEqualTo(85.0));
        }
      }
    });
  });

  group('SafeSpitCalculator — TV-09: Wind does NOT affect targetPitch', () {
    // Wind does not appear in the formula at all — this test documents the contract.
    test('TV-09: targetPitch is wind-independent (D-5, Rule 15)', () {
      // The calculator takes (speed, vehicle) only — wind is not a parameter.
      // This test documents the correct absence of wind from the formula.
      final noWind = SafeSpitCalculator.targetPitch(50.0);
      // "With wind" — targetPitch formula has no wind parameter, so result is identical.
      final withWindSpeed = SafeSpitCalculator.targetPitch(50.0);
      expect(noWind, equals(withWindSpeed));
    });
  });
}
