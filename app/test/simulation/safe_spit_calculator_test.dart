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
    test('TV-01: targetPitch(0) == 90.0 (proven)', () {
      expect(SafeSpitCalculator.targetPitch(0.0), equals(90.0));
    });

    // ── TV-02: 50 km/h ──────────────────────────────────────────────────────
    test('TV-02: targetPitch(50) == 70.0 (proven)', () {
      expect(SafeSpitCalculator.targetPitch(50.0), equals(70.0));
    });

    // ── TV-03: 200 km/h clamp ───────────────────────────────────────────────
    test('TV-03: targetPitch(200) == 10.0 (proven, clamp)', () {
      expect(SafeSpitCalculator.targetPitch(200.0), equals(10.0));
    });

    // ── TV-07: Negative speed clamped (D-14, Rule 16) ───────────────────────
    test('TV-07: targetPitch(-10) == 90.0 (negative speed clamped)', () {
      expect(SafeSpitCalculator.targetPitch(-10.0), equals(90.0));
    });

    // ── TV-08: Car identity profile (D-4, Rule 20) ──────────────────────────
    test('TV-08: Car profile is identity — targetPitch(100, car) == 50.0', () {
      expect(
        SafeSpitCalculator.targetPitch(100.0, vehicle: VehicleProfiles.car),
        equals(50.0),
      );
    });

    // ── TV-10: Determinism ───────────────────────────────────────────────────
    test('TV-10: same inputs produce same output (determinism)', () {
      const double speed = 75.0;
      final r1 = SafeSpitCalculator.targetPitch(speed);
      final r2 = SafeSpitCalculator.targetPitch(speed);
      expect(r1, equals(r2));
      expect(r1, closeTo(60.0, 1e-6)); // 90 - (75/5)*2.0 = 60.0
    });

    // ── Additional coverage ──────────────────────────────────────────────────
    test('clamp lower: targetPitch(300) never below 10.0', () {
      expect(SafeSpitCalculator.targetPitch(300.0), equals(10.0));
    });

    test('clamp upper: targetPitch(0) never above 90.0', () {
      for (double v = -100; v <= 0; v += 10) {
        expect(SafeSpitCalculator.targetPitch(v), lessThanOrEqualTo(90.0));
      }
    });

    test('monotonically non-increasing from 0 to 200', () {
      double prev = 90.0;
      for (double v = 0; v <= 200; v += 5) {
        final pitch = SafeSpitCalculator.targetPitch(v);
        expect(pitch, lessThanOrEqualTo(prev));
        prev = pitch;
      }
    });
  });

  group('SafeSpitCalculator — isClearToEject (PROVEN tolerance)', () {
    // ── TV-04: Just inside tolerance ────────────────────────────────────────
    test('TV-04: deltaDeg=4.9 → isClearToEject=true', () {
      // targetPitch(50) = 70.0; actualPitch = 65.1 → delta = 4.9
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 65.1, targetPitchDeg: 70.0, speedKmh: 50.0),
        isTrue,
      );
    });

    // ── TV-05: Exactly on tolerance edge (inclusive <=) ─────────────────────
    test('TV-05: deltaDeg=5.0 → isClearToEject=true (inclusive)', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 65.0, targetPitchDeg: 70.0, speedKmh: 50.0),
        isTrue,
      );
    });

    // ── TV-06: Just outside tolerance ───────────────────────────────────────
    test('TV-06: deltaDeg=5.1 → isClearToEject=false', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 64.9, targetPitchDeg: 70.0, speedKmh: 50.0),
        isFalse,
      );
    });

    test('exact match: actualPitch == targetPitch → locked', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 70.0, targetPitchDeg: 70.0, speedKmh: 50.0),
        isTrue,
      );
    });

    test('targetPitch > 135 requires strict roll (roll > 15 fails)', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 180.0, targetPitchDeg: 180.0, speedKmh: 0.0, rollDeg: 20.0),
        isFalse, // Fails due to roll
      );
    });

    test('targetPitch > 135 passes if roll <= 15', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 180.0, targetPitchDeg: 180.0, speedKmh: 0.0, rollDeg: 10.0),
        isTrue,
      );
    });

    test('targetPitch < 45 passes if roll is near 180 (face down)', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 0.0, targetPitchDeg: 0.0, speedKmh: 0.0, rollDeg: 175.0),
        isTrue,
      );
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 0.0, targetPitchDeg: 0.0, speedKmh: 0.0, rollDeg: -170.0),
        isTrue,
      );
    });

    test('targetPitch < 45 fails if roll is far from 0 and 180', () {
      expect(
        SafeSpitCalculator.isClearToEject(
            actualPitchDeg: 0.0, targetPitchDeg: 0.0, speedKmh: 0.0, rollDeg: 90.0),
        isFalse,
      );
    });
  });

  group('SafeSpitCalculator — vertical modifiers (NEW)', () {
    test('Still profile gives 0.0 target pitch (straight UP)', () {
      expect(
        SafeSpitCalculator.targetPitch(0.0, vehicle: VehicleProfiles.still),
        equals(0.0),
      );
    });

    test('Walking profile at low speed gives 0.0 target pitch', () {
      expect(
        SafeSpitCalculator.targetPitch(4.0, vehicle: VehicleProfiles.walking),
        equals(0.0),
      );
    });
    
    test('Walking profile at moderate speed gives upward pitch angled forward', () {
      // 0.0 + ((10.0 - 5.0) * 6.0) = 30.0
      expect(
        SafeSpitCalculator.targetPitch(10.0, vehicle: VehicleProfiles.walking),
        equals(30.0),
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

    // Bus has a higher turbulenceFactor — should give lower pitch at same speed (more forward)
    test('Bus: higher turbulenceFactor gives lower pitch (fictional)', () {
      final carPitch = SafeSpitCalculator.targetPitch(50.0, vehicle: VehicleProfiles.car);
      final busPitch = SafeSpitCalculator.targetPitch(50.0, vehicle: VehicleProfiles.bus);
      expect(busPitch, lessThan(carPitch));
    });

    test('All vehicles: result always within [0, 180]', () {
      for (final vehicle in VehicleProfiles.all) {
        for (double v = 0; v <= 300; v += 50) {
          final pitch = SafeSpitCalculator.targetPitch(v, vehicle: vehicle);
          expect(pitch, greaterThanOrEqualTo(0.0));
          expect(pitch, lessThanOrEqualTo(180.0));
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
  group('SafeSpitCalculator — backwards facing modifiers (NEW)', () {
    test('Backwards facing adds angle instead of subtracting', () {
      final forward = SafeSpitCalculator.targetPitch(50.0, isFacingBackwards: false);
      final backward = SafeSpitCalculator.targetPitch(50.0, isFacingBackwards: true);
      // 50 km/h -> 70.0 forward, 110.0 backward
      expect(forward, equals(70.0));
      expect(backward, equals(110.0));
    });

    test('Backwards facing clamps at 180', () {
      final backward = SafeSpitCalculator.targetPitch(300.0, isFacingBackwards: true);
      // 90 + (300/5)*2 = 210, clamped to 180
      expect(backward, equals(180.0));
    });

    test('Backwards facing identity profile', () {
      final carBackward = SafeSpitCalculator.targetPitch(100.0, vehicle: VehicleProfiles.car, isFacingBackwards: true);
      // 90 + (100/5)*2 = 130
      expect(carBackward, equals(130.0));
    });
  });
}
