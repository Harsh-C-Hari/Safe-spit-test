# PRODUCT_SPEC.md — SAFE//SPIT

## What SAFE//SPIT is

SAFE//SPIT is a deliberately, absurdly over-engineered "tactical aerospace instrumentation system" for calculating the optimal angle to spit out of a moving vehicle. It presents a fictional/proprietary ballistics heuristic through a fighter-jet HUD aesthetic, driven by real phone sensors (GPS speed, gyroscope pitch), with a lock-on/lock-tone interaction lifted straight from missile-lock UX tropes.

The joke is the point. The engineering under the joke is not a joke — real sensors, a deterministic simulation core, a competitive game mode ("Spit Olympics"), a companion website, and (optionally) a small hardware demo (ESP32) are all real, working systems. Nothing about the *physics* is scientifically validated; everything about the *software* should be.

## Target experience

A judge, teammate, or random person picks up the phone, moves it around, and within seconds:
1. Sees a live camera feed with a green tactical HUD overlay.
2. Sees real numbers changing as they move the phone (speed from GPS or Demo Mode, pitch from gyro).
3. Watches a reticle track toward a "lock" state as they tilt the phone toward the computed target angle.
4. Feels a haptic pulse and hears a tone the instant lock is achieved.
5. Gets a "simulated launch" and a score.

That loop — real sensor input → visible HUD reaction → lock → feedback → score — **is the product**. Everything else (vehicles, wind, Spit Olympics, website, multiplayer, Supabase, ESP32) is in service of making that loop richer, more replayable, or more shareable. Nothing is allowed to make that loop less reliable.

## Core user journey (reference build)

```
Open app
  → Permission gate (camera + location)
  → HUD live (camera passthrough + green tint + reticle + telemetry)
  → Move phone → pitch reacts, speed reacts (GPS or Demo Mode)
  → Angle enters tolerance window → SPIT LOCK
  → Haptic + audio cue (local asset, not network-dependent — see DECISIONS.md)
  → Simulated launch → score/result shown
  → (optional) Try Spit Olympics pass-and-play
  → (optional) Save/share result
```

## The joke / concept

SAFE//SPIT is framed as a proprietary "aerodynamic departure system" that exists to prevent "boundary-layer eddy recirculation" and "fluid blowback" — invented pseudo-aerospace terminology applied, completely straight-faced, to spitting out of a car window. The comedy comes entirely from the mismatch between the seriousness of the presentation and the triviality of the task. The product must never wink at the user or break character with a "lol just kidding" tone — the HUD, the terminology, and the audio design all play it completely straight.

## Major experiences (priority order — see RISK_REGISTER.md and IMPLEMENTATION_ORDER.md for sequencing)

1. **Phone-only Android core** — the tactical HUD, real sensors, physics, Spit Lock. Must work with zero network and zero ESP32.
2. **Spit Olympics** — deterministic, seeded, same-conditions competitive mode (pass-and-play first, online second).
3. **Companion website** — a premium, editorial, non-generic interactive site with its own local simulator using the same physics rules.
4. **Backend (Supabase)** — anonymous-first leaderboard, callsigns, match history. Strictly optional; nothing above breaks without it.
5. **ESP32 hardware demo** — a bonus, entirely optional physical prop that the phone never depends on.

## Feature priorities (S/A/B/C)

See `RISK_REGISTER.md` for probability/impact and `IMPLEMENTATION_ORDER.md` for build sequencing. Summary:

- **S (must work):** Android app, tactical HUD, GPS speed, gyro pitch, vehicle-agnostic trajectory calc, Spit Lock, camera passthrough, local audio + haptic feedback, Demo Mode, basic scoring, phone-only operation, sensor/permission fallbacks.
- **A (high value):** vehicle selector, wind visualization, sensor diagnostics screen, Spit Olympics (pass-and-play), leaderboard, anonymous users, Supabase, website, website simulator.
- **B (optional):** AI Commander/voice, ESP32, operator profiles, tournament mode, replay, online (networked) multiplayer.
- **C (last):** Easter eggs, extra jokes, cosmetic telemetry, gimmicks.

## Success criteria for the reference build

- The core WOW loop (move phone → HUD reacts → lock → feedback → score) works reliably on at least one real Android device, indoors and outdoors, with and without a network connection.
- Nothing in the reference build crashes on missing camera, missing/denied location, or missing network.
- The physics model, sensor fusion approach, and known limitations (see SENSOR_SPEC.md, especially gyro drift) are documented well enough that a fresh Antigravity agent does not need to reverse-engineer the prototype to continue building.
- We know, in writing, what is PROVEN, what is PLANNED, and what is still UNKNOWN (see section "Known / Proven / Planned / Unknown" in each spec file, and the roll-up in RISK_REGISTER.md).

## Non-goals for the reference build

- Not building final hackathon polish — this is a validation/reference build meant to surface problems early.
- Not implementing online multiplayer before pass-and-play multiplayer is solid.
- Not implementing the full website before the Android phone-only core is solid.
- Not treating the ESP32 as a dependency of anything.
- Not presenting the physics as real ballistics/aerodynamics anywhere in-product, in marketing copy, or in the website.

## Safety / behavior boundaries

- The product is a simulation. No feature should encourage or instruct real spitting at people, vehicles, property, traffic, or wildlife. All "launches" are simulated/scored events, not literal instructions.
- No feature should encourage unsafe behavior while a vehicle is in motion (e.g., using the app as an actual driver). Any future copy/onboarding should include a lightweight "passenger/stationary use" disclaimer — flagged as a UNKNOWN/REQUIRES DECISION item for the next planning pass (see RISK_REGISTER.md).

## Reference-build purpose

This is **not** the final hackathon build. Its purpose is to be built ahead of the hackathon (target: complete well before September 11) so the team can:
- discover real Android/sensor/permission problems now, not on demo day;
- validate the physics/HUD/lock interaction actually feels good on a real device;
- validate the website and multiplayer architecture without gold-plating them;
- produce a `FAILURE_LOG.md` and `BUILD-MANIFEST.md` that feed the *next* planning pass for the actual hackathon implementation.

Success for this phase is not "shipped a finished app." Success is "we know exactly what works, what doesn't, and why, before the clock is running."

## Reconciliation with the planning package

This file is a faithful record of the product definition. It has been light-edited to align with the planning package. Key decisions reflected here:

- **D-1 (Demo Mode is opt-in from the gate):** the `PermissionGate` keeps its proven "SYSTEM LOCKED" screen as the default, but adds a clearly labeled "ENTER DEMO MODE" button. Demo Mode is opt-in, not silent. See `docs/DEMO_PLAN.md` §"Demo Mode entry point" and `docs/SENSOR_SPEC.md` "Sensor fallbacks" table.

For the full game mode catalog (Precision, Speed Lock, Demo Run, Target Strike, Crosswind, Vehicle Challenge, Pass-and-Play Tournament, Chaos, Blind, Online), see `docs/GAME_SPEC.md`. For the 90-second judge demo, see `docs/DEMO_PLAN.md`.
