# SENSOR_SPEC.md — SAFE//SPIT

## Sensors used

| Sensor | Status | Package | Purpose |
|---|---|---|---|
| GPS | PROVEN | `geolocator` | Vehicle speed (km/h) |
| Gyroscope | PROVEN | `sensors_plus` | Device pitch (integrated) |
| Camera | PROVEN | `camera` | HUD passthrough visual |
| Accelerometer | PLANNED | `sensors_plus` (already a dependency, unused today) | Roll/tilt refinement, possible drift correction |
| Magnetometer | PLANNED | `sensors_plus` (same) | Heading |
| Barometer | PROPOSED/OPTIONAL | none yet | Not recommended for reference build — low value, inconsistent hardware support |
| Microphone | NOT PLANNED | — | No evidence of use anywhere; RECORD_AUDIO permission appears to be a manifest-merge artifact, not a feature (see TECH_STACK.md) |
| Bluetooth/NFC | OPTIONAL, ESP32-only | none yet | Only relevant if/when the ESP32 experiment proceeds; must never gate the phone-only core |

## PROVEN: GPS speed pipeline

Confirmed from the prototype's `SafeSpitSensorManager`:
- Uses `Geolocator`'s position stream (a `LocationSettings`-configured stream — the older plan's spec called for `LocationAccuracy.bestForNavigation`; the exact accuracy setting used in the shipped build was not independently confirmed from the compiled binary and should be verified in source).
- Converts to km/h (`v_kmh = v_ms * 3.6`) per the older plan.
- Stream has explicit `onError`/`cancelOnError`/`onDone` handlers (PROVEN — confirmed present in the compiled class), so GPS stream failures do not crash the app. What visibly happens to the UI on error was not confirmed from static analysis — treat "does the HUD show a diagnostic message on GPS error today" as **UNKNOWN, requires source read / device test**.

## PROVEN: Gyroscope pitch integration

Confirmed from the prototype's `SafeSpitSensorManager`:
- Subscribes to `gyroscopeEventStream()`.
- Tracks `_lastGyroTime`, computes `dt` from `Duration.inMicroseconds` between events.
- Integrates: `newPitch = clamp(previousPitch + (angularVelocityY_rad/s * 180/π * dt), 0°, 180°)`.
- Same explicit `onError`/`cancelOnError`/`onDone` pattern as GPS.

**This is naive single-axis numerical integration and will drift over time** — this is expected and openly acknowledged in the older plan's own doc comments, not a bug introduced by this document. Gyro-only pitch integration without periodic correction (e.g. from the accelerometer's gravity vector) accumulates error the longer the session runs. Do not present this as "precise" anywhere in-product; the joke already covers for this ("proprietary heuristic"), but the *engineering* honesty matters for future debugging.

**PLANNED improvement (not yet implemented, not required for the reference build's core loop, but worth prototyping if drift proves visibly bad in testing):** fuse the accelerometer's gravity vector with the gyro integration (a basic complementary filter) to periodically re-anchor pitch to a stable reference, instead of relying on pure integration. This is a `REQUIRES REAL DEVICE TESTING` item — do not build it speculatively; build it only if playtesting shows drift is actually a problem within a typical demo session length (a few minutes).

## PROVEN: Camera passthrough

- `CameraController(cameras.first, ResolutionPreset.high, enableAudio: false)`.
- Green tint overlay: `Color(0xFF39FF14).withOpacity(0.05)` — exactly the "5% translucent green tactical filter" described in the older plan.
- Graceful handling when `cameras` list is empty (falls back to a black background with a loading indicator rather than crashing) — PROVEN from source strings ("Error finding cameras:" debug print + conditional render).

## Normalized telemetry (target shape — PLANNED generalization of the proven pipeline)

```
NormalizedTelemetry {
  speedKmh: double
  pitchDeg: double
  rollDeg: double        // PLANNED
  yawDeg: double          // PLANNED
  headingDeg: double       // PLANNED
  timestamp: DateTime
  sensorHealth: {
    gps: SensorHealth
    gyro: SensorHealth
    accelerometer: SensorHealth   // PLANNED
    magnetometer: SensorHealth    // PLANNED
    camera: SensorHealth
  }
}

enum SensorHealth { ok, degraded, unavailable, permissionDenied }
```

UI code (HUD, diagnostics screen) must only ever read `NormalizedTelemetry` — never raw `Position` or `GyroscopeEvent` objects. This normalization boundary does not exist yet in the prototype (the sensor manager currently exposes speed/pitch directly as loose fields consumed by the widget tree via `setState`) and is the single most important refactor for making the vehicle/wind/multiplayer features buildable without destabilizing the proven core.

## Coordinate systems / orientation calculation

- Pitch: device Y-axis angular velocity integrated over time, expressed in degrees, clamped `[0°, 180°]`. This is a simplification (true 3D device orientation needs a quaternion or rotation-matrix approach), but it is what's proven to work for this product's single-axis "tilt the phone back" interaction, and there is no evidence the older or latest plan requires more than this for the S-tier lock interaction. Roll/yaw (needed for wind visualization and Spit Olympics target aiming) are PLANNED, not yet designed in detail — treat as `REQUIRES VALIDATION` once vehicle/wind work begins.

## Sensor fallbacks (explicit)

| Condition | Fallback |
|---|---|
| GPS permission denied | `PermissionGate` shows the "SYSTEM LOCKED" screen **and** a clearly labeled "ENTER DEMO MODE" button. Tapping the button routes to the HUD in Demo Mode (D-1). The "SYSTEM LOCKED" screen is no longer a hard block; it is the default response with an explicit opt-out. |
| GPS available but returns no fix indoors | Speed reads 0 or stale; sensorHealth marked `degraded`; Demo Mode should be offered/available as an explicit user choice, not silently substituted (silent substitution would be misleading during a real demo — the presenter needs to know they're in Demo Mode) |
| Gyro unavailable (rare on modern Android, but must not crash) | `sensorHealth.gyro = unavailable`; pitch pinned to `45°` (i.e. behaves as if stationary/optimal) rather than `0°`, so the HUD doesn't show a jarring default |
| Camera permission denied | `PermissionGate` blocks entry (PROVEN pattern, same screen as GPS denial) |
| Camera hardware absent (rare) | Black background fallback, already proven behavior |

## Error handling / lifecycle

- Both GPS and gyro streams already have `onError`/`onDone`/`cancelOnError` wiring in the prototype — extend this pattern to any new sensor streams (accelerometer, magnetometer) rather than inventing a new pattern.
- Streams must be cancelled in `dispose()` — confirmed present for camera controller and audio player in the prototype; must be extended to any new subscriptions.

## Known / Proven / Planned / Unknown summary

- **PROVEN:** GPS→km/h pipeline, gyro dt-integration pipeline, camera passthrough + green tint, stream-level error handling scaffolding.
- **PLANNED:** normalized telemetry boundary, accelerometer/magnetometer usage, roll/yaw/heading, sensor diagnostics screen, Demo Mode as an explicit substitute source.
- **PROPOSED:** complementary-filter drift correction for pitch.
- **UNKNOWN / REQUIRES VALIDATION:** exact `LocationAccuracy` setting used in the shipped build; exact on-screen behavior when GPS/gyro streams error out today; real-world drift magnitude over a multi-minute session on target hardware; whether Android 14+/15+ location permission prompts (one-time vs. always) need special handling beyond what `permission_handler` already provides.

## Reconciliation with the planning package

This file is a faithful record of the sensor stack. It has been light-edited to align with the planning package. Key decisions reflected here:

- **D-1 (Demo Mode entry on the gate):** the `PermissionGate` adds a clearly labeled "ENTER DEMO MODE" button alongside the "SYSTEM LOCKED" message. Demo Mode is opt-in, not silent. The fallback table above is updated to reflect this. See `docs/DEMO_PLAN.md` §"Demo Mode entry point."
- **R-01 (Gyro drift, P0):** the risk register calls for a 5-minute static-device log of pitch. If drift exceeds 2°, a complementary filter is the mitigation (PLANNED, not required for the reference build). See `docs/RISK_REGISTER.md`.

The implementation order is in `docs/IMPLEMENTATION_ORDER.md`. The full risk register is in `docs/RISK_REGISTER.md`.
