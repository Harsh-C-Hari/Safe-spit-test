# GAME_SPEC.md — SAFE//SPIT

> **Status:** PLANNED (new). Reconciles the product-level game design from `plan.md` with the proven simulation core from `IMPLEMENTATION_PLAN.md` and `SIMULATION_SPEC.md`.
> **Cross-references:** `SIMULATION_SPEC.md`, `MULTIPLAYER_SPEC.md`, `IMPLEMENTATION_ORDER.md`, `HUD_SPEC.md`, `shared-spec/scenario.schema.json`, `shared-spec/result.schema.json`.

## 1. The game loop (single-player core)

The core loop is the WOW moment from `PRODUCT_SPEC.md`. It is a strict state machine; every transition is deterministic given the same `NormalizedTelemetry` snapshot and the same `Scenario`.

State machine: `Idle → HudLive → Locking → Locked → Launched → Scored`. Transitions:
- Idle → HudLive: permissions granted OR Demo Mode entered (D-1).
- HudLive → Locking: first tick where `deltaDeg` is computed and decreasing.
- Locking → Locked: `deltaDeg <= 5.0` (proven tolerance).
- Locked → Locking: `deltaDeg > 5.0` (lock lost). Optional "lost lock" cue fires on this edge (A-tier).
- Locked → Launched: user action OR a configurable hold-timer.
- Launched → Scored: score computed from frozen snapshot (deterministic, D-11).
- Scored → Idle: user taps "Try again" or "New scenario".

Critical invariants:
- The `Simulation` is a pure function of `Scenario + NormalizedTelemetry snapshot`. No side effects, no hidden state beyond the integrated pitch value (which lives in the sensor layer).
- The `SpitLockController` is edge-triggered (D-13). Audio and haptic fire once per transition, not per frame.
- The `Launched` state is a freeze: the simulation snapshot is captured at launch and the score is computed from that frozen snapshot.

## 2. Mode catalog (priority per mode)

| Mode | Priority | Description | What it changes |
|---|---|---|---|
| Precision Spit | S | Closest to the optimal trajectory over a fixed window. | Scoring weights `precision` and `stability` highest. |
| Speed Lock | S | Fastest lock acquisition. | Scoring weights `timing` highest; countdown timer on HudLive. |
| Demo Run | S | Zero-config flow; default entry point. | Uses Demo Mode telemetry; no permissions; no online score. |
| Target Strike | A | Hit a simulated target at a distance. | Adds `impactPosition`/`deviationM` to scoring; target distance from seed. |
| Crosswind Challenge | A | Wind affects impact point (never the lock). | `windSpeedKmh`/`windDirectionDeg` non-zero; `windSensitivity` from vehicle. |
| Vehicle Challenge | A | Per-vehicle mission pack. | Vehicle profile selected, not defaulted to Car. |
| Pass-and-Play Tournament | A | Local 2-4 player, same seed, deterministic. | See `MULTIPLAYER_SPEC.md`. |
| Chaos Mode | B | Unstable gyro + random target jitter. | Adds noise to telemetry; for fun, not demo. |
| Blind Mode | B | Reduced HUD info (no trajectory line, no target marker). | HUD variant only; simulation unchanged. |
| Online Tournament | B | Plan A multiplayer over Supabase. | Additive; cannot ship if Plan B doesn't work. |
| Any mode requiring new sensors | C | — | Cut first. |

Cut rule: any mode that does not pass the reference build's playtesting is removed, not patched. See `IMPLEMENTATION_ORDER.md` Phase 16 and `RISK_REGISTER.md` R-13.

## 3. Vehicle profile system

A vehicle profile is a typed data record (see `shared-spec/scenario.schema.json`):

VehicleProfile { id (snake_case, "car" is identity), displayName, turbulenceFactor (Car=1.0), angleBias (Car=0.0), windSensitivity (Car=1.0), difficulty (0.0..1.0) }

D-4 (identity): the Car profile reproduces the proven formula exactly. Asserted by `shared-spec/test-vectors.json` TV-08.

Other vehicles (Bus, Bike, Auto, Train, Tractor, Aircraft, Walking, Other) are PLANNED but their exact numeric values are UNKNOWN until Phase A playtesting. The reference build ships Car plus one or two test profiles.

Fictional, not realistic: the profiles are hand-authored, explicitly fictional. No claim of physical realism.

## 4. Scenario seed system

A scenario is fully determined by a 6-character uppercase hex `seed` plus a `mode` plus a `vehicle`. The seed is the only source of randomness (D-11). It deterministically derives: wind speed/direction, target distance, and mode-specific modifiers.

Format: 6 hex chars, case-insensitive on input, uppercase on output. Copyable. Used in shareable URLs (`/play?seed=8F42A7&vehicle=car`) and pass-and-play.

Determinism guarantee: same seed + vehicle + mode + telemetry = same result, on both Android and website (D-3, D-11).

## 5. Scoring

Scoring is a pure, deterministic function of `SimulationResult` (and, for timing, the lock window duration). No `Random()`, no `DateTime.now()` (D-11).

score = baseScoreForLock(lockQuality) - distancePenalty(deviationM) + timingBonus(timeToLockMs) + modeBonus(mode, result)

`scoreBreakdown` is always returned with `score` (see `shared-spec/result.schema.json`): precision, impact, timing, stability, style. `style` is cosmetic-only and never affects ranking.

Constants are UNKNOWN at planning time; tuned during Phase A playtesting, recorded in `update.ai/DECISIONS.md`. The formula's shape is fixed; the constants are not.

Mode-specific scoring variants: precision (precision+stability weights), speed_lock (timing weight, countdown timer), target_strike (impact weight, deviationM matters), crosswind (impact+precision, wind non-zero), vehicle_challenge (per-vehicle weights from difficulty), chaos (precision + injected noise), blind (precision, HUD hides trajectory).

## 6. Lock quality

lockQuality is 0.0..1.0, the smoothed average of `1 - (deltaDeg / 5.0)` over held-lock samples, clamped to [0,1]. 1.0 = perfectly centered; 0.0 = barely inside. Updated each tick while isClearToEject is true; frozen at Launched. PLANNED, not PROVEN.

## 7. Pass-and-play

See `MULTIPLAYER_SPEC.md` for full detail. Plan B (pass-and-play) is the default.

## 8. Tournament

A sequence of pass-and-play matches with a deterministic bracket. Bracket seed derived from the first match's seed. 2-4 players. Same scoring function; winner is highest total score. A-tier; reuses pass-and-play infrastructure.

## 9. Replay

A deterministic playback from a recorded (scenarioSeed, sensorLog) tuple. sensorLog is a sequence of NormalizedTelemetry snapshots. Replaying through the same Simulation produces the same SimulationResult (D-11). B-tier for the reference build; the data structure is defined now so it can be added without a schema change.

## 10. Safety / behavior boundaries

No feature encourages or instructs real spitting at people, vehicles, property, or wildlife. The "launch" is always a simulated, scored event. See `PRODUCT_SPEC.md` "Safety / behavior boundaries."

## Known / Proven / Planned / Unknown

- PROVEN: the core targetPitch formula, isClearToEject tolerance, edge-triggered lock pattern.
- PLANNED: lockQuality, full mode catalog, scoring constants, vehicle profiles beyond Car, tournament bracket, replay.
- PROPOSED: the exact scoring constants (tuned in Phase A).
- UNKNOWN: whether lockQuality smoothing feels good on a real device; whether mode-specific scoring weights produce a satisfying spread.