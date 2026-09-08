// spit_lock_controller_test.dart — SAFE//SPIT
//
// Phase 6 acceptance tests for the edge-triggered lock state machine.
// Key invariant (Rule 10): audio/haptic fire ONCE on false→true edge only.

import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/game/spit_lock_controller.dart';
import 'package:safespit/simulation/simulation_engine.dart';
import 'package:safespit/simulation/scenario.dart';
import 'package:safespit/simulation/vehicle_profiles.dart';

SimulationResult _makeResult({required bool locked, double delta = 0.0}) {
  return SimulationResult(
    targetPitchDeg: 57.0,
    deltaDeg: delta,
    isClearToEject: locked,
    lockQuality: locked ? (1.0 - delta / 5.0).clamp(0.0, 1.0) : 0.0,
    deviationM: 0.0,
  );
}

void main() {
  group('SpitLockController — edge-triggered transitions', () {
    late SpitLockController controller;
    late List<LockTransition> transitions;

    setUp(() {
      controller = SpitLockController();
      transitions = [];
      controller.onTransition.listen(transitions.add);
    });

    tearDown(() {
      controller.dispose();
    });

    // ── Rule 10: Audio/haptic events counted ─────────────────────────────────

    test('lock acquired fires ONE transition event on false→true edge', () async {
      // Tick unlocked several times
      for (int i = 0; i < 5; i++) {
        controller.processTick(_makeResult(locked: false, delta: 10.0), DateTime.now());
      }

      // Now lock
      controller.processTick(_makeResult(locked: true, delta: 0.0), DateTime.now());

      await Future<void>.delayed(Duration.zero); // let stream deliver

      final lockEvents = transitions.where((t) => t.isLockAcquired).toList();
      expect(lockEvents.length, equals(1),
          reason: 'lock acquired event must fire exactly once (Rule 10)');
    });

    test('staying locked does NOT fire more lockAcquired events', () async {
      controller.processTick(_makeResult(locked: false, delta: 10.0), DateTime.now());
      controller.processTick(_makeResult(locked: true, delta: 0.0), DateTime.now());
      // Stay locked for many ticks
      for (int i = 0; i < 10; i++) {
        controller.processTick(_makeResult(locked: true, delta: 0.0), DateTime.now());
      }

      await Future<void>.delayed(Duration.zero);

      final lockEvents = transitions.where((t) => t.isLockAcquired).toList();
      expect(lockEvents.length, equals(1),
          reason: 'staying locked must not re-fire the lock event (Rule 10)');
    });

    test('lock lost fires one isLockLost event on true→false edge', () async {
      controller.processTick(_makeResult(locked: false, delta: 10.0), DateTime.now());
      controller.processTick(_makeResult(locked: true, delta: 0.0), DateTime.now());
      controller.processTick(_makeResult(locked: false, delta: 10.0), DateTime.now());

      await Future<void>.delayed(Duration.zero);

      final lostEvents = transitions.where((t) => t.isLockLost).toList();
      expect(lostEvents.length, equals(1),
          reason: 'lock lost event fires once on true→false edge');
    });

    test('state transitions: searching → locking → locked', () async {
      controller.processTick(_makeResult(locked: false, delta: 20.0), DateTime.now());
      expect(controller.state, equals(SpitLockState.searching));

      controller.processTick(_makeResult(locked: false, delta: 8.0), DateTime.now());
      expect(controller.state, equals(SpitLockState.locking));

      controller.processTick(_makeResult(locked: true, delta: 0.0), DateTime.now());
      expect(controller.state, equals(SpitLockState.locked));
    });

    test('reset clears all state', () {
      controller.processTick(_makeResult(locked: true, delta: 0.0), DateTime.now());
      expect(controller.state, equals(SpitLockState.locked));

      controller.reset();
      expect(controller.state, equals(SpitLockState.searching));
      expect(controller.lockQuality, equals(0.0));
    });
  });

  group('SpitLockController — lock quality', () {
    late SpitLockController controller;

    setUp(() => controller = SpitLockController());
    tearDown(() => controller.dispose());

    test('lockQuality is 0 when not locked', () {
      controller.processTick(_makeResult(locked: false, delta: 20.0), DateTime.now());
      expect(controller.lockQuality, closeTo(0.0, 0.1));
    });

    test('lockQuality increases over time while locked', () {
      // First tick not locked
      controller.processTick(_makeResult(locked: false, delta: 10.0), DateTime.now());
      final q0 = controller.lockQuality;

      // Lock for several ticks
      for (int i = 0; i < 20; i++) {
        controller.processTick(_makeResult(locked: true, delta: 0.0), DateTime.now());
      }

      expect(controller.lockQuality, greaterThan(q0));
    });
  });
}
