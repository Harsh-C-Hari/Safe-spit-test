# MASTER IMPLEMENTATION PLAN

This is the primary guide for implementing the SAFE//SPIT hackathon project from an empty directory.

## Objective
Build a deterministic, sensor-driven Flutter app that calculates the optimal pitch angle required to safely spit out of a moving vehicle window.

## Phase 1: Project Initialization & Architecture [REQUIRED]
- **Prerequisites**: Empty directory.
- **Work**: Initialize Flutter app (`flutter create`). Configure `pubspec.yaml` (sensors_plus, geolocator, camera, provider).
- **Verification**: App builds and runs a blank screen on Android.

## Phase 2: Core Simulation Engine [REQUIRED] [PROVEN]
- **Prerequisites**: Phase 1.
- **Work**: Implement pure-Dart simulation. No Flutter imports. Implement `SafeSpitCalculator`, `targetPitch` formula, `SimulationEngine`.
- **Tests**: Port the 37 proven unit tests from the reference build.
- **Verification**: All unit tests pass. Deterministic behavior is guaranteed.

## Phase 3: Sensor Abstraction & Telemetry [REQUIRED] [VALIDATED]
- **Work**: Create `SensorManager`. Subscribe to accelerometer and GPS. Calculate pitch from `atan2(z, y)`. Normalize into `NormalizedTelemetry`.
- **Known Pitfalls**: GPS can be noisy; pitch calculation requires specific Android axes handling.

## Phase 4: State Management & Game Flow [REQUIRED]
- **Work**: Implement `GameState` using `ChangeNotifier` (or similar). Handle BOOT -> READY -> DEMO/LIVE -> LOCK -> NEW ROUND.
- **Verification**: State transitions work via mock inputs.

## Phase 5: Demo Mode [REQUIRED] [PROVEN]
- **Work**: Build a deterministic tick-generator that feeds `ScenarioInput` into `simulation_engine.dart` independent of real sensors.
- **Verification**: App visually progresses through a mock spit sequence (pitch aligns, locks, fires) without physical movement.

## Phase 6: HUD & UI [REQUIRED] [VALIDATED]
- **Work**: Implement `MissileLockReticlePainter` and `HudScreen`.
- **Verification**: Visual crosshair moves based on pitch delta.

## Phase 7: Physical Camera [REQUIRED]
- **Work**: Initialize rear camera preview behind the HUD.
- **Verification**: App shows live camera feed.

## Phase 8: Audio & Haptics [SHOULD HAVE]
- **Work**: Trigger edge-based audio/haptic feedback on `UNLOCKED -> LOCKED` transition.

## Phase 9: Multiplayer & Backend [NICE TO HAVE] [PLANNED]
- **Work**: Real-time sync, leaderboards.
- **Warning**: Do not start until core phone experience is flawless.

## Important Constraints
- **DO NOT** break the deterministic separation of the simulation engine.
- **DO NOT** invent new physics formulas. Use the ones specified in `SIMULATION_SPEC.md`.
- **DO NOT** copy the passenger inversion bug from the reference build (see `FAILURE_LOG_REFERENCE.md`).
