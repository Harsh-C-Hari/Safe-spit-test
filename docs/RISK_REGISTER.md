# RISK_REGISTER.md — SAFE//SPIT

> **Status:** PLANNED (new). A brutally honest risk register. Every risk is rated by Probability x Impact and has an explicit Detection, Mitigation, and Fallback. This is the source of truth for "what could go wrong on demo day."
> **Cross-references:** every other doc.

## Format

Each risk is rated by Probability x Impact and has an explicit Detection, Mitigation, and Fallback. Priority: P0 = must mitigate before demo; P1 = mitigate if time; P2 = accept.

## Risks

### R-01: Gyroscope drift over multi-minute sessions
- Category: sensor
- Probability: HIGH
- Impact: MEDIUM
- Detection: Log pitch over a 5-minute static device. If pitch drifts more than 2 degrees, the risk has materialized.
- Mitigation: Reset pitch on app resume. Consider a complementary filter (accelerometer gravity vector fused with gyro) in Phase A validation.
- Fallback: Cap session length, or re-zero on a known-horizontal calibration gesture.
- Priority: P0

### R-02: GPS no fix indoors
- Category: sensor
- Probability: HIGH
- Impact: HIGH
- Detection: Indoor test with no GPS fix. Speed reads 0 or stale; sensorHealth marked degraded.
- Mitigation: Explicit "GPS unavailable" diagnostic; offer Demo Mode from the gate (D-1).
- Fallback: Demo Mode is the default indoors.
- Priority: P0

### R-03: GPS permission denied
- Category: permission
- Probability: MEDIUM
- Impact: HIGH
- Detection: Revoke location permission in OS settings.
- Mitigation: PermissionGate plus Demo Mode entry (D-1).
- Fallback: Demo Mode.
- Priority: P0

### R-04: Camera permission denied
- Category: permission
- Probability: MEDIUM
- Impact: HIGH
- Detection: Revoke camera permission.
- Mitigation: Black background fallback (proven in the prototype); gate offers Demo Mode (D-1).
- Fallback: Demo Mode with "DEMO SENSOR" overlay.
- Priority: P0

### R-05: Camera hardware absent or in use
- Category: hardware
- Probability: LOW
- Impact: HIGH
- Detection: `cameras` list is empty.
- Mitigation: Existing black-background fallback is proven.
- Fallback: Demo Mode with "DEMO SENSOR" overlay.
- Priority: P1

### R-06: Sensor stream interruption on lifecycle pause/resume
- Category: lifecycle
- Probability: HIGH
- Impact: MEDIUM
- Detection: Background/foreground test on a real device. The sensor streams should be cancelled and re-subscribed on resume.
- Mitigation: Cancel and re-subscribe on resume; test explicitly.
- Fallback: If re-subscribe fails, offer Demo Mode.
- Priority: P0

### R-07: Audio silent or muted
- Category: hardware
- Probability: LOW
- Impact: MEDIUM
- Detection: Device with volume set to zero.
- Mitigation: Visual-only feedback (haptic) and on-screen lock indicator; the lock itself does not depend on audio.
- Fallback: Haptic + visual lock indicator.
- Priority: P1

### R-08: Haptic motor missing
- Category: hardware
- Probability: LOW
- Impact: LOW
- Detection: Device with no vibrator.
- Mitigation: Visual-only feedback; document device as "no haptic."
- Fallback: Audio + visual lock indicator.
- Priority: P2

### R-09: Rendering performance on low-end devices
- Category: performance
- Probability: MEDIUM
- Impact: MEDIUM
- Detection: Profile on a 2019-era budget Android.
- Mitigation: CustomPainter.shouldRepaint is already correct; cap repaint rate to 60fps.
- Fallback: Reduce HUD element count; drop the trajectory line if needed.
- Priority: P1

### R-10: Website/mobile simulation divergence
- Category: scope
- Probability: MEDIUM
- Impact: HIGH
- Detection: Run shared test-vectors.json on both the Dart and TypeScript implementations.
- Mitigation: shared-spec contract plus parity test in CI (or pre-commit checklist).
- Fallback: If divergence is found, fix the implementation that diverges; do not loosen the test vectors.
- Priority: P0

### R-11: Supabase failure during demo
- Category: network
- Probability: MEDIUM
- Impact: MEDIUM
- Detection: Airplane mode + Supabase misconfigured.
- Mitigation: NoopBackendGateway is the default; UI says "not saved online."
- Fallback: The core game works without Supabase; the demo is unaffected.
- Priority: P1

### R-12: Online multiplayer complexity
- Category: scope
- Probability: HIGH
- Impact: MEDIUM
- Detection: Room code flow takes too long to implement or test.
- Mitigation: Plan B is the default; online is additive (D-6).
- Fallback: Skip online entirely; ship pass-and-play only.
- Priority: P1

### R-13: Over-scoping
- Category: scope
- Probability: HIGH
- Impact: HIGH
- Detection: Feature list growing past S-tier mid-build.
- Mitigation: Strict cut list (plan.md section 65). The reference build only ships S-tier + selected A-tier.
- Fallback: Cut B/C first, then A, then non-essential S. Never cut the core WOW loop.
- Priority: P0

### R-14: Hackathon time constraint
- Category: hackathon
- Probability: HIGH
- Impact: HIGH
- Detection: Feature count vs. hours remaining.
- Mitigation: Cut list. Reference build is the safety net.
- Fallback: Ship the reference build as the hackathon build if Phase B is not ready.
- Priority: P0

### R-15: Build or signing problems
- Category: hackathon
- Probability: MEDIUM
- Impact: HIGH
- Detection: Profile or release build fails.
- Mitigation: Ship a debug build for the demo if a release build fails; document in FAILURE_LOG.md.
- Fallback: Debug build on a USB-connected device.
- Priority: P0

### R-16: UI complexity / over-designed HUD
- Category: scope
- Probability: MEDIUM
- Impact: MEDIUM
- Detection: HUD is unreadable in 5 seconds.
- Mitigation: Re-cut to the proven reticle + trajectory line + telemetry bars; defer the rest.
- Fallback: Ship the proven HUD with the trajectory line only.
- Priority: P1

### R-17: ESP32 integration risk
- Category: hardware
- Probability: MEDIUM
- Impact: LOW
- Detection: ESP32 is unreliable or adds complexity.
- Mitigation: ESP32 is invisible to the app per D-7. The Android app does not import, depend on, or query an ESP32.
- Fallback: Remove the esp32/ directory entirely; the app is unaffected.
- Priority: P2

### R-18: Demo day hardware failure
- Category: demo
- Probability: LOW
- Impact: HIGH
- Detection: Device won't boot or battery is dead.
- Mitigation: Have a backup device, a backup APK, and a backup demo recording on a USB stick.
- Fallback: Show the recording.
- Priority: P1

### R-19: Network failure during demo
- Category: network
- Probability: LOW
- Impact: MEDIUM
- Detection: Airplane mode.
- Mitigation: Core is offline-first. The lock tone is a local asset (D-2). No network call is required for the core loop.
- Fallback: Demo Mode + airplane mode is a valid demo state.
- Priority: P1

### R-20: Lock-tone asset missing
- Category: hardware
- Probability: LOW
- Impact: HIGH
- Detection: Asset is not bundled (check pubspec.yaml asset declaration at build time).
- Mitigation: D-2 makes it a local asset; build-time verification in pubspec.yaml.
- Fallback: Generate a 1-second sine sweep at 880Hz at build time (D-18).
- Priority: P1