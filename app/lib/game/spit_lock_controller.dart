// spit_lock_controller.dart — SAFE//SPIT
//
// PLANNED: Edge-triggered lock state machine (Phase 6).
// RULE 10: Audio and haptic fire ONCE on the false→true transition (D-13).
//          They do NOT fire continuously while locked.
// PROVEN pattern: the prototype uses _wasClear to track the previous lock state.

import 'dart:async';

import '../sensors/normalized_telemetry.dart';
import '../simulation/safe_spit_calculator.dart';
import '../simulation/scenario.dart';

/// The lock states the system cycles through.
enum SpitLockState {
  searching, // Δθ > tolerance, no lock
  locking, // Δθ is narrowing toward tolerance (visual feedback)
  locked, // Δθ <= tolerance — SPIT LOCK acquired
}

/// Represents a single lock transition event.
class LockTransition {
  final SpitLockState previous;
  final SpitLockState current;
  final bool isLockAcquired; // false→true edge (fire audio+haptic)
  final bool isLockLost; // true→false edge (optional cue, A-tier)

  const LockTransition({
    required this.previous,
    required this.current,
    required this.isLockAcquired,
    required this.isLockLost,
  });
}

/// The edge-triggered lock state machine.
///
/// Feed it [NormalizedTelemetry] ticks and a [SimulationResult] and it
/// will emit [LockTransition] events whenever lock state changes.
///
/// Audio and haptic handlers should subscribe to [onTransition] and
/// fire ONLY when [LockTransition.isLockAcquired] is true (Rule 10).
class SpitLockController {
  // State
  SpitLockState _state = SpitLockState.searching;
  bool _wasClear = false; // PROVEN pattern from prototype
  double _lockQuality = 0.0;
  int? _lockStartMs; // wall-clock ms when lock was first acquired

  // Lock duration tracking
  int _lockHoldMs = 0;

  // Transitions stream
  final StreamController<LockTransition> _transitionController =
      StreamController<LockTransition>.broadcast();

  Stream<LockTransition> get onTransition => _transitionController.stream;

  SpitLockState get state => _state;
  double get lockQuality => _lockQuality;
  int get lockHoldMs => _lockHoldMs;

  /// Process a new telemetry tick against a [SimulationResult].
  ///
  /// Call this each time new [NormalizedTelemetry] arrives.
  void processTick(SimulationResult result, DateTime now) {
    final bool isClear = result.isClearToEject;
    final bool wasAlreadyClear = _wasClear;

    // ── Update lock quality ─────────────────────────────────────────────
    if (isClear) {
      // Exponential smoothing toward 1.0 (perfect lock)
      _lockQuality = _lockQuality * 0.85 + result.lockQuality * 0.15;
    } else {
      _lockQuality = _lockQuality * 0.9; // Decay slowly when not locked
    }

    // ── State machine transitions ────────────────────────────────────────
    final SpitLockState previousState = _state;
    SpitLockState nextState;

    if (isClear) {
      nextState = SpitLockState.locked;
    } else if (result.deltaDeg < SafeSpitCalculator.lockToleranceDeg * 3) {
      // Within 15°: show "locking" visual feedback
      nextState = SpitLockState.locking;
    } else {
      nextState = SpitLockState.searching;
    }

    // ── Edge detection (PROVEN _wasClear pattern) ────────────────────────
    final bool lockAcquired = !wasAlreadyClear && isClear;
    final bool lockLost = wasAlreadyClear && !isClear;

    if (lockAcquired) {
      _lockStartMs = now.millisecondsSinceEpoch;
      _lockHoldMs = 0;
    }

    if (isClear && _lockStartMs != null) {
      _lockHoldMs = now.millisecondsSinceEpoch - _lockStartMs!;
    }

    _wasClear = isClear;
    _state = nextState;

    // ── Emit transition event if state changed ───────────────────────────
    if (nextState != previousState || lockAcquired || lockLost) {
      _transitionController.add(LockTransition(
        previous: previousState,
        current: nextState,
        isLockAcquired: lockAcquired,
        isLockLost: lockLost,
      ));
    }
  }

  /// Reset the controller (e.g. on new scenario or "try again").
  void reset() {
    _state = SpitLockState.searching;
    _wasClear = false;
    _lockQuality = 0.0;
    _lockStartMs = null;
    _lockHoldMs = 0;
  }

  void dispose() {
    _transitionController.close();
  }
}
