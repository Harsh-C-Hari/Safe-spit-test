# TECH_STACK.md — SAFE//SPIT

## Android app

**Framework:** Flutter. This is PROVEN — the shipped prototype APK is a Flutter/Dart app (confirmed via `assets/flutter_assets`, `libflutter.so`, `libdartjni.so` inside the APK, and Dart kernel source paths embedded in the debug build).

**Confirmed prototype configuration** (read directly from the APK's `AndroidManifest.xml` and asset bundle):

| Item | Value | Source of evidence |
|---|---|---|
| Application ID | `com.example.safespit` | AndroidManifest.xml |
| App label | `safespit` | AndroidManifest.xml |
| `minSdkVersion` | 24 (Android 7.0) | AndroidManifest.xml |
| `targetSdkVersion` / `compileSdkVersion` | 36 | AndroidManifest.xml |
| `versionName` | `1.0.0` | AndroidManifest.xml |
| Build type shipped | **Debug/JIT**, not release AOT (`kernel_blob.bin` present, no `libapp.so`, `android:debuggable="true"`) | APK contents |
| Flutter embedding | v2 (`flutterEmbedding = 2`) | AndroidManifest.xml |
| Activity | Single `MainActivity`, standard launcher intent-filter | AndroidManifest.xml |

**Action item for Antigravity:** the reference build should ship a **profile or release** build, not a debug build, once functional testing is done — debug builds are ~5-10x larger and slower, and the shipped prototype APK (with its 76MB Dart kernel blob) is not representative of real device performance.

### Confirmed dependencies (compiled into the shipped prototype — PROVEN)

Extracted directly from the Dart kernel's embedded `package:` import list:

- `camera` (+ `camera_android_camerax`, `camera_platform_interface`) — camera passthrough
- `geolocator` (+ `geolocator_android`, `geolocator_platform_interface`) — GPS speed
- `sensors_plus` (+ `sensors_plus_platform_interface`) — gyroscope
- `audioplayers` (+ `audioplayers_platform_interface`) — lock tone
- `permission_handler` (+ `permission_handler_platform_interface`) — runtime permissions
- `package_info_plus`, `path_provider`, `provider`, `uuid`, `http`, `cupertino_icons`

**Notes / UNKNOWNs:**
- `provider` is compiled in but its actual use as the state-management approach in `main.dart` was not confirmed from static binary analysis. Antigravity should verify in source before assuming it's load-bearing, or should deliberately adopt it as the state-management choice for the reference build (a reasonable, low-risk choice for a Flutter app of this size — no need to introduce Riverpod/Bloc/etc. for a reference build).
- `http` is present; no confirmed usage was found. It may be transitively pulled in by another plugin. Do not assume any custom HTTP calls exist yet.
- **No** `supabase_flutter`, no Bluetooth/BLE package (`flutter_blue_plus`, etc.), no NFC package, no barometer-specific package, and no haptics package (e.g. `vibration` or Flutter's built-in `HapticFeedback` usage was not distinguishable from static analysis but requires no extra dependency either way) were found in the prototype. All of these are therefore **PLANNED**, not proven.

### Recommended additions for the reference build

| Need | Recommendation | Why |
|---|---|---|
| Haptics | Flutter's built-in `HapticFeedback` (`flutter/services.dart`) | Zero new dependency; sufficient for a single pulse on lock |
| Local audio for lock tone | Keep `audioplayers`, switch the source from a **remote URL to a bundled local asset** (see DECISIONS.md — this is a reliability fix, not a new dependency) | Prototype currently plays `https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg` via `UrlSource`, which silently fails offline |
| Backend | `supabase_flutter` | Matches the plan's stated backend choice; minimal, has anonymous auth built in |
| Additional orientation sensors (accelerometer, magnetometer) | Continue using `sensors_plus` (already covers accelerometer/magnetometer/gyroscope) | No new package needed — `sensors_plus` is a superset of what's already integrated |
| State management | `provider` (already compiled in) or plain `ChangeNotifier` + `InheritedNotifier` | Avoid introducing a second state-management library; keep it boring |

### Platform requirements

- Android only for the reference build (no iOS target implied by anything in either plan; the compiled kernel includes iOS/macOS/Linux/Windows platform code paths only because Flutter's JIT snapshot bundles cross-platform framework code regardless of target — this is **not** evidence of multi-platform intent, it's a debug-build artifact).
- Real device testing required for GPS and gyroscope; emulators do not produce reliable GPS speed or gyro data for this product's core loop.

## Permissions (confirmed, from AndroidManifest.xml)

`INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA` (+ `uses-feature android.hardware.camera.any`), `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE` (maxSdk 28), `READ_EXTERNAL_STORAGE`, `ACCESS_NETWORK_STATE`.

**Notes:**
- `INTERNET`/`ACCESS_NETWORK_STATE` are currently load-bearing because the lock tone streams from a remote URL (see above) — once that's fixed to a local asset, these permissions become optional for the phone-only core (though still needed for Supabase later).
- `RECORD_AUDIO` is very likely a manifest-merge artifact from the `camera` plugin's video-recording capability (`CameraController(enableAudio: false)` is confirmed in the prototype, i.e. audio recording is explicitly disabled) rather than something the app actually uses. Flag as low-priority cleanup, not a bug.
- `WRITE_EXTERNAL_STORAGE`/`READ_EXTERNAL_STORAGE` are very likely manifest-merge artifacts of `path_provider`/`camera`, not something the app deliberately requests today.

## Website

**UNKNOWN / REQUIRES DECISION** — no website exists in any form in the current prototype. Recommendation (PROPOSED, not proven): a modern static-first framework with strong animation ergonomics — e.g. **Next.js (React) or SvelteKit**, either is fine — chosen primarily so the shared simulation logic (see PROJECT_STRUCTURE.md `shared-spec/`) can be re-implemented once in TypeScript and reused across every page, and so GSAP/Framer-Motion-class animation tooling is available for the "premium interactive" direction described in WEBSITE_SPEC.md. Do not default to a generic marketing-site template.

## Backend

**Supabase** — Postgres + auth (with anonymous sign-in) + row-level security + a thin REST/JS client. This matches the plan's stated direction and is the right size for a reference build: no custom server, no separate hosting to manage beyond Supabase itself. See SUPABASE_SPEC.md for schema.

## Build requirements

- Flutter SDK matching Dart/Flutter versions compatible with `compileSdkVersion 36` (recent stable Flutter channel).
- Android Studio / command-line Android SDK with API 36 platform + build tools.
- A real Android device (API 24+) for sensor testing — GPS speed and gyroscope pitch cannot be meaningfully validated on an emulator.

## Prefer stable, practical technology

Do not add libraries "because they're popular." Every dependency added beyond what's listed above should be justified in `update.ai/DECISIONS.md` with a one-line reason.

## Reconciliation with the planning package

This file is a faithful record of the prototype's evidence. It has been light-edited to align with the planning package. Key decisions reflected here:

- **D-2:** the lock tone is now a local asset under `app/assets/audio/lock_tone.mp3` (uses `audioplayers.AssetSource` instead of `UrlSource`). The `INTERNET` permission is no longer load-bearing for the core loop.
- **D-8 / D-16:** `provider` is the state-management library, deliberately. Use `ChangeNotifier` + `InheritedNotifier` for app state, `provider` for DI / context plumbing. Do not introduce Riverpod, Bloc, Redux, or MobX.
- **D-9:** the backend is wired behind a `BackendGateway` interface; the default implementation is `NoopBackendGateway`. `SupabaseBackendGateway` is added later (Phase 12 of `docs/IMPLEMENTATION_ORDER.md`) if time allows.
- **D-10:** no new animation libraries. All HUD animation is `CustomPainter.shouldRepaint` + `AnimationController`. Rive and Lottie are out of scope for the reference build.

The full decision log is in `update.ai/DECISIONS.md`. Cross-references: `docs/IMPLEMENTATION_ORDER.md`, `update.ai/CURRENT_STATUS.md`.
