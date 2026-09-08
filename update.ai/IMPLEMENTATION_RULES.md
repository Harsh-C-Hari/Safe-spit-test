# IMPLEMENTATION_RULES.md — SAFE//SPIT

> **Status:** PLANNED (new). Non-negotiable engineering rules. Any AI that ignores these breaks the project.

## Rule 1 — Preserve proven behavior

Any change to the proven calculator or HUD painter is a breaking change and must be explicitly justified in `update.ai/DECISIONS.md`. Do not "improve" `targetPitch(v)`, the 5° tolerance, or the `#39FF14` green without an explicit decision entry.

## Rule 2 — Simulation cannot import Flutter

Files in `app/lib/simulation/**` MUST compile without `package:flutter/...`. If a simulation file needs Flutter, it belongs in `game/` or `hud/`. This is the boundary that makes the simulation pure and cross-platform.

## Rule 3 — UI consumes NormalizedTelemetry, not raw sensor data

No screen, widget, or controller may import `geolocator`, `sensors_plus`, or `camera` directly. UI code reads `NormalizedTelemetry` and `SensorHealth` only. This is the seam that makes Demo Mode possible without code duplication.

## Rule 4 — Core game cannot depend on internet

The HUD, the lock, the launch, the score, and the result screen MUST all work in airplane mode. The lock tone is a local asset (D-2). No code path in the core loop makes a network call.

## Rule 5 — Demo Mode must always exist

There is always a path from the permission gate to the HUD via Demo Mode (D-1). The button is always visible when permissions are denied. The HUD always shows "DEMO MODE" when Demo Mode is active. Silent substitution is forbidden.

## Rule 6 — No unnecessary dependencies

Every new dependency is justified in `update.ai/DECISIONS.md` with a one-line reason. Do not add `provider`-alternative state libraries, animation libraries (no Rive, no Lottie), or marketing-site template packages. The reference build uses the prototype's compiled dependencies: `provider`, `audioplayers`, `geolocator`, `sensors_plus`, `camera`, `permission_handler`.

## Rule 7 — Test before expanding scope

The simulation test suite MUST pass before any new mode is added. The end-to-end integration test MUST pass before any new screen is added. See `docs/TEST_PLAN.md` and `shared-spec/test-vectors.json`.

## Rule 8 — Distinguish real sensor mode from simulation mode

The HUD MUST visibly indicate which mode is active. "DEMO MODE" in a corner. "PERMISSIONS DENIED" on the gate. A status indicator on the diagnostics screen. The user is never uncertain about what they are playing with.

## Rule 9 — Safety boundaries must remain intact

No copy instructs or encourages real spitting at people, vehicles, property, or wildlife. The "launch" is always a simulated, scored event. See `docs/PRODUCT_SPEC.md` "Safety / behavior boundaries." This is non-negotiable.

## Rule 10 — Lock-on / lock-off is edge-triggered

Audio and haptic fire on the false→true transition (and optionally the true→false transition for the lost-lock cue, A-tier). They do NOT fire continuously while locked. The `SpitLockController` uses a `wasClear` boolean (D-13). The prototype already uses this pattern — preserve it.

## Rule 11 — Determinism is a feature

No `DateTime.now()`, no `Random()`, no platform RNG in simulation or scoring. The same `(seed, telemetry log)` produces the same result, every time, on every device, on Android and on the website (D-11). This is what makes pass-and-play fair.

## Rule 12 — The reference build is a learning artifact, not the hackathon artifact

Do not "improve" the reference build mid-flight. If something is wrong, fix it. If something is missing, cut it. Do not add scope.

## Rule 13 — ESP32 is invisible

The Android app MUST compile and run with the `esp32/` directory deleted. No import, no dependency, no query. The ESP32 firmware (if it exists) is a wholly separate project. If it disappears, the app does not notice (D-7).

## Rule 14 — Use the existing test vector format

Any new test vector goes in `shared-spec/test-vectors.json` with the established shape (TV-NN-id, scenario, expected). Both the Dart and TypeScript implementations run every vector. No inline test vectors in code; the JSON is the source of truth.

## Rule 15 — Wind does not affect the lock

Wind affects `impactPosition`, `deviationM`, and the crosswind scoring only. The lock tolerance (`deltaDeg <= 5.0`) is wind-independent (D-5). This is the rule that keeps the WOW moment reliable indoors and out.

## Rule 16 — Negative speed is clamped

`targetPitch(-10) == targetPitch(0) == 45.0` (D-14, TV-07). Defensive, cheap, prevents a class of edge-case bugs. No simulation code may produce a `targetPitch` from a negative `speedKmh` without first clamping to 0.

## Rule 17 — Follow the implementation order

Do not start a phase until the prior phase's acceptance criteria pass (see `docs/IMPLEMENTATION_ORDER.md`). If Phase 5 reveals a Phase 1 bug, reopen Phase 1, do not patch around it. Cut features before cutting quality.

## Rule 18 — Update the failure log

Every meaningful failure discovered during the build goes in `FAILURE_LOG.md` with the format from that file. "Meaningful" = causes a real change in code, a real change in spec, or a real change in test coverage. Cosmetic failures do not go in.

## Rule 19 — Update the build manifest at the end of each phase

`BUILD-MANIFEST.md` is updated at the end of each phase, not at the end of the project. It is the snapshot of what the build actually contains, not what we hoped it would contain.

## Rule 20 — Vehicle profile identity

`Car` (id="car", turbulenceFactor=1.0, angleBias=0.0) is the identity profile. TV-08 asserts it. Any vehicle profile that breaks the identity (e.g. by changing the proven formula) is a regression and must be reverted or documented as a breaking change in `update.ai/DECISIONS.md`.
