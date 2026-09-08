# TEST_PLAN.md — SAFE//SPIT

> **Status:** PLANNED (new). The reference build is not done until this test plan passes.
> **Cross-references:** `shared-spec/test-vectors.json`, `RISK_REGISTER.md`, `DEMO_PLAN.md`, `IMPLEMENTATION_ORDER.md`.

## 1. Unit tests (simulation, pure)

These run without Flutter, without a device, without a network. They are the majority of the automated test surface.

1. `targetPitch(0) == 45.0` (TV-01).
2. `targetPitch(50) == 57.0` (TV-02).
3. `targetPitch(200) == 85.0` (TV-03, clamp engaged).
4. `targetPitch(-10) == 45.0` (TV-07, negative speed clamped per D-14).
5. `isClearToEject` boundary: `deltaDeg = 4.9` → true (TV-04); `deltaDeg = 5.0` → true (TV-05, inclusive); `deltaDeg = 5.1` → false (TV-06).
6. Vehicle modifier identity: `Car` profile produces the same result as no-vehicle (TV-08).
7. Scoring determinism: same `(seed, telemetry log)` → same `score`, run twice (TV-10).
8. Lock quality calculation: `lockQuality` is in `[0, 1]`; `lockQuality = 1.0` when `deltaDeg = 0`; `lockQuality = 0.0` when `deltaDeg = 5.0`.
9. Wind deviation: wind affects `deviationM` and `impactPosition` but NOT `targetPitchDeg` (TV-09).
10. Trajectory length: `trajectory` has at least 2 points and is deterministic for a given Scenario.
11. Scenario-seed reproducibility: same seed → same wind, same target distance, same mode-specific modifiers.

## 2. Unit tests (sensor abstraction, no platform)

1. `NormalizedTelemetry` construction with all fields.
2. `SensorHealth` transitions: `ok → degraded`, `ok → unavailable`, `ok → permissionDenied`, and back.
3. `DemoModeSource` produces a deterministic `NormalizedTelemetry` stream for a given seed.
4. Clock injection for deterministic tests (the simulation does not read `DateTime.now()`; the test injects a virtual clock).

## 3. Integration tests (with Flutter test framework, no device)

1. Sensor manager wiring uses fake streams (no real GPS, no real gyro).
2. Lock controller fires audio/haptic edge exactly once on false→true and once on true→false (D-13).
3. Permission gate text changes when permission is denied ("SYSTEM LOCKED") vs granted (routes to HUD).
4. Demo Mode is selectable from the lock screen ("ENTER DEMO MODE" button visible, routes to HUD with "DEMO MODE" indicator).
5. `BackendGateway` in Noop mode returns `Result.err('backend disabled')` without throwing.

## 4. Widget tests (Flutter test framework)

1. HUD reticle paints green (`#39FF14`) on lock, default color on unlock.
2. Lock transition is edge-triggered (audio event count = 1 per transition, not per frame).
3. Bottom telemetry reads from `NormalizedTelemetry`, not from raw sensor objects.
4. Result screen renders score breakdown (precision, impact, timing, stability, style).
5. "DEMO MODE" indicator is visible when Demo Mode is active.

## 5. Device tests (manual, documented as a checklist)

A `DEVICE-TEST-CHECKLIST.md` is generated at reference-build time. Each entry in `RISK_REGISTER.md`'s "Detection" column becomes a checkbox item. The categories:

1. Sensor availability matrix: GPS present/absent, gyro present/absent, camera present/absent.
2. Permission denial matrix: GPS denied, camera denied, both denied, both granted.
3. Lifecycle: background→foreground, screen rotation, app kill→relaunch.
4. Network failure: airplane mode on, Supabase unreachable, slow network.
5. Audio failure: device muted, audio output unavailable.
6. Haptic failure: device with no vibrator.
7. Low-end device: a 2019-era budget Android if available.

## 6. Game tests

1. Pass-and-play produces identical conditions for both players (same seed, same target pitch, same trajectory shape).
2. Replay from `(seed, sensorLog)` reproduces the same score.
3. Tournament bracket calculation is correct (2, 3, 4 players).
4. Each mode (precision, speed_lock, target_strike, crosswind) applies its scoring weights correctly.

## 7. Website tests

1. Responsive layout: desktop, tablet, mobile.
2. Input normalization: mouse, touch, keyboard produce the same `NormalizedTelemetry` for the same logical input.
3. Simulation parity: running a shared `test-vectors.json` vector in the website simulator produces the same `SimulationResult` as the Android app (D-3, R-10).
4. Performance budget: 60fps on desktop, 30fps on mobile.
5. Shareable seed URL: `/play?seed=8F42A7&vehicle=car` produces the same scenario for two visitors.

## 8. End-to-end integration test

`Sensor → Telemetry → Simulation → HUD → Lock → Launch → Score` runs on a real device, in Demo Mode, with all permissions granted AND with all permissions denied, and produces the same result type (a `SimulationResult` with a `score` field). This is the single most important test in the plan.

## 9. Shared-spec parity test

Both the Dart and TypeScript implementations run `shared-spec/test-vectors.json` and produce the same `SimulationResult` for each vector (within 1e-6 floating-point tolerance). This is enforced by a CI step or, at minimum, a pre-commit checklist.

## Known / Proven / Planned / Unknown

- PROVEN: the three target pitch test points (TV-01, TV-02, TV-03) and the isClearToEject boundary (TV-04, TV-05, TV-06) are from the prototype.
- PLANNED: all other tests above.
- UNKNOWN: the exact device matrix for the manual device tests (determined at reference-build time).