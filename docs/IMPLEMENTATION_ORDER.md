# IMPLEMENTATION_ORDER.md — SAFE//SPIT

> **Status:** PLANNED (new). The exact sequence Antigravity builds in. Do not start a phase until the prior phase's acceptance criteria are met.
> **Cross-references:** `RISK_REGISTER.md` (each phase's risk), `TEST_PLAN.md` (each phase's tests), `DEMO_PLAN.md` (the final phase validates the demo), `PROJECT_STRUCTURE.md` (directory layout).

## Phase 0 — Repository setup (Priority: S)

- **Objective:** Create the `app/`, `website/`, `shared-spec/`, `update.ai/`, `backend/`, `esp32/` directory skeleton. Create the `app/` Flutter project (`flutter create app --org com.safespit --project-name safespit --platforms android`).
- **Files:** repo root, `app/`, `website/`, `shared-spec/`, `update.ai/`, `backend/`, `esp32/` (placeholder only).
- **Dependencies:** none.
- **Acceptance:** `flutter build apk --debug` produces a hello-world APK; `app/lib/main.dart` is the only file with a `main()`.
- **Tests:** none yet.
- **Fallback:** none.

## Phase 1 — Preserve proven prototype (Priority: S)

- **Objective:** Copy `safe_spit_calculator.dart` into `app/lib/simulation/safe_spit_calculator.dart` and `safe_spit_sensor_manager.dart` into `app/lib/sensors/sensor_manager.dart`. Do not change behavior. Add the unit tests for the proven formula. Add the local `lock_tone.mp3` asset.
- **Files:** `app/lib/simulation/safe_spit_calculator.dart`, `app/lib/sensors/sensor_manager.dart`, `app/assets/audio/lock_tone.mp3`, `app/test/simulation/safe_spit_calculator_test.dart`.
- **Dependencies:** Phase 0.
- **Acceptance:** The three proven test points pass (TV-01, TV-02, TV-03); the prototype's HUD logic is byte-equivalent in behavior; the lock tone plays from a local asset.
- **Tests:** `targetPitch(0)=45`, `targetPitch(50)=57`, `targetPitch(200)=85`, `isClearToEject` boundary tests.
- **Fallback:** If `lock_tone.mp3` cannot be sourced, use `audioplayers` with a generated WAV (D-18).

## Phase 2 — Normalized telemetry seam (Priority: S)

- **Objective:** Introduce `NormalizedTelemetry` and `SensorHealth` types. Adapt the existing sensor manager to emit a `Stream<NormalizedTelemetry>` rather than loose fields. Add a `DemoModeSource` that produces a deterministic `NormalizedTelemetry` stream.
- **Files:** `app/lib/sensors/normalized_telemetry.dart`, `app/lib/sensors/sensor_health.dart`, `app/lib/sensors/demo_mode_source.dart`, `app/lib/sensors/sensor_manager.dart` (adapted).
- **Dependencies:** Phase 1.
- **Acceptance:** The existing widget tree can be wired to the normalized stream with no behavioral change; `DemoModeSource` produces a known sequence of telemetry; `SensorHealth` correctly transitions on stream errors.
- **Tests:** `NormalizedTelemetry` construction; `DemoModeSource` determinism; `SensorHealth` transition on injected stream errors.
- **Fallback:** If the existing sensor manager cannot be cleanly adapted, introduce a `LegacySensorAdapter` that wraps it and emits the new stream type.

## Phase 3 — Permission gate with Demo Mode entry (Priority: S)

- **Objective:** Extend the proven `PermissionGate` with an "ENTER DEMO MODE" button. The button is visible alongside the existing "SYSTEM LOCKED" message. Tapping it routes to the HUD in Demo Mode.
- **Files:** `app/lib/hud/permission_gate.dart` (extended), `app/lib/sensors/demo_mode_source.dart` (wired).
- **Dependencies:** Phase 2.
- **Acceptance:** The gate still blocks the HUD when permissions are denied AND the user has not opted into Demo Mode; the gate offers Demo Mode as a clearly labeled action; selecting Demo Mode routes to a HUD that displays "DEMO MODE" in a visible corner.
- **Tests:** Widget test for the gate; integration test for the Demo Mode entry path.
- **Fallback:** If the gate is technically difficult to extend, split it into `permission_gate.dart` (the lock screen) and `demo_mode_entry.dart` (the button + routing). The user-facing behavior is identical.

## Phase 4 — Simulation core (Priority: S)

- **Objective:** Complete the simulation layer beyond the proven calculator. Add `trajectory_model.dart`, `vehicle_profiles.dart`, `scenario.dart`, `scoring.dart`. The `Car` profile is the identity profile.
- **Files:** `app/lib/simulation/*` (full set), `shared-spec/scenario.schema.json`, `shared-spec/result.schema.json`, `shared-spec/test-vectors.json`.
- **Dependencies:** Phase 1.
- **Acceptance:** The simulation is a pure function of `ScenarioInput + NormalizedTelemetry snapshot`, produces `SimulationResult`, is deterministic, and is fully unit-testable without Flutter. The shared-spec test vectors all pass.
- **Tests:** Full simulation unit test suite; parity test that runs `test-vectors.json` on both Dart and TypeScript.
- **Fallback:** If vehicle profiles are too much, ship the reference build with only `Car` + a single "test" profile. Other vehicles come in Phase B.

## Phase 5 — HUD (Priority: S)

- **Objective:** Extend the proven `MissileLockReticlePainter` with planned elements (trajectory line, target marker, wind indicator, vehicle indicator, mission panel). The HUD consumes `NormalizedTelemetry` and `SimulationResult` only.
- **Files:** `app/lib/hud/hud_screen.dart`, `app/lib/hud/missile_lock_reticle_painter.dart` (extended), `app/lib/hud/telemetry_bars.dart`, `app/lib/hud/diagnostics_panel.dart`.
- **Dependencies:** Phase 2, Phase 4.
- **Acceptance:** The HUD runs the WOW moment (move phone → HUD reacts → lock → score) in both real sensor and Demo Mode. Reticle sizing responds to `MediaQuery` (not hardcoded). All draw calls are inside `CustomPainter.paint`.
- **Tests:** Widget test for reticle paint; integration test for HUD reads from normalized telemetry.
- **Fallback:** Ship the proven reticle + only the trajectory line. Other elements come in Phase B.

## Phase 6 — Lock system (Priority: S)

- **Objective:** Implement `SpitLockController` as an edge-triggered state machine. Wire it to the HUD. The audio + haptic cue fires once on each transition, not continuously.
- **Files:** `app/lib/game/spit_lock_controller.dart`, `app/lib/game/game_state.dart`, `app/lib/services/audio_service.dart` (lock-tone player), `app/lib/services/haptic_service.dart` (HapticFeedback wrapper).
- **Dependencies:** Phase 4, Phase 5.
- **Acceptance:** Lock transitions on the false→true and true→false edges; audio plays once per transition (test verifies by counting audio events); haptic fires on lock; the lost-lock cue (true→false) is a planned, optional A-tier feature.
- **Tests:** Edge-triggered transition test; audio event count test; haptic count test.
- **Fallback:** If the lost-lock cue is unstable, drop it from the reference build (it is A-tier).

## Phase 7 — Demo Mode end-to-end (Priority: S)

- **Objective:** Integrate Demo Mode through the full stack. The reference build must be runnable on an emulator with no sensors, no GPS, no camera, and no network.
- **Files:** Integration of all prior phases.
- **Dependencies:** Phase 6.
- **Acceptance:** `flutter run` on a freshly created Android emulator with all permissions denied shows the gate, accepts the Demo Mode entry, runs the HUD, achieves lock, and produces a score — all without errors.
- **Tests:** The full e2e test in `TEST_PLAN.md` runs green in Demo Mode.
- **Fallback:** If the integration reveals a real bug in any prior phase, the prior phase is re-opened, not patched around.

## Phase 8 — Vehicle system (Priority: A)

- **Objective:** Implement the vehicle selector screen and the vehicle profile data. The Car profile is the identity profile. Other vehicles add small bias and wind sensitivity.
- **Files:** `app/lib/screens/vehicle_select_screen.dart`, `app/lib/simulation/vehicle_profiles.dart` (full data).
- **Dependencies:** Phase 4.
- **Acceptance:** Selecting a vehicle updates the HUD's vehicle indicator and the simulation's `vehicle` field; the Car profile produces identical results to the no-vehicle simulation.
- **Tests:** Vehicle modifier identity test; non-Car modifier test.
- **Fallback:** Ship with Car only; defer the rest to Phase B.

## Phase 9 — Scoring and result screen (Priority: S for simulator, A for leaderboard)

- **Objective:** Implement the scoring function and the result screen. The result screen shows score breakdown, mission card, and "try again" / "share" / "submit to leaderboard" actions.
- **Files:** `app/lib/simulation/scoring.dart` (full), `app/lib/screens/result_screen.dart`.
- **Dependencies:** Phase 6.
- **Acceptance:** Scoring is deterministic; the same `(seed, telemetry log)` produces the same score; the result screen renders all dimensions.
- **Tests:** Scoring determinism test; scoring edge cases (perfect lock, near-miss, lost lock).
- **Fallback:** If the share action is unstable, drop it; submit-to-leaderboard is wired but not yet used (Noop backend in reference build).

## Phase 10 — Pass-and-play (Priority: A)

- **Objective:** Implement Plan B multiplayer. Two players on one device, deterministic scenario, score comparison.
- **Files:** `app/lib/game/match_state.dart`, `app/lib/screens/spit_olympics_screen.dart`.
- **Dependencies:** Phase 9.
- **Acceptance:** Two players can complete a pass-and-play match on one device with identical conditions; a winner is named; the match is recorded locally.
- **Tests:** Pass-and-play parity test (both players get same `targetPitch(v)` and `trajectory` for same seed).
- **Fallback:** If the tournament bracket is too much, ship with single-match pass-and-play only.

## Phase 11 — Spit Olympics (Priority: A)

- **Objective:** Add the modes (Target Strike, Crosswind, Vehicle Challenge) on top of the base game loop.
- **Files:** Extension of `app/lib/game/`, `app/lib/simulation/`.
- **Dependencies:** Phase 10.
- **Acceptance:** Each mode is selectable from the Spit Olympics screen, runs the same base loop, and applies its mode-specific scoring.
- **Tests:** Per-mode scoring tests; cross-mode determinism.
- **Fallback:** Ship with two modes only; defer the rest.

## Phase 12 — Backend wiring (Priority: A)

- **Objective:** Implement `SupabaseBackendGateway` and wire it behind `BackendGateway`. Submit a score, fetch the leaderboard, handle network errors. The reference build may ship with `NoopBackendGateway` only.
- **Files:** `app/lib/backend/*`, `backend/migrations/*.sql`.
- **Dependencies:** Phase 9.
- **Acceptance:** With Supabase configured, scores are submitted; without Supabase, scores are kept locally and the user sees "not saved online."
- **Tests:** Gateway interface tests with both implementations; offline behavior test (airplane mode).
- **Fallback:** Ship the reference build with `NoopBackendGateway` only; wire the Supabase implementation later if time allows.

## Phase 13 — Website (Priority: A)

- **Objective:** Build the website's interactive simulator and the shareable seed URLs. The website uses the same `shared-spec/` and the same `test-vectors.json`.
- **Files:** `website/`, `shared-spec/`.
- **Dependencies:** `shared-spec/` is final (from Phase 4).
- **Acceptance:** The website's simulator runs the same scenarios as the app; the shareable seed URL produces identical conditions for a second visitor; the leaderboard page handles offline gracefully.
- **Tests:** Shared-spec parity test (both implementations run `test-vectors.json` and produce the same result).
- **Fallback:** Ship the cinematic intro + the simulator page only; defer the leaderboard and Spit Olympics web pages.

## Phase 14 — Sensor diagnostics (Priority: A)

- **Objective:** Implement the diagnostics screen that shows live `SensorHealth` per sensor.
- **Files:** `app/lib/screens/diagnostics_screen.dart`.
- **Dependencies:** Phase 2.
- **Acceptance:** Each sensor has a visible status; permission state is shown; Demo Mode is visible from this screen too.
- **Tests:** Widget test for the diagnostics screen.
- **Fallback:** Ship the diagnostics as a debug-only screen (gated by a long-press or a `?debug=1` URL).

## Phase 15 — Haptics and audio polish (Priority: A)

- **Objective:** Refine the haptic patterns and add a "lost lock" cue.
- **Files:** `app/lib/services/haptic_service.dart` (full), `app/lib/services/audio_service.dart` (full).
- **Dependencies:** Phase 6.
- **Acceptance:** Every documented state transition has a haptic pattern; haptics do not fire if the device has no vibrator; audio works in airplane mode (local asset only).
- **Tests:** Pattern list test; missing-vibrator test; airplane-mode test.
- **Fallback:** Ship with single-pulse haptics only.

## Phase 16 — Optional polish (Priority: B/C)

- **Objective:** AI Commander, voice control, ESP32 experiment, operator profiles, tournament mode, advanced replay, easter eggs. All optional. Cut from the reference build if time is short.
- **Files:** Per-feature.
- **Dependencies:** All S/A work is stable.
- **Acceptance:** Features that ship are listed in `BUILD-MANIFEST.md`; features that don't are listed in the failure log.
- **Tests:** Per-feature.
- **Fallback:** Drop any feature that does not pass its own acceptance criteria; do not "almost ship" optional work.

**Cut order (from plan.md section 65):** easter eggs → AI Commander → extra hardware → online multiplayer → voice → complex replay → advanced website → tournaments → non-essential vehicle profiles. **Never cut:** HUD, sensor response, vehicle selector (Car), trajectory, Spit Lock, core simulation, Demo Mode, basic scoring, phone-only operation.

## Phase 17 — Full validation (Priority: S)

- **Objective:** Run the entire test plan; run the demo script; record all failures; produce the build manifest.
- **Files:** `FAILURE_LOG.md`, `BUILD-MANIFEST.md`, `DEVICE-TEST-CHECKLIST.md`, `demo-recording.mp4`.
- **Dependencies:** All prior phases that are claimed complete.
- **Acceptance:** The reference build is "done" when (a) every S-tier test passes, (b) every documented robustness condition in `DEMO_PLAN.md` is exercised, (c) `FAILURE_LOG.md` is complete and honest, (d) `BUILD-MANIFEST.md` is accurate.
- **Tests:** The full test plan, the full demo script, the full device checklist.
- **Fallback:** If a robustness condition cannot be satisfied, the failure is documented, and the build is still frozen with that known issue. The Phase B hackathon plan is then written around the known issue.