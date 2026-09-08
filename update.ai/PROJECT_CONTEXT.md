# PROJECT_CONTEXT.md — SAFE//SPIT

> **Status:** PLANNED (new). A 60-second read for an AI that has never seen SAFE//SPIT.
> **Cross-references:** all of `docs/`, all of `shared-spec/`.

## What this is

SAFE//SPIT is a deliberately absurd fighter-jet-HUD simulator for "the optimal angle to spit from a moving vehicle." The user holds a phone, tilts it to the target angle, and "fires" — all simulated, all scored, all absurd on purpose.

## The joke (one sentence)

"After eight years of R&D, we finally answered the question no one asked: at what angle should you spit from a moving car, bus, train, or aircraft?"

## Reference build vs. hackathon build

- **Phase A — Reference/Validation build:** the safety net. Built from a complete planning package. Validates the core loop, the demo, the determinism, and the shared-spec contract. Can be shipped if the hackathon is cancelled.
- **Phase B — Hackathon build:** the public version. Implemented from a clean start based on the validated plan.

## Tech stack

- **Android app:** Flutter / Dart. The prototype is a JIT/debug APK that proves the core loop.
- **Simulation:** Dart (Android) + TypeScript (website). Two parallel implementations, one shared JSON contract.
- **Sensors:** `geolocator` (GPS), `sensors_plus` (gyro/accelerometer/magnetometer), `camera` (HUD passthrough).
- **Audio:** `audioplayers` with a local asset (lock tone is bundled, not networked).
- **State:** `provider` (already compiled in the prototype).
- **Backend (optional):** Supabase (Postgres + RLS + Realtime). The reference build ships with a Noop default; the Supabase implementation is additive.
- **Website:** Next.js or SvelteKit (deferred to implementation).
- **ESP32:** optional, isolated from the Android app (invisible dependency).

## Architecture layers (one diagram)

```
[ Presentation ]   HUD, reticle, telemetry bars, result screen
       |
[   Game    ]     State machine: lock controller, match state, scoring wiring
       |
[ Simulation ]    Pure functions: pitch formula, trajectory, scoring, vehicle modifiers
       |
[  Sensor    ]    NormalizedTelemetry stream; DemoModeSource; SensorHealth
       |
[ Platform I/O ]  geolocator, sensors_plus, camera, audioplayers, HapticFeedback
```

Cross-cutting: `BackendGateway` (Supabase or Noop) — present in every layer that needs persistence.

## PROVEN / PLANNED / PROPOSED / UNKNOWN roll-up

- **PROVEN** (from the prototype APK teardown): the target-pitch formula `targetPitch(v) = clamp(45 + (v/5) * 1.2, 45, 85)`, the 5° lock tolerance, the `MissileLockReticlePainter` with `#39FF14` tactical green, the GPS→km/h pipeline, the gyro dt-integration, the camera passthrough with 5% green tint, the `PermissionGate` "SYSTEM LOCKED" screen, the edge-triggered lock audio.
- **PLANNED:** NormalizedTelemetry as the sensor/UI seam; Demo Mode entry on the permission gate; shared-spec JSON contract; pass-and-play multiplayer; per-vehicle profiles; per-mode scoring; the website simulator; the Supabase leaderboard; the danger/red HUD state.
- **PROPOSED:** complementary-filter drift correction for pitch; per-mode scoring constants tuned in Phase A; Next.js vs SvelteKit (deferred).
- **UNKNOWN:** exact `LocationAccuracy` setting; exact on-screen behavior on sensor stream errors today; real-world drift magnitude; brand final name (working: SAFE//SPIT).

## Links to the other docs

- `IMPLEMENTATION_PLAN.md` — older prototype-aligned plan, reconciled with this package.
- `plan.md` — master plan, product vision.
- `docs/PRODUCT_SPEC.md` — product definition, safety boundaries.
- `docs/ARCHITECTURE.md` — layered architecture, BackendGateway pattern.
- `docs/PROJECT_STRUCTURE.md` — directory layout.
- `docs/TECH_STACK.md` — dependency decisions, lock tone.
- `docs/SIMULATION_SPEC.md` — simulation contract, cross-platform strategy.
- `docs/SENSOR_SPEC.md` — sensor fallbacks, NormalizedTelemetry shape.
- `docs/HUD_SPEC.md` — reticle, lock transition, colors.
- `docs/GAME_SPEC.md` — game loop, mode catalog, scoring.
- `docs/MULTIPLAYER_SPEC.md` — pass-and-play (Plan B), online (Plan A).
- `docs/SUPABASE_SPEC.md` — schema, RLS, BackendGateway interface.
- `docs/WEBSITE_SPEC.md` — page flow, interaction model, accessibility.
- `docs/TEST_PLAN.md` — unit, integration, widget, device, e2e.
- `docs/DEMO_PLAN.md` — the 90-second judge demo.
- `docs/RISK_REGISTER.md` — 20 risks, P0/P1/P2.
- `docs/IMPLEMENTATION_ORDER.md` — Phase 0 through Phase 17.
- `update.ai/IMPLEMENTATION_RULES.md` — non-negotiable engineering rules.
- `update.ai/DECISIONS.md` — D-1 through D-20, the decision log.
- `update.ai/CURRENT_STATUS.md` — the snapshot of where the project is right now.
- `shared-spec/scenario.schema.json`, `result.schema.json`, `test-vectors.json` — the cross-platform contract.
