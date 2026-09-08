# BUILD-MANIFEST.md — SAFE//SPIT

> **Status:** PLANNED (new). Template for documenting the build's current state. Updated at the end of each implementation phase, not at the end of the project.
> **Cross-references:** `docs/IMPLEMENTATION_ORDER.md`, `update.ai/CURRENT_STATUS.md`, `FAILURE_LOG.md`, `docs/TEST_PLAN.md`.

## Build metadata

- Build date: 2026-09-03
- Git commit hash (or build label): REFERENCE-BUILD-v1.0-alpha
- Flutter version: 3.47.1-stable
- Android SDK / NDK version: TBD (device testing pending)
- Package id: `com.safespit`
- Version name: 1.0.0-alpha
- Version code: 1

## Devices tested

| Model | Android version | Result | Date | Tester |
|---|---|---|---|---|
| TBD | TBD | TBD | TBD | TBD |

(Each row is filled during Phase 17 — full validation. A row that says "fail" is mirrored in `FAILURE_LOG.md`.)

## Enabled features (per phase, with S/A/B/C tier)

| Feature | Tier | Shipping in reference build? | Notes |
|---|---|---|---|
| Proven reticle (`MissileLockReticlePainter`) | S | YES | PROVEN; preserved byte-equivalent |
| Lock tolerance (`deltaDeg <= 5.0`) | S | YES | PROVEN; TV-04, TV-05, TV-06 |
| Edge-triggered lock audio | S | YES | PROVEN; D-13 |
| PermissionGate "SYSTEM LOCKED" | S | YES | PROVEN |
| Demo Mode entry on gate | S | YES | D-1, PLANNED |
| Local lock-tone asset | S | YES | D-2, replaces `UrlSource` |
| NormalizedTelemetry seam | S | YES | PLANNED |
| Full simulation (pitch, trajectory, scoring) | S | YES | Phase 4 |
| HUD extensions (trajectory, target, wind, vehicle) | S | PARTIAL | Phase 5; ship reticle + trajectory, defer the rest if time is short |
| SpitLockController (edge-triggered) | S | YES | Phase 6 |
| Demo Mode end-to-end | S | YES | Phase 7 |
| Car vehicle profile | S | YES | D-4 identity |
| Result screen | S | YES | Phase 9 |
| `NoopBackendGateway` | S | YES | D-9 default |
| Other vehicle profiles (Bus, Train, etc.) | A | TBD | Phase 8; ship Car + 1 test profile minimum |
| Pass-and-play (Plan B) | A | TBD | Phase 10 |
| Spit Olympics modes (Target Strike, Crosswind, Vehicle Challenge) | A | TBD | Phase 11; ship 2 modes minimum |
| `SupabaseBackendGateway` | A | TBD | Phase 12; ship `Noop` only if time is short |
| Website (cinematic intro + simulator page) | A | TBD | Phase 13; ship minimal viable if time is short |
| Sensor diagnostics screen | A | TBD | Phase 14; debug-only if time is short |
| Lost-lock cue | A | TBD | Phase 15 |
| Tournament mode | A | TBD | Phase 16 |
| Chaos Mode | B | TBD | Phase 16; cut first if time is short |
| Blind Mode | B | TBD | Phase 16 |
| Online multiplayer (Plan A) | B | TBD | Phase 16; cut first if time is short |
| Replay | B | TBD | Phase 16; data structure defined, UI cut first |
| AI Commander | C | NO | Cut first per plan.md §65 |
| Voice control | C | NO | Cut first |
| ESP32 integration | C | NO | Inactive per D-7 |
| Rive / Lottie animation libraries | C | NO | Cut per D-10 |
| Custom font asset | C | NO | Cut; default Flutter font stack |

## Disabled features (with reason)

(none at planning time)

## Known limitations

(none at planning time)

## Test status (per phase, from `docs/TEST_PLAN.md`)

| Phase | Unit | Integration | Widget | Device | e2e | Status |
|---|---|---|---|---|---|---|
| Phase 0 | — | — | — | — | — | PENDING |
| Phase 1 | 3 proven points | — | — | — | — | PENDING |
| Phase 2 | Telemetry types | DemoMode | — | — | — | PENDING |
| Phase 3 | — | Gate flow | Gate UI | — | — | PENDING |
| Phase 4 | Full sim | — | — | — | — | PENDING |
| Phase 5 | — | HUD reads | Reticle paint | — | — | PENDING |
| Phase 6 | — | Lock edge | Telemetry reads | — | — | PENDING |
| Phase 7 | — | — | — | — | Full e2e | PENDING |
| Phase 8 | Vehicle identity | — | — | — | — | PENDING |
| Phase 9 | Scoring determinism | — | Result UI | — | — | PENDING |
| Phase 10 | — | Pass-and-play parity | — | — | — | PENDING |
| Phase 11 | Per-mode scoring | — | — | — | — | PENDING |
| Phase 12 | Gateway iface | Noop offline | — | — | — | PENDING |
| Phase 13 | — | — | — | — | Web parity | PENDING |
| Phase 14 | — | — | Diagnostics UI | — | — | PENDING |
| Phase 15 | Pattern list | — | — | — | — | PENDING |
| Phase 16 | Per-feature | — | — | — | — | PENDING |
| Phase 17 | Full | Full | Full | Full | Full | PENDING |

## Reference screenshots

(none at planning time — paths to be added during Phase 17)

## Demo recording

(none at planning time — `demo-recording.mp4` to be added during Phase 17)

## Configuration notes

- Supabase URL: TBD (only if `SupabaseBackendGateway` is enabled; the reference build ships with `NoopBackendGateway` only).
- Lock tone asset: `app/assets/audio/lock_tone.mp3` (D-2; D-18 fallback is a generated sine sweep).
- Schema version pinned: `0.1.0` (see `shared-spec/scenario.schema.json` and `result.schema.json`).
- Test vector count: 10 (TV-01 through TV-10 in `shared-spec/test-vectors.json`).

## Demo procedure

See `docs/DEMO_PLAN.md`. The 90-second core demo, plus the optional 30-second pass-and-play encore.

## Recovery procedure

If the build enters an unrecoverable state during demo or development, the recovery action is to back out to the main menu and re-enter (one screen back, not a force-quit). The menu path is documented in the result screen and the gate.

For a clean rebuild from scratch:

1. `flutter clean`
2. `flutter pub get`
3. `flutter test` (run the full test suite)
4. `flutter build apk --debug`
5. `flutter install` (on a connected device)

For a clean checkout from version control:

1. Clone the repo
2. `cd app && flutter pub get`
3. `flutter test`
4. `flutter run` (on a connected device or emulator)

## What this build does NOT include

(Anything explicitly cut. Filled during Phase 16 and Phase 17.)
