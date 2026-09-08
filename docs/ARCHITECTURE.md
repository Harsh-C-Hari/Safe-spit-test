# ARCHITECTURE.md — SAFE//SPIT

## Reconciliation note (read this first)

The existing prototype (see `update.ai/DECISIONS.md` and the inspection notes below) implements a **flat, single-layer architecture**: three files (`main.dart`, `safe_spit_calculator.dart`, `safe_spit_sensor_manager.dart`) where the sensor manager talks almost directly to the UI via `setState`, and the calculator is a small pure class. This was appropriate for a single-screen proof of concept and is **proven to work**.

The latest plan's ambitions (vehicles, wind, Spit Olympics, shared Android/website simulation, multiplayer, Supabase) cannot be built on that flat structure without becoming unmaintainable. This document proposes a **layered architecture that generalizes the proven 3-file core** rather than replacing it — the existing calculator becomes the seed of the simulation layer, and the existing sensor manager becomes the seed of the sensor abstraction layer. Nothing proven is thrown away; it is promoted into a proper layer.

## Layers

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION (HUD, screens, painters, animations)       │
├─────────────────────────────────────────────────────────┤
│  GAME / APPLICATION (Spit Lock state machine, Spit       │
│  Olympics flow, scoring, Demo Mode, session state)        │
├─────────────────────────────────────────────────────────┤
│  SIMULATION (pure, deterministic — SIMULATION_SPEC.md)    │
├─────────────────────────────────────────────────────────┤
│  SENSOR ABSTRACTION (normalized telemetry stream)          │
├─────────────────────────────────────────────────────────┤
│  PLATFORM I/O (GPS, gyro, accelerometer, magnetometer,     │
│  camera, permissions, audio, haptics)                      │
└─────────────────────────────────────────────────────────┘

  SHARED (used by Android + website where practical):
  SIMULATION layer, scenario/seed model, scoring model,
  vehicle profile data, Spit Olympics rules.

  BACKEND (optional, never a hard dependency):
  Supabase — auth (anonymous), profiles, matches, scores.
```

### Why this layering, and not something fancier

The existing prototype already draws a (thin) line between pure logic (`SafeSpitCalculator`) and I/O (`SafeSpitSensorManager`). We are simply making that line real and extending it, not inventing new philosophy. Every layer above only talks to the layer directly below it through a small, explicit interface. UI code never touches a raw `Stream<GyroscopeEvent>` — it only ever sees normalized telemetry and simulation output.

## Data flow — the WOW moment

```
GPS speed (m/s) ──┐
                   ├─► SensorAbstraction ─► NormalizedTelemetry ─► Simulation
Gyro (rad/s, dt) ──┘         │                                        │
                              │ (fallback: Demo Mode synthetic feed)   │
                              ▼                                        ▼
                        SensorHealth (per-sensor status)         TrajectoryResult
                                                                       │
                                                                       ▼
                                                              SpitLockController
                                                          (SEARCHING → LOCKING → LOCK)
                                                                       │
                                                     ┌─────────────────┼─────────────────┐
                                                     ▼                 ▼                 ▼
                                                  HUD paint       Haptic pulse       Audio cue (once)
```

`NormalizedTelemetry` is the single seam between "real world" and "simulation." Demo Mode substitutes a synthetic `NormalizedTelemetry` stream at exactly this seam — nothing downstream needs to know the difference (see SENSOR_SPEC.md and DEMO_PLAN.md).

## State flow

- **SensorHealth** (per sensor: `available | permissionDenied | unavailable | noisy | ok`) is tracked independently per input (GPS, gyro, accelerometer, magnetometer, camera). It is never silently swallowed — it is visible in a diagnostics panel and drives fallback behavior.
- **SimulationState**: input snapshot → deterministic output. Stateless per tick; the only state that persists across ticks is the smoothed/integrated pitch value and the lock-progress timer, both of which live in the SIMULATION layer's small internal state object, not in widgets.
- **GameState**: `Idle → HudLive → Locking → Locked → Launched → Scored`. Spit Olympics adds a parallel `MatchState` (`WaitingForScenario → Playing → Submitted → Comparing → Result`).

## UI flow

`PermissionGate` (proven — reuse) → `HudScreen` (camera + reticle + telemetry bars, proven — generalize) → optional `VehicleSelectScreen` (new) → `SpitOlympicsScreen` (new) → `ResultScreen` (new) → optional `LeaderboardScreen` (new, requires backend).

## Backend flow

Supabase is called only from a thin `BackendGateway` interface with two implementations: `SupabaseBackendGateway` and `NoopBackendGateway` (used automatically when Supabase is unreachable or unconfigured). Every screen above codes against `BackendGateway`, never against the Supabase client directly. This guarantees the "local simulator must remain usable if Supabase is unavailable" rule in section 17 of the master plan is structurally enforced, not just promised.

## Website flow

The website consumes the **same simulation rules** (SIMULATION_SPEC.md) either via a literal ported/shared implementation (if the team is comfortable maintaining two small parallel implementations of one deterministic formula) or via a JSON scenario/result contract validated by shared test vectors. See WEBSITE_SPEC.md and MULTIPLAYER_SPEC.md for the concrete recommendation (shared-spec, not shared-runtime, is the safer default — see DECISIONS.md).

## Multiplayer flow

Plan B (deterministic pass-and-play) sits entirely inside the GAME layer using the existing SIMULATION layer twice with the same scenario seed — no new architecture required. Plan A (online) adds a thin `MatchService` on top of `BackendGateway` and is additive, not a fork of the game logic. See MULTIPLAYER_SPEC.md.

## Fallback flow (cross-cutting)

Every layer boundary has an explicit fallback:

| Layer boundary | Failure | Fallback |
|---|---|---|
| Platform I/O → Sensor Abstraction | GPS unavailable/denied | Sensor marked `unavailable`; Demo Mode speed source substituted if Demo Mode is on, else speed pinned at 0 with visible diagnostic |
| Platform I/O → Sensor Abstraction | Gyro unavailable | Same pattern; pitch pinned at last-known or 45° default |
| Platform I/O → Sensor Abstraction | Camera denied | HUD renders on black background instead of camera texture; everything else still works |
| Simulation → Game | n/a (pure function, cannot "fail") | N/A — this is why it must stay pure |
| Game → Backend | Supabase unreachable/misconfigured | `NoopBackendGateway`; scores kept locally only, user is told plainly ("not saved online") |
| Multiplayer Plan A → Plan B | Match server unreachable | Automatic offer to fall back to pass-and-play with the same scenario seed |

## Known / Proven / Planned / Unknown (architecture-level)

- **PROVEN:** flat 3-file Flutter structure with a pure calculator and a stream-driven sensor manager works end-to-end on a real build (confirmed via APK teardown — see TECH_STACK.md).
- **PLANNED:** the layered structure above is the target for the reference build; it is a deliberate generalization of the proven structure, not a rewrite from scratch.
- **PROPOSED:** `BackendGateway`/`NoopBackendGateway` pattern, `MatchService`, shared-spec website strategy — these are architectural recommendations with no prior art in the existing prototype.
- **UNKNOWN / REQUIRES VALIDATION:** whether `provider` (present as a compiled dependency in the prototype but not confirmed as the active state-management approach from static analysis) is meant to be the state-management layer going forward, or was pulled in transitively. Antigravity should confirm by reading `pubspec.yaml` and `main.dart` directly before assuming `provider` is load-bearing.

## Reconciliation with the planning package

This file is a faithful record of the planned layered architecture. It has been light-edited to align with the planning package. Key decisions reflected here:

- **`NormalizedTelemetry` is the sensor/UI seam.** UI code (HUD, game state, match state) consumes `NormalizedTelemetry` and `SensorHealth` only. No screen or widget may import `geolocator`, `sensors_plus`, or `camera` directly. See `docs/SENSOR_SPEC.md` and Rule 3 in `update.ai/IMPLEMENTATION_RULES.md`.
- **`BackendGateway` interface is structural, not optional.** The default implementation is `NoopBackendGateway`; `SupabaseBackendGateway` is added later. The interface makes the offline-first property structural, not a code-review hope (D-9).
- **`provider` is the state-management layer, deliberately.** Confirmed: `provider` is the choice (D-8, D-16). `ChangeNotifier` for mutable state, `InheritedNotifier` for context plumbing.
- **ESP32 is invisible to the Android app** (D-7, Rule 13). The Android app MUST compile and run with the `esp32/` directory deleted.

The full decision log is in `update.ai/DECISIONS.md`. The implementation order is in `docs/IMPLEMENTATION_ORDER.md`. The full planning package is in `docs/`.
