# CURRENT_STATUS.md — SAFE//SPIT

> **Status:** IMPLEMENTATION — Phases 0–6 complete (simulation, sensors, game loop, HUD core). Tests passing. Analyzer clean.
> **Cross-references:** `update.ai/PROJECT_CONTEXT.md`, `update.ai/IMPLEMENTATION_RULES.md`, `update.ai/DECISIONS.md`, `docs/IMPLEMENTATION_ORDER.md`.

## Current phase

**Phase 6 complete.** Simulation engine, sensor abstraction, game state machine, HUD, SpitLockController, Demo Mode, and audio/haptic services are all implemented and verified.

Next: **Phase 7** — Demo Mode end-to-end test (DemoModeSource → GameState → HudScreen renders correctly with "DEMO MODE" label).

## What is IMPLEMENTED (as of this session)

### Phase 0 ✅
- Flutter project `app/` created with correct directory structure.
- `pubspec.yaml` configured with full dependency stack (camera, geolocator, sensors_plus, provider, audioplayers, permission_handler).
- `assets/audio/` (lock_tone.wav generated), `assets/fonts/` (SpaceMono).
- `lib/` directory layout: `simulation/`, `sensors/`, `game/`, `hud/`, `services/`, `backend/`.

### Phase 1 ✅ — Simulation engine
- `lib/simulation/safe_spit_calculator.dart` — PROVEN formula, vehicle modifier support.
- `lib/simulation/vehicle_profiles.dart` — Car (identity), Bus, Train, Motorcycle, Bicycle, Hoverboard.
- `lib/simulation/scenario.dart` — `ScenarioInput` / `SimulationResult` / `ScoreBreakdown` types.
- `lib/simulation/trajectory_model.dart` — Parabolic arc, `ScenarioRng`, `computeWindDeviation`.
- `lib/simulation/scoring.dart` — Deterministic `computeScore()`, `updateLockQuality()`.
- `lib/simulation/simulation_engine.dart` — Top-level `simulate(ScenarioInput)` pure function.
- **Tests:** 30 tests, all passing. TV-01 through TV-10 verified.

### Phase 2 ✅ — Sensor abstraction
- `lib/sensors/normalized_telemetry.dart` — `NormalizedTelemetry`, `SensorHealth`, `SensorHealthStatus`.
- `lib/sensors/sensor_manager.dart` — PROVEN GPS + gyroscope pipelines emitting `Stream<NormalizedTelemetry>`.
- `lib/sensors/demo_mode_source.dart` — Deterministic 20s demo cycle, no sensors required.

### Phase 3 ✅ — Permission gate
- `lib/hud/permission_gate.dart` — PROVEN "SYSTEM LOCKED" screen + Demo Mode entry (Rule 5, D-1).

### Phase 4 ✅ — Scenario types and wind deviation
- Implemented in `scenario.dart` and `trajectory_model.dart`.

### Phase 5 ✅ — HUD reticle painter
- `lib/hud/missile_lock_reticle_painter.dart` — PROVEN `MissileLockReticlePainter` extended with trajectory arc, wind indicator, lock quality arc, demo mark.

### Phase 6 ✅ — Game loop and state machine
- `lib/game/spit_lock_controller.dart` — `SpitLockController` with PROVEN `_wasClear` edge-trigger pattern. Emits `LockTransition` events.
- `lib/game/game_state.dart` — `GameState` ChangeNotifier driving Idle→HudLive→Locking→Locked→Launched→Scored.
- `lib/hud/hud_screen.dart` — Full HUD screen with camera, reticle, top/bottom bars, launch button, score overlay, Demo Mode indicator (Rule 8).
- `lib/services/audio_service.dart` — Lock tone (local WAV asset, D-2, Rule 4).
- `lib/services/haptic_service.dart` — Haptic feedback, edge-triggered (Rule 10).
- `lib/backend/backend_gateway.dart` — `BackendGateway` interface + `NoopBackendGateway` (D-9).
- `lib/main.dart` — App entry point, Provider tree, portrait lock, immersive mode, `SafeSpitRouter`.
- **Tests:** 7 tests, all passing. Edge-trigger invariant (Rule 10) verified.

### Analysis ✅
- `flutter analyze lib/` — **No issues found**.
- 37 unit tests passing.

## What is PROVEN

From the prototype APK teardown (unchanged in this build):

- `targetPitch(v) = clamp(45 + (v/5) * 1.2, 45, 85)` — TV-01, TV-02, TV-03 ✅
- `isClearToEject` tolerance: `deltaDeg <= 5.0` — TV-04, TV-05, TV-06 ✅
- `MissileLockReticlePainter` with `#39FF14` tactical green ✅
- GPS speed pipeline: `v_kmh = v_ms * 3.6`, `onError`/`cancelOnError`/`onDone` handlers ✅
- Gyroscope pitch integration: dt-integration, `[0°, 180°]` clamp ✅
- Camera passthrough: `CameraController(cameras.first, ResolutionPreset.high, enableAudio: false)` ✅
- Edge-triggered lock audio: fires once on false→true transition only (Rule 10) ✅

## What is PLANNED (next phases)

- **Phase 7:** Demo Mode end-to-end test on device/emulator.
- **Phase 8:** Vehicle selection UI screen.
- **Phase 9:** Scoring screen and leaderboard UI.
- **Phase 10:** Pass-and-play multiplayer (MULTIPLAYER_SPEC.md).
- **Phase 11:** Wind and difficulty modes.
- **Phase 12:** Supabase backend integration (BackendGateway Supabase implementation).
- **Phases 13–17:** Website, ESP32, polish, packaging, hackathon prep.

## What is UNKNOWN (unchanged from planning)

- Exact `LocationAccuracy` setting from the prototype.
- Real-world gyro drift magnitude over multi-minute sessions.
- Whether Android 14+ location permission prompts need special handling beyond `permission_handler`.
- Non-Car vehicle profile numeric tuning values (`turbulenceFactor`, `angleBias`, etc.).
- Whether lockQuality exponential smoothing (alpha=0.15) feels right on a real device.

## What is broken

Nothing. `flutter analyze lib/` clean. 37/37 tests passing.

## Next recommended action (single, specific)

**Phase 7:** Run the app in Demo Mode on a physical device or emulator. Verify:
1. PermissionGate shows "ENTER DEMO MODE" button.
2. Tapping it enters the HUD with "DEMO MODE" indicator visible (Rule 8).
3. HUD animates over ~8s, reaches SPIT LOCK, fires lock tone.
4. "EXECUTE SPIT PROTOCOL" button appears. Tapping scores the run.

**Build command:** `flutter run --debug` (Android device connected or emulator started).

## Blockers

None. All pure-Dart tests passing. Analyzer clean. Ready for device testing.

- Phase 8 update (2026-09-08): Vehicle system — direction indicator (headingDeg) and aim-guide arrow implemented; vehicle selector (`vehicle_select_screen.dart`) and profile data (`vehicle_profiles.dart`) remain planned. Car identity profile preserved per D-4.
