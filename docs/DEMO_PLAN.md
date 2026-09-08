# DEMO_PLAN.md — SAFE//SPIT

> **Status:** PLANNED (new). The shortest reliable judge demo, including a robust Demo Mode that works without permissions or network.
> **Cross-references:** `PRODUCT_SPEC.md`, `SENSOR_SPEC.md` (fallback table), `RISK_REGISTER.md`, `IMPLEMENTATION_ORDER.md` (Phase 7).

## 1. Core demo script (under 90 seconds)

1. "We noticed a serious problem..." (the joke setup, under 10s).
2. Open app → permission gate (under 5s).
3. Grant camera + location OR enter Demo Mode from the gate (under 5s).
4. HUD appears with live telemetry (under 5s).
5. Move phone → HUD reacts, trajectory moves, reticle tracks (under 15s).
6. Hold phone at the target angle → SPIT LOCK → haptic + audio (under 10s).
7. Simulated launch animation (under 5s).
8. Result screen (score + mission card) (under 5s).
9. Optional: open Spit Olympics, play a 2-player pass-and-play seed (under 30s).

Total: under 90 seconds for the core; under 120 with the Spit Olympics encore.

## 2. Demo Mode entry point

An explicit "ENTER DEMO MODE" button on the permission gate (D-1). Demo Mode is opt-in, not silent. The HUD clearly shows "DEMO MODE" in a visible corner of the screen so the presenter never loses track of which mode they're in.

## 3. What Demo Mode simulates

- Vehicle speed: a deterministic script per seed (the same seed produces the same speed curve).
- Gyro pitch: a scripted trajectory that walks toward the target angle (so the presenter can hit lock reliably).
- Camera: a static "DEMO SENSOR" overlay if camera is denied; the camera passthrough if camera is granted but GPS is not.
- Audio: the same local lock-tone asset (`app/assets/audio/lock_tone.mp3`, D-2).

## 4. What Demo Mode does NOT simulate

- Real GPS coordinates.
- Real sensor noise.
- Real device drift.
- These are honest properties of real sensors and should not be faked. Demo Mode is a demo of the software, not a fake of the hardware.

## 5. Robustness requirements

The demo must succeed in ALL of the following states without recovery action:

| # | State | Expected behavior |
|---|---|---|
| 1 | All permissions granted | Full real-sensor HUD. |
| 2 | Camera denied, GPS granted | HUD on black background; speed from GPS; lock works. |
| 3 | GPS denied, camera granted | HUD with camera; speed from Demo Mode (or 0); "DEMO MODE" visible if Demo Mode is entered. |
| 4 | All permissions denied (Demo Mode) | Full Demo Mode; "DEMO MODE" visible; lock works; score shown. |
| 5 | Airplane mode (no network) | All of the above still works; "Score not saved online" is acceptable. |
| 6 | Supabase unreachable | Same as airplane mode; NoopBackendGateway; "not saved online" message. |
| 7 | Audio muted on device | Lock still works; haptic still fires; on-screen lock indicator still shows. |
| 8 | Device in landscape | Rotation does not break the demo; HUD re-layouts. |

## 6. Failure recovery

If the demo enters an unrecoverable state, the recovery action is to back out to the main menu and re-enter. This is a one-screen-back fallback, not a force-quit fallback. The menu path is documented in the result screen: "If something goes wrong, tap the back arrow to return to the main menu."

## 7. What the demo should NOT include

- A Supabase login screen.
- A profile setup screen.
- A tutorial.
- Anything that requires typing.
- A loading screen that lasts more than 2 seconds (if a sensor is slow to initialize, show the HUD with "DEMO MODE" and let the presenter enter Demo Mode).

## 8. The WOW moment (explicit)

The WOW moment is: judge touches phone → real sensor changes → HUD responds → trajectory responds → target acquired → haptic → lock sound → simulated launch → score. This must be reachable in under 30 seconds from app launch, in Demo Mode, with no permissions, on a device that has never seen the app before.

## 9. Acceptance

The demo runs in under 90 seconds, the joke is clear within 10 seconds, the lock+launch+score interaction is visible, and the demo succeeds in all eight robustness conditions above.

## Known / Proven / Planned / Unknown

- PROVEN: the core HUD + lock + audio interaction (from the prototype).
- PLANNED: the Demo Mode entry point on the permission gate (D-1), the "DEMO MODE" indicator, the deterministic Demo Mode telemetry script.
- PROPOSED: the exact copy on the "ENTER DEMO MODE" button and the "DEMO MODE" indicator.
- UNKNOWN: whether the 90-second budget is achievable on a cold start on a mid-range device (requires device testing).