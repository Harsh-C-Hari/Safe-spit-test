import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/simulation/safe_spit_calculator.dart';

void main() {
  group('SafeSpitCalculator target reference', () {
    test('zero speed points vertically up', () {
      expect(SafeSpitCalculator.targetPitch(0.0), equals(0.0));
    });

    test('negative speed is treated as zero', () {
      expect(SafeSpitCalculator.targetPitch(-10.0), equals(0.0));
    });

    test('target increases with phone speed', () {
      expect(SafeSpitCalculator.targetPitch(10.0), equals(45.0));
      expect(SafeSpitCalculator.targetPitch(15.0), equals(67.5));
    });

    test('target is clamped to the inclusive 0..90 range', () {
      expect(SafeSpitCalculator.targetPitch(20.0), equals(90.0));
      expect(SafeSpitCalculator.targetPitch(300.0), equals(90.0));
    });

    test('target is monotonic from zero through high speed', () {
      double previous = 0.0;
      for (double speed = 0.0; speed <= 300.0; speed += 5.0) {
        final target = SafeSpitCalculator.targetPitch(speed);
        expect(target, greaterThanOrEqualTo(previous));
        expect(target, inInclusiveRange(0.0, 90.0));
        previous = target;
      }
    });
  });

  group('SafeSpitCalculator lock tolerance', () {
    test('exact match locks', () {
      expect(
        SafeSpitCalculator.isClearToEject(
          actualPitchDeg: 45.0,
          targetPitchDeg: 45.0,
          speedKmh: 10.0,
        ),
        isTrue,
      );
    });

    test('five degrees is inside the inclusive tolerance', () {
      expect(
        SafeSpitCalculator.isClearToEject(
          actualPitchDeg: 40.0,
          targetPitchDeg: 45.0,
          speedKmh: 10.0,
        ),
        isTrue,
      );
    });

    test('more than five degrees does not lock at moving speed', () {
      expect(
        SafeSpitCalculator.isClearToEject(
          actualPitchDeg: 39.9,
          targetPitchDeg: 45.0,
          speedKmh: 10.0,
        ),
        isFalse,
      );
    });
  });
}
