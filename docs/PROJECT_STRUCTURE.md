# PROJECT_STRUCTURE.md — SAFE//SPIT

## Guiding rule

The prototype currently lives at a project root literally named `useless` (confirmed from embedded debug source paths in the shipped APK — a fitting detail for the product's sense of humor, but not a name we should ship a repo with). Antigravity should **rename the project root to `safespit` or `safe-spit`** and restructure `lib/` as below, while preserving `safe_spit_calculator.dart` and `safe_spit_sensor_manager.dart` as the literal starting point for the simulation and sensor layers (do not discard proven logic — move and extend it).

## Repository layout

```
SAFE-SPIT/
├── app/                          # Flutter application (Android now, other platforms later if ever)
│   ├── lib/
│   │   ├── main.dart             # App entry, routing only — NOT business logic (unlike prototype)
│   │   ├── simulation/           # PURE, deterministic, no Flutter imports
│   │   │   ├── safe_spit_calculator.dart      # <- promoted from prototype, extended
│   │   │   ├── trajectory_model.dart
│   │   │   ├── vehicle_profiles.dart
│   │   │   ├── scenario.dart                  # scenario/seed model, shared with website spec
│   │   │   └── scoring.dart
│   │   ├── sensors/
│   │   │   ├── sensor_manager.dart            # <- promoted from safe_spit_sensor_manager.dart
│   │   │   ├── normalized_telemetry.dart
│   │   │   ├── sensor_health.dart
│   │   │   └── demo_mode_source.dart
│   │   ├── game/
│   │   │   ├── spit_lock_controller.dart
│   │   │   ├── game_state.dart
│   │   │   ├── match_state.dart               # Spit Olympics / pass-and-play
│   │   │   └── match_service.dart             # online multiplayer (Plan A), optional
│   │   ├── backend/
│   │   │   ├── backend_gateway.dart           # interface
│   │   │   ├── supabase_backend_gateway.dart
│   │   │   └── noop_backend_gateway.dart
│   │   ├── hud/
│   │   │   ├── hud_screen.dart
│   │   │   ├── missile_lock_reticle_painter.dart  # <- promoted from prototype's inline painter
│   │   │   ├── telemetry_bars.dart
│   │   │   └── permission_gate.dart               # <- promoted, generalized
│   │   ├── screens/
│   │   │   ├── vehicle_select_screen.dart
│   │   │   ├── spit_olympics_screen.dart
│   │   │   ├── result_screen.dart
│   │   │   └── leaderboard_screen.dart
│   │   └── shared/                                # small models shared across layers (not "shared with website" — see below)
│   ├── assets/
│   │   ├── audio/lock_tone.mp3    # LOCAL asset — replaces prototype's network-dependent UrlSource (see DECISIONS.md)
│   │   └── fonts/ ...
│   ├── android/                   # standard Flutter Android project (package id decision: see DECISIONS.md)
│   └── test/
│       ├── simulation/            # pure unit tests — the majority of the automated test surface
│       ├── sensors/
│       ├── game/
│       └── widget/
│
├── website/                       # separate app (framework choice: TECH_STACK.md)
│   ├── src/
│   │   ├── simulation/            # shared-spec port of simulation/ (see SIMULATION_SPEC.md §"cross-platform strategy")
│   │   ├── components/
│   │   ├── pages/ (or routes/, depending on framework)
│   │   └── ...
│   └── test/
│       └── simulation/            # runs the SAME shared test vectors as app/test/simulation
│
├── shared-spec/                   # NOT code — the scenario/result JSON contract + test vectors both platforms must satisfy
│   ├── scenario.schema.json
│   ├── result.schema.json
│   └── test-vectors.json
│
├── backend/                       # Supabase project config, migrations, RLS policies (SQL, not application code)
│   └── migrations/
│
├── esp32/                         # optional, isolated, never imported by app/ or website/
│
├── docs/                          # this package
│
├── update.ai/                     # this package
│
├── FAILURE_LOG.md                 # created during reference-build testing, not at planning time
├── BUILD-MANIFEST.md              # created/updated during reference-build testing
└── README.md
```

## Rules for Antigravity

- `app/lib/simulation/**` must never `import 'package:flutter/...'`. If a simulation file needs Flutter, it belongs in `game/` or `hud/` instead. This is the single most important structural rule — it's what keeps the simulation deterministic, testable, and portable to the website.
- `app/lib/sensors/**` is the only place allowed to touch `geolocator`, `sensors_plus`, or `camera` package APIs directly.
- `app/lib/backend/**` is the only place allowed to touch the Supabase client. No screen or game-state file should import Supabase directly.
- Do not create a generic `lib/utils/` or `lib/helpers/` dumping ground. If something doesn't obviously belong in one of the folders above, that's a signal to name it properly, not to hide it.
- `shared-spec/` is intentionally not code. It is the contract both the Android app and the website must satisfy, expressed as data (JSON Schema + literal input/output test vectors), so both platforms can validate against it independently without needing to share a runtime.

## What NOT to build (avoid overbuilding)

- No monorepo build-tool (Nx, Turborepo, Melos, etc.) for this reference build. Three loosely-coupled projects (`app/`, `website/`, `backend/`) sharing one Git repo and one `shared-spec/` folder is sufficient at this scale.
- No microservices. `backend/` is Supabase config only — there is no custom server to deploy for the reference build.

## Reconciliation with the planning package

This file is a faithful record of the planned repository layout. It has been light-edited to align with the planning package. Key decisions reflected here:

- **`shared-spec/` is the cross-platform contract, not code.** It is JSON Schema + literal input/output test vectors that both the Android app and the website must satisfy independently. This is the D-3 strategy: shared-spec, not shared-runtime. The three files (`scenario.schema.json`, `result.schema.json`, `test-vectors.json` with 10 vectors) are the source of truth.
- **`update.ai/` is the AI handoff package.** Four files: `PROJECT_CONTEXT.md` (60-second orientation), `IMPLEMENTATION_RULES.md` (20 non-negotiable rules), `DECISIONS.md` (D-1 through D-20), `CURRENT_STATUS.md` (snapshot of where the project is right now).
- **`FAILURE_LOG.md` and `BUILD-MANIFEST.md` are top-level files.** They are filled during Phase A testing, not at planning time. The templates are in place; the first real entries appear when the first real failure or the first real build happens.

The implementation order is in `docs/IMPLEMENTATION_ORDER.md` (Phase 0 through Phase 17). The first action is Phase 0 (repo setup); the first acceptance criterion is `flutter build apk --debug` producing a hello-world APK.
