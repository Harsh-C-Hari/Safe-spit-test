// scoring_test.dart — SAFE//SPIT
//
// Phase 9 acceptance: scoring determinism + edge cases.
// RULE 11: No DateTime.now(), no Random() in tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/simulation/scoring.dart';

void main() {
  group('computeScore — determinism', () {
    test('same inputs produce identical output', () {
      final a = computeScore(lockQuality: 0.85, deviationM: 0.5, timeToLockMs: 3000, mode: 'precision');
      final b = computeScore(lockQuality: 0.85, deviationM: 0.5, timeToLockMs: 3000, mode: 'precision');
      expect(a.total, equals(b.total));
      expect(a.precision, equals(b.precision));
      expect(a.impact, equals(b.impact));
      expect(a.timing, equals(b.timing));
    });

    test('total equals precision + impact + timing', () {
      final s = computeScore(lockQuality: 0.75, deviationM: 1.0, timeToLockMs: 5000, mode: 'precision');
      expect(s.total, equals(s.precision + s.impact + s.timing));
    });
  });

  group('computeScore — edge cases', () {
    test('perfect lock: lockQuality=1.0 ? precision=500', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 0.0, timeToLockMs: 1000, mode: 'precision');
      expect(s.precision, equals(500));
    });

    test('zero lock quality ? precision=0', () {
      final s = computeScore(lockQuality: 0.0, deviationM: 0.0, timeToLockMs: 1000, mode: 'precision');
      expect(s.precision, equals(0));
    });

    test('perfect deviation (<=0.1m) ? near-max impact', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 0.0, timeToLockMs: 1000, mode: 'precision');
      expect(s.impact, equals(300));
    });

    test('max deviation (>=5m) ? impact=0', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 5.0, timeToLockMs: 1000, mode: 'precision');
      expect(s.impact, equals(0));
    });

    test('fastest lock (1000ms) ? max timing=200', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 0.0, timeToLockMs: 1000, mode: 'precision');
      expect(s.timing, equals(200));
    });

    test('slowest lock (>=10000ms) ? timing=0', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 0.0, timeToLockMs: 10000, mode: 'precision');
      expect(s.timing, equals(0));
    });

    test('no timing (timeToLockMs=0) ? timing=0', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 0.0, timeToLockMs: 0, mode: 'precision');
      expect(s.timing, equals(0));
    });

    test('perfect run ? total >= 950 (S grade)', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 0.0, timeToLockMs: 1000, mode: 'precision');
      expect(s.total, greaterThanOrEqualTo(950));
    });

    test('total never exceeds 1000', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 0.0, timeToLockMs: 1000, mode: 'precision');
      expect(s.total, lessThanOrEqualTo(1000));
    });

    test('style bonus: perfect lock in non-precision mode ? 100 pts', () {
      final s = computeScore(lockQuality: 1.0, deviationM: 0.0, timeToLockMs: 1000, mode: 'crosswind');
      expect(s.style, equals(100));
    });

    test('style bonus: lockQuality=0.95 in precision mode ? 50 pts', () {
      final s = computeScore(lockQuality: 0.95, deviationM: 0.0, timeToLockMs: 1000, mode: 'precision');
      expect(s.style, equals(50));
    });
  });
}
