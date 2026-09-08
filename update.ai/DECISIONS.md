# DECISIONS.md — SAFE//SPIT

> **Status:** PLANNED (new). Decision log. Each decision records context, options considered, the choice, and the why. This is the first place an AI looks when wondering "why did they do it this way."

---

### D-1: Permission denial behavior

- Date: 2026-09-03
- Status: accepted
- Context: `IMPLEMENTATION_PLAN.md` hard-blocks the HUD when permissions are denied ("SYSTEM LOCKED"); `plan.md` says the core must always work, which implies Demo Mode as a silent fallback. The two are directly contradictory.
- Options:
  1. Hard-block the HUD on denial; no Demo Mode.
  2. Silently substitute Demo Mode when permissions are denied.
  3. Hard-block by default; offer an explicit "ENTER DEMO MODE" button on the lock screen.
- Decision: Option 3.
- Why: Silent substitution would mislead a presenter into thinking real sensors are working. Explicit opt-in makes the demo honest and the gate's failure mode informative. The prototype's "SYSTEM LOCKED" screen is preserved as the default; Demo Mode is added as a clearly labeled opt-in.
- Consequences: The `PermissionGate` widget grows an additional button. The HUD grows a "DEMO MODE" indicator. The `BackendGateway` Noop pattern (D-9) provides a parallel for honest failure. See `docs/DEMO_PLAN.md` §"Demo Mode entry point."

### D-2: Lock-tone asset is local, not networked

- Date: 2026-09-03
- Status: accepted
- Context: The prototype plays the lock tone from `https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg` via `audioplayers.UrlSource`. The master plan says the core must work offline.
- Options:
  1. Keep the network URL; require network connectivity.
  2. Move the asset to `app/assets/audio/lock_tone.mp3` and use `audioplayers.AssetSource`.
  3. Generate the lock tone synthetically at build time (no asset file).
- Decision: Option 2 primary, with Option 3 as a documented fallback if the asset cannot be sourced.
- Why: The lock cue is the WOW moment's audio anchor. It must never fail because the venue has poor Wi-Fi. A bundled local asset is the proven capability of `audioplayers` already in the prototype's dependencies.
- Consequences: The `INTERNET` permission is no longer load-bearing for the core loop. The asset must be added to `pubspec.yaml` and verified at build time. See `docs/TECH_STACK.md` "Audio" and `RISK_REGISTER.md` R-20.

### D-3: Cross-platform simulation strategy is shared-spec, not shared-runtime

- Date: 2026-09-03
- Status: accepted
- Context: The master plan calls for a "shared simulation" between the Android app and the website. The options are: (a) one shared runtime (Dart→WASM, Flutter Web, or a server-side endpoint), or (b) two implementations with a shared JSON contract.
- Options:
  1. Dart→WASM or Flutter Web for the website.
  2. Server-side simulation endpoint; the website calls it.
  3. Two parallel implementations (Dart + TypeScript) and a shared JSON contract.
- Decision: Option 3.
- Why: Direct quote from the master plan: *"Do not force a technically complicated shared-runtime architecture if a deterministic compatible model is more reliable."* The two-impl + contract approach is reliable, debuggable, and matches team skill diversity.
- Consequences: `shared-spec/scenario.schema.json`, `result.schema.json`, and `test-vectors.json` are the contract. Both implementations run every vector. The website's simulator page is a TypeScript page, not a Flutter Web embed.

### D-4: Vehicle modifier identity preserves the proven formula

- Date: 2026-09-03
- Status: accepted
- Context: The proven formula `targetPitch(v) = clamp(45 + (v/5) * 1.2, 45, 85)` has been validated against the prototype. Adding vehicles could break that.
- Options:
  1. Apply vehicle modifiers to the base formula (risk: breaks the proven points).
  2. Define `Car` with `turbulenceFactor = 1.0`, `angleBias = 0.0` (identity) and apply non-Car vehicles as a small post-clamp bias.
  3. Replace the proven formula with a generalized form.
- Decision: Option 2.
- Why: The proven formula is the project's most-likely-to-be-quoted fact; breaking it would invalidate the entire reference build's credibility. Identity preservation keeps the Car profile byte-equivalent to no-vehicle.
- Consequences: TV-08 asserts identity. Other vehicles use small biases (typically < 5°) and the `windSensitivity` field for impact deviation. Vehicle profiles are fictional, not realistic.

### D-5: Wind does not affect the lock

- Date: 2026-09-03
- Status: accepted
- Context: The master plan's "crosswind" features imply wind is everywhere. The lock is the WOW moment.
- Options:
  1. Wind affects the lock tolerance (risk: makes the demo less reliable).
  2. Wind affects scoring/impact only, never the lock.
  3. Wind is a separate game mode with its own lock.
- Decision: Option 2.
- Why: The lock is the moment the user holds the phone still. Adding wind to that calculation makes the demo less reliable indoors and on devices with no real wind data. The simulation stays deterministic either way.
- Consequences: `targetPitchDeg` is wind-independent. `deviationM` and `impactPosition` are wind-dependent. `windSpeedKmh` and `windDirectionDeg` are derived from the scenario seed when not explicitly set. TV-09 asserts this.

### D-6: Plan B (pass-and-play) multiplayer before Plan A (online)

- Date: 2026-09-03
- Status: accepted
- Context: The master plan has both an online multiplayer feature and a pass-and-play flow. Networking adds failure modes we cannot afford on demo day.
- Options:
  1. Online first, then pass-and-play.
  2. Pass-and-play first; online additive.
  3. Online only.
- Decision: Option 2.
- Why: Pass-and-play is the demo's natural demo path on a single device; it works in airplane mode; it requires zero infrastructure. Online is cut-order #5 in the master plan's cut list and is only added if pass-and-play is stable.
- Consequences: `MULTIPLAYER_SPEC.md` is fully specified for Plan B; Plan A is specified only enough to know the surface area. See `docs/IMPLEMENTATION_ORDER.md` Phase 10 (Plan B) and Phase 12 (Plan A).

### D-7: ESP32 is invisible to the Android app

- Date: 2026-09-03
- Status: accepted
- Context: The master plan has an ESP32 section but says it must not block the Android core. The only safe way to enforce that is to make the dependency impossible at the import level.
- Options:
  1. ESP32 is a runtime dependency of the app (high risk if ESP32 is unreliable).
  2. ESP32 firmware is a separate directory; the app never imports it.
  3. ESP32 talks to the app via a runtime-toggleable sensor source.
- Decision: Option 2 (with Option 3 as a future option, not required for the reference build).
- Why: The app MUST compile and run with the `esp32/` directory deleted (Rule 13). If the ESP32 disappears, the app does not notice. Demo Mode is the only "alternative sensor source" needed for the reference build.
- Consequences: The Android app's `app/lib/sensors/` directory is the only seam where an alternative sensor source could plug in. ESP32 firmware (if any) is a wholly separate project.

### D-8: State management is `provider`

- Date: 2026-09-03
- Status: accepted
- Context: The prototype already compiles `provider` as a dependency. The reference build is the wrong place to fight a state-management migration.
- Options:
  1. Use `provider` deliberately (already compiled).
  2. Migrate to Riverpod.
  3. Migrate to Bloc / Redux / MobX.
- Decision: Option 1.
- Why: `provider` is already shipped; the only remaining decision is whether to use it deliberately or accidentally. We choose deliberately. Migrating to a different state library would be a several-day refactor for no proven benefit.
- Consequences: The `provider` package is the only state library. New code uses `ChangeNotifier` + `InheritedNotifier` for app state, `provider` for DI and context plumbing. See `docs/TECH_STACK.md` "State management."

### D-9: BackendGateway with Noop default

- Date: 2026-09-03
- Status: accepted
- Context: The master plan says the core must work without Supabase. A typed interface with a default Noop implementation enforces that at compile time.
- Options:
  1. Supabase calls inline in the UI; no interface.
  2. `BackendGateway` interface with `SupabaseBackendGateway` and `NoopBackendGateway`.
  3. Build-flag-driven conditional Supabase code.
- Decision: Option 2.
- Why: The interface makes the offline-first property structural. The Noop default ships by default; Supabase is added later behind the same interface. Build flags are fragile and easy to mis-configure.
- Consequences: Every call site that needs Supabase talks to `BackendGateway`. The Noop implementation is the default. The Supabase implementation is added in `docs/IMPLEMENTATION_ORDER.md` Phase 12 only if time allows.

### D-10: Animation library is `CustomPainter` only

- Date: 2026-09-03
- Status: accepted
- Context: The master plan implies richer motion; the prototype uses `CustomPainter` with `shouldRepaint`. Adding Rive or Lottie adds authoring tooling, asset files, and version drift.
- Options:
  1. Rive for HUD animation.
  2. Lottie for HUD animation.
  3. `CustomPainter` + `AnimationController` (proven pattern).
- Decision: Option 3.
- Why: The reference build's job is to validate the core, not to design an animation pipeline. The `CustomPainter` already has a working `shouldRepaint`; reuse it.
- Consequences: All HUD animation is done in `CustomPainter.shouldRepaint` + `AnimationController`. No new asset files. If an animation later needs a richer timeline, that is a Phase B decision.

### D-11: Scoring is deterministic

- Date: 2026-09-03
- Status: accepted
- Context: Pass-and-play must be fair. Two players running the same scenario on the same device must get the same final score for the same inputs.
- Options:
  1. Time-of-day in scoring (risk: unfair pass-and-play).
  2. `Random()` in scoring (risk: unfair pass-and-play).
  3. Pure function of `(seed, telemetry log)`.
- Decision: Option 3.
- Why: Without determinism, the demo's head-to-head is meaningless. Determinism also makes the website/Android parity test trivially passable.
- Consequences: No `DateTime.now()`, no `Random()`, no platform RNG in simulation or scoring. The test vectors in `shared-spec/test-vectors.json` assert this directly (TV-10).

### D-12: Branding is not locked

- Date: 2026-09-03
- Status: accepted
- Context: The master plan lists "Other Branding Directions" and does not lock one. Locking early would create throwaway work.
- Options:
  1. Lock "SAFE//SPIT" + "Tactical Salivary Ballistics System" subtitle now.
  2. Defer branding to Phase A playtesting.
  3. Use placeholders throughout.
- Decision: Option 2.
- Why: Phase A playtesting surfaces what reads well. Locking copy now would force a rename later.
- Consequences: UI text uses "SAFE//SPIT" as a working name. No copy is treated as final until Phase A playtesting.

### D-13: Lock-on / lock-off is edge-triggered, not level-triggered

- Date: 2026-09-03
- Status: accepted
- Context: Audio loop bugs from level-triggered design are a known failure mode and were a documented risk in the older plan. The prototype already uses the edge-triggered pattern.
- Options:
  1. Audio + haptic fire continuously while locked (level-triggered).
  2. Audio + haptic fire once on the false→true transition (edge-triggered).
  3. Same as Option 2, plus a single fire on the true→false transition for the "lost lock" cue (A-tier).
- Decision: Option 3.
- Why: The prototype already uses Option 2. Option 3 adds a "lost lock" cue as A-tier (not required for the reference build).
- Consequences: `SpitLockController` uses a `wasClear` boolean. Audio and haptic events are counted in tests; a test that counts more than 1 audio event per false→true transition fails.

### D-14: Negative speed is clamped to zero

- Date: 2026-09-03
- Status: accepted
- Context: GPS speed should never be negative, but a buggy sensor feed could produce one. Defensive clamping is cheap.
- Options:
  1. Pass through negative speeds (risk: nonsense target pitch).
  2. Clamp `speedKmh` to `>= 0` before the formula.
  3. Assert positive and crash.
- Decision: Option 2.
- Why: Cheap to enforce, prevents a class of edge-case bugs. The simulation should be stable even with bad inputs.
- Consequences: `targetPitch(-10) == targetPitch(0) == 45.0`. TV-07 asserts this.

### D-15: Coordinate system simplification is intentional

- Date: 2026-09-03
- Status: accepted
- Context: The current single-axis gyro integration is the only proven pitch source. A quaternion or rotation matrix is not a small refactor.
- Options:
  1. Implement a full quaternion-based orientation now.
  2. Keep single-axis gyro, leave a `rollDeg`/`yawDeg`/`headingDeg` seam in the schema.
  3. Drop the seam entirely.
- Decision: Option 2.
- Why: The seam is left in place; the implementation arrives later. The reference build uses `pitch = integrated gyroscope Y` for the lock.
- Consequences: `NormalizedTelemetry` has `rollDeg`, `yawDeg`, `headingDeg` fields defaulting to 0. The schema and the simulation accept them but the current implementation does not use them.

### D-16: `provider` is the state-management library, deliberately

- Date: 2026-09-03
- Status: accepted
- Context: This is a re-affirmation of D-8 with explicit engineering policy. See D-8 for the context.
- Decision: Use `provider` deliberately for all app state. `ChangeNotifier` for mutable state, `InheritedNotifier` for context plumbing.
- Why: `provider` is already shipped. Any other choice is a several-day migration for no proven benefit.
- Consequences: No new state-management library is added. If a future feature genuinely needs Riverpod-level ergonomics, that is a Phase B decision with an entry in this file.

### D-17: `audioplayers` is the audio library, deliberately

- Date: 2026-09-03
- Status: accepted
- Context: The prototype already uses `audioplayers`. The lock tone asset is local (D-2).
- Decision: Use `audioplayers` deliberately. Local assets for all sounds. No networked audio.
- Why: `audioplayers` is already shipped and supports `AssetSource`. The lock cue must work offline.
- Consequences: `audioplayers` is the only audio library. All audio assets are bundled in `app/assets/audio/`.

### D-18: Lock tone asset fallback is a 1-second sine sweep

- Date: 2026-09-03
- Status: accepted
- Context: If a proper lock-tone asset cannot be sourced for the reference build, the build needs a fallback that does not block.
- Options:
  1. Block Phase 1 on a proper asset.
  2. Use a generated 1-second sine sweep at 880Hz as a placeholder.
  3. Use a different free asset.
- Decision: Option 2, with Option 3 as a fallback if a better asset is found.
- Why: The reference build cannot block on asset acquisition. A generated sine sweep is functional and replaceable later.
- Consequences: If a proper asset is sourced, it replaces the sine sweep. The replacement is documented in this file.

### D-19: Scenario seed format is 6-character uppercase hex

- Date: 2026-09-03
- Status: accepted
- Context: A scenario seed is the only source of randomness in the simulation. It must be copyable, shareable, and unambiguous.
- Options:
  1. Long UUID.
  2. 6-character hex.
  3. Variable-length string.
- Decision: Option 2.
- Why: 6 hex chars = 16M possible scenarios. Short enough to type and share. Unambiguous (case-insensitive on input, uppercase on output).
- Consequences: `shared-spec/scenario.schema.json` regex is `^[0-9A-Fa-f]{6}$`. Pass-and-play seeds are displayed in uppercase. Shareable URLs use uppercase: `/play?seed=8F42A7&vehicle=car`.

### D-20: Anonymous callsign is `SPIT-XXXXX`

- Date: 2026-09-03
- Status: accepted
- Context: Plan B multiplayer needs a player identifier that does not require a login and does not leak identity.
- Options:
  1. Login required.
  2. Random string per session.
  3. Deterministic `SPIT-XXXXX` derived from `(device_id, timestamp)`.
- Decision: Option 3.
- Why: Anonymous, no login, but stable across the app's lifetime on a device. Regenerated on reinstall.
- Consequences: `update.ai/DECISIONS.md` D-20 is the source of truth. The callsign is shown on the result screen and the pass-and-play comparison screen. Never sent to a server in Plan B.

---

## Decision log conventions

- **Date:** the date the decision was made (or last updated).
- **Status:** `proposed` (under discussion), `accepted` (binding), `superseded` (replaced by a later decision).
- **Context:** the situation that required a decision. Cite the contradiction or the gap.
- **Options:** the alternatives considered. Numbered.
- **Decision:** the chosen option.
- **Why:** the one-sentence-to-one-paragraph reason.
- **Consequences:** what this enables, what it forecloses, what files it touches.

When a decision is superseded, do not delete it — add a "Superseded by D-NN" note and link to the new entry. The log is append-only.
