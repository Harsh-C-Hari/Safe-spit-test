# SAFE//SPIT — MASTER PROJECT PLAN
## Pre-Implementation, Reference Build & Hackathon Architecture

> **Status (as of 2026-09-03):** PLANNING COMPLETE — READY FOR ANTIGRAVITY.  
> **Date:** 03 September 2026  
> **Hackathon:** 11 September 2026  
> **Purpose of this document:** Source of truth for the planning/architecture phase before implementation.
>
> **The pre-implementation package is complete.** The files listed in the "Pre-implementation package" section below are the canonical source of truth for what Antigravity (the implementation agent) must build. This master plan is the source of truth for the **product vision and why**; the new `docs/`, `update.ai/`, and `shared-spec/` files are the source of truth for the **how**. Where they conflict, the new files win. See [`update.ai/DECISIONS.md`](update.ai/DECISIONS.md) (D-1 through D-20) for the explicit reconciliation log.
>
> **IMPORTANT:** This document is intentionally more detailed than the eventual hackathon implementation. Not every feature listed here must be implemented immediately. Features are prioritized explicitly so the implementation agent can build the reliable core first.

---

# 0. PROJECT DEVELOPMENT STRATEGY

SAFE//SPIT will be developed in multiple stages.

The goal is NOT to spend the hackathon discovering the architecture, debugging unknown sensor behavior, or deciding which features are actually feasible.

Instead:

```text
CURRENT PHASE
    ↓
MASTER PLAN
    ↓
CLAUDE PLANNING / ARCHITECTURE
    ↓
PRE-IMPLEMENTATION PACKAGE
    ↓
ANTIGRAVITY REFERENCE BUILD
    ↓
REAL DEVICE TESTING
    ↓
QA / FAILURE DISCOVERY
    ↓
REFERENCE BUILD FREEZE
    ↓
FINAL HACKATHON IMPLEMENTATION PLAN
    ↓
SEPTEMBER 11
    ↓
IMPLEMENT FROM VALIDATED PLAN
```

---

# Pre-implementation package (2026-09-03 — current canonical source of truth for implementation)

The planning/architecture phase is complete. The following files have been produced and are what the implementation agent must read first. This master plan remains the source of truth for the **product vision and the why**; the new files are the source of truth for the **how**.

| File | Purpose |
|---|---|
| [`docs/IMPLEMENTATION_ORDER.md`](docs/IMPLEMENTATION_ORDER.md) | **The 18-phase build order (Phase 0 → Phase 17).** This is the single most important doc for the implementation agent. Do not start a phase until the prior phase's acceptance criteria pass. |
| [`update.ai/IMPLEMENTATION_RULES.md`](update.ai/IMPLEMENTATION_RULES.md) | 20 non-negotiable engineering rules (Rule 1 → Rule 20). Any change to these requires a new decision in `update.ai/DECISIONS.md`. |
| [`update.ai/DECISIONS.md`](update.ai/DECISIONS.md) | D-1 → D-20 reconciliation log: each decision with context, options, choice, why, and consequences. The first place to look when wondering "why did they do it this way." |
| [`update.ai/PROJECT_CONTEXT.md`](update.ai/PROJECT_CONTEXT.md) | 60-second project orientation for a fresh AI session. |
| [`update.ai/CURRENT_STATUS.md`](update.ai/CURRENT_STATUS.md) | Snapshot of the project's current state. Read this first when resuming work. |
| [`docs/PRODUCT_SPEC.md`](docs/PRODUCT_SPEC.md) | Product definition, target experience, the joke, success criteria, safety boundaries. |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Layered architecture (Presentation → Game → Simulation → Sensor Abstraction → Platform I/O). `NormalizedTelemetry` is the sensor/UI seam. |
| [`docs/SIMULATION_SPEC.md`](docs/SIMULATION_SPEC.md) | The proven formula (preserve byte-for-byte), the `Scenario`/`SimulationResult` types, vehicle modifiers, scoring, determinism rules. |
| [`docs/SENSOR_SPEC.md`](docs/SENSOR_SPEC.md) | Sensor stack, `NormalizedTelemetry`/`SensorHealth`, and the explicit fallback table (including Demo Mode entry per D-1). |
| [`docs/HUD_SPEC.md`](docs/HUD_SPEC.md) | Reticle, telemetry bars, lock state machine, and which elements are PROVEN vs. PLANNED. |
| [`docs/GAME_SPEC.md`](docs/GAME_SPEC.md) | Game loop, mode catalog with explicit S/A/B/C priority per mode, vehicle profiles, scenario seeds, scoring, pass-and-play. |
| [`docs/MULTIPLAYER_SPEC.md`](docs/MULTIPLAYER_SPEC.md) | Plan B (pass-and-play) fully specified; Plan A (online) specified only at surface area. |
| [`docs/SUPABASE_SPEC.md`](docs/SUPABASE_SPEC.md) | Optional backend. `BackendGateway` interface; `NoopBackendGateway` is the default. |
| [`docs/WEBSITE_SPEC.md`](docs/WEBSITE_SPEC.md) | Premium interactive site, not a marketing page. Shares `shared-spec/` with the Android app. |
| [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md) | Unit, integration, widget, device, game, website, end-to-end, and shared-spec parity tests. |
| [`docs/DEMO_PLAN.md`](docs/DEMO_PLAN.md) | Under-90-second judge demo, Demo Mode entry, the 8 robustness conditions. |
| [`docs/RISK_REGISTER.md`](docs/RISK_REGISTER.md) | R-01 → R-20 with Probability, Impact, Detection, Mitigation, Fallback, and P0/P1/P2 priority. |
| [`docs/PROJECT_STRUCTURE.md`](docs/PROJECT_STRUCTURE.md) | Directory layout (now including `shared-spec/`, `update.ai/`). |
| [`docs/TECH_STACK.md`](docs/TECH_STACK.md) | Confirmed and rejected dependencies; D-2/D-8/D-9/D-10/D-16 status. |
| [`shared-spec/scenario.schema.json`](shared-spec/scenario.schema.json) | JSON Schema for a `Scenario` document. |
| [`shared-spec/result.schema.json`](shared-spec/result.schema.json) | JSON Schema for a `SimulationResult` document. |
| [`shared-spec/test-vectors.json`](shared-spec/test-vectors.json) | TV-01 → TV-10: the minimum parity set; the proven three points, the lock-tolerance boundary, negative speed, Car identity, wind, determinism. |
| [`FAILURE_LOG.md`](FAILURE_LOG.md) | F-NN format. Filled by the reference build; empty at planning time. |
| [`BUILD-MANIFEST.md`](BUILD-MANIFEST.md) | Build metadata, devices tested, enabled/disabled features, test status per phase. Template at planning time. |
| [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) | **Older, prototype-aligned plan.** Preserved as evidence; the canonical "how" is `docs/IMPLEMENTATION_ORDER.md`. |
| [`Prototype/safe-spit-prototype.apk`](Prototype/safe-spit-prototype.apk) | The shipped reference build; the source of all PROVEN claims. |

The first implementation should therefore be treated as a:

## REFERENCE / VALIDATION BUILD

It is NOT the final hackathon build.

Its purpose is to determine:

* what actually works
* what does not work
* what looks impressive
* what feels boring
* what sensors are reliable
* what Android limitations exist
* what multiplayer architecture is practical
* what website interactions are worth keeping
* what features should be removed
* what needs fallback behavior
* how long critical implementation actually takes

After this reference build is tested, the final hackathon implementation plan must be rewritten based on reality.

---

# 1. PROJECT VISION

## Working Name

SAFE//SPIT

## Possible Subtitle

Tactical Salivary Ballistics System

## Other Branding Directions

* Advanced Salivary Ballistics Division
* Personal Vehicular Saliva Guidance System
* Tactical Salivary Deployment System
* Project SPITFIRE
* SALIVA-OS

Final branding is NOT locked yet.

---

# 2. CORE CONCEPT

SAFE//SPIT is an intentionally ridiculous tactical system that calculates and simulates the "optimal" trajectory for spitting from moving vehicles.

The joke:

> We built an absurdly sophisticated military/aerospace-grade system for something nobody needs.

The project should combine:

```text
Fighter-Jet HUD
        +
Aerospace Instrumentation
        +
Competitive Sports Game
        +
Premium Experimental Website
        +
Completely Useless Purpose
```

The goal is NOT to claim scientifically accurate real-world spit ballistics.

The physics model should be presented as a:

> fictional / proprietary heuristic simulation

Technical credibility should come from:

* real sensor integration
* responsive telemetry
* deterministic simulation
* sensor-driven interaction
* reliable software architecture
* polished visualization
* testing
* multiplayer architecture

rather than pretending that the fictional formula represents validated aerospace science.

---

# 3. PROJECT ECOSYSTEM

SAFE//SPIT is not intended to be only an Android application.

The planned ecosystem consists of:

```text
                    SAFE//SPIT
                         |
        +----------------+----------------+
        |                |                |
     WEBSITE         ANDROID         SPIT OLYMPICS
        |                |                |
        +----------------+----------------+
                         |
                     SUPABASE
                         |
            USERS / MATCHES / SCORES /
                LEADERBOARDS
```

The major experiences are:

1. SAFE//SPIT Website
2. SPIT OLYMPICS
3. SAFE//SPIT Android App
4. GLOBAL SPIT LEAGUE

The website and Android application should feel like parts of the same fictional universe.

---

# 4. DEVELOPMENT PRIORITY SYSTEM

Every feature must receive an implementation priority.

## S — CORE / MUST WORK

These features define the project.

They should be implemented and tested before optional features.

* Android application
* Tactical HUD
* Real sensor integration
* Vehicle selection
* Dynamic trajectory
* Spit Lock
* Camera passthrough
* Core simulation
* Demo mode
* Basic scoring
* Phone-only operation
* Reliable fallback behavior

## A — HIGH VALUE

Implement after the S-level core is stable.

* Wind visualization
* Sensor diagnostics
* Mission system
* Haptics
* Leaderboard
* Anonymous profiles
* Supabase
* Website
* Spit Olympics
* Deterministic multiplayer
* Replay
* Website simulator
* Online multiplayer if reliable

## B — OPTIONAL POLISH

Only implement if the core is already stable.

* AI Commander
* Voice commands
* ESP32 controller
* Operator profiles
* Tournament mode
* Advanced replay
* Calibration comedy
* Additional vehicle systems
* Advanced audio

## C — EASTER EGGS / NON-ESSENTIAL

Only implement at the very end.

* Extra jokes
* Easter eggs
* Walking mode jokes
* Irrelevant telemetry
* Additional experimental interactions

---

# 5. CRITICAL IMPLEMENTATION RULE

## NEVER ALLOW OPTIONAL FEATURES TO DESTABILIZE THE CORE.

The project must remain complete if all B/C features are removed.

The minimum viable SAFE//SPIT must still be:

```text
Launch
  ↓
System Initialization
  ↓
Vehicle Selection
  ↓
Sensor Initialization
  ↓
Tactical HUD
  ↓
Live Telemetry
  ↓
Trajectory
  ↓
Target Acquisition
  ↓
SPIT LOCK
  ↓
Simulated Launch
  ↓
Score
  ↓
Result
```

---

# 6. ANDROID CORE EXPERIENCE

## Priority: S

The Android application is the primary technical showcase.

Expected flow:

```text
Launch App
    ↓
System Initialization
    ↓
Hardware Diagnostics
    ↓
Vehicle Selection
    ↓
Calibration / Sensor Initialization
    ↓
Tactical HUD
    ↓
Live Telemetry
    ↓
Trajectory Calculation
    ↓
Target Acquisition
    ↓
SPIT LOCK
    ↓
Simulated Launch
    ↓
Score / Result
```

A leaderboard may follow when backend functionality is available.

---

# 7. PHONE HARDWARE UTILIZATION

## Priority: S

Use real phone hardware wherever it materially improves the experience.

## Primary Hardware

* GPS
* Gyroscope
* Accelerometer
* Magnetometer
* Camera
* Speaker / audio
* Haptic motor
* Device orientation

## Secondary / Optional Hardware

* Barometer
* Microphone / voice input
* GNSS satellite information
* Ambient light sensor
* Proximity sensor
* Bluetooth
* NFC

IMPORTANT:

Do NOT add hardware merely to create a checklist.

The preferred experience is:

```text
ONE IMPRESSIVE INTERACTION
        +
MULTIPLE HARDWARE SYSTEMS
```

rather than many disconnected hardware gimmicks.

Example:

```text
Judge moves phone
        ↓
Gyroscope + Accelerometer
        ↓
Orientation changes
        ↓
Trajectory changes
        ↓
Camera HUD reacts
        ↓
Audio changes
        ↓
Haptics trigger
        ↓
SPIT LOCK
```

This interaction should be treated as one of the main WOW moments.

---

# 8. SENSOR FUSION

## Priority: S

The Android app should use real sensor data where practical.

Telemetry should include:

* vehicle speed from GPS
* pitch
* roll
* yaw
* heading
* device orientation

Potential telemetry:

* altitude
* satellite count
* GPS accuracy
* acceleration
* relative wind estimate

The system should visibly react when the user physically moves or tilts the phone.

Changing numbers alone are insufficient.

The judge should be able to perform an action and immediately see the system react.

---

# 9. SENSOR RELIABILITY REQUIREMENT

The reference build must test real devices.

The implementation must not assume that every Android device exposes every sensor.

The system should gracefully handle:

```text
Sensor Available
        ↓
Use Real Sensor
```

and:

```text
Sensor Missing / Permission Denied / Unreliable
        ↓
Diagnostic State
        ↓
Safe Fallback / Demo Mode
```

The app must never become unusable merely because an optional sensor is unavailable.

---

# 10. CURRENT PHYSICS MODEL

The current prototype / implementation plan defines:

```text
targetPitch(v) =
    clamp(
        45° + (v / 5) × 1.2°,
        45°,
        85°
    )
```

Clearance:

```text
|actualPitch - targetPitch| <= 5°
```

Current test points:

```text
0 km/h    → 45°
50 km/h   → 57°
200 km/h  → 85° clamp
```

This must remain a fictional/proprietary heuristic model.

It must NOT be presented as scientifically validated ballistics.

The simulation layer may later become more sophisticated, but complexity must not compromise reliability.

---

# 11. SIMULATION ENGINE

## Priority: S / A

The simulation should be separated from the presentation layer.

The simulation should accept normalized inputs such as:

```text
speed
pitch
roll
yaw
wind
wind direction
vehicle
target
scenario seed
```

and produce:

```text
trajectory
impact position
deviation
lock quality
timing
score
result
```

The simulation should be deterministic when given the same scenario seed and inputs.

This is important for multiplayer.

---

# 12. SHARED SIMULATION PRINCIPLE

The website and Android application should not implement unrelated simulation logic.

Preferred architecture:

```text
ANDROID
Real Sensors
    ↓
Input Normalizer
    ↓
             SHARED SIMULATION MODEL
    ↑
Input Normalizer
    ↑
WEBSITE
Mouse / Touch / Keyboard
```

This allows:

```text
Android Player
      VS
Website Player
```

under identical simulated conditions.

Claude must determine the most practical technology for sharing or reproducing the simulation logic across Android and web.

Do not force a technically complicated shared-runtime architecture if a deterministic compatible model is more reliable.

---

# 13. TACTICAL HUD

## Priority: S

The HUD is the visual centerpiece of the Android application.

Style direction:

```text
Aerospace HUD
      +
Military Instrumentation
      +
Sci-Fi Tactical Interface
```

Core elements:

* camera passthrough
* tactical overlay
* central targeting reticle
* center pip
* corner brackets
* crosshair
* outer lock ring
* target marker
* pitch indicator
* target pitch
* actual pitch
* angle error
* vehicle speed
* wind vector
* lock status
* system status
* diagnostics
* mission information
* trajectory visualization

Existing implementation concept includes:

* inner reticle
* center pip
* four corner brackets
* cardinal crosshair
* secondary lock ring
* green clear state
* red danger state

---

# 14. HUD STATE SYSTEM

## Priority: S

Primary states:

### CLEAR / LOCKED

Tactical neon green.

### DANGER

Tactical neon red.

Potential states:

### SYSTEM

Neutral technical UI.

### WARNING

Amber/orange direction.

### ACQUIRING

Animated targeting state.

Exact final palette is not locked.

The visual language should be consistent across:

* Android
* website
* game
* leaderboard
* branding

---

# 15. SPIT LOCK

## Priority: S — SIGNATURE FEATURE

Spit Lock should be one of the most polished interactions in the entire project.

State progression:

```text
SEARCHING
    ↓
TARGET ACQUISITION
    ↓
TRAJECTORY FOUND
    ↓
LOCKING
    ↓
SPIT LOCK
    ↓
CLEAR TO EJECT
```

When lock occurs:

* reticle animation
* green state transition
* audio lock tone
* haptic feedback
* visual flash
* trajectory confirmation

The audio must trigger on the state transition rather than continuously.

The complete interaction should feel responsive and deliberate.

---

# 16. DYNAMIC TRAJECTORY

## Priority: S

Display a predicted trajectory.

It should react to:

* vehicle speed
* pitch
* device orientation
* wind
* vehicle profile
* target position
* simulated conditions

Expected WOW interaction:

```text
Move phone
    ↓
Orientation changes
    ↓
Trajectory moves
```

```text
Tilt phone
    ↓
Pitch changes
    ↓
Trajectory changes
```

```text
Rotate phone
    ↓
Relative wind changes
    ↓
Trajectory changes
```

The trajectory should be visually obvious enough for a judge to understand that the system is actually reacting.

---

# 17. WIND VISUALIZATION

## Priority: A

Represent relative wind visually.

Potential implementation:

* animated particles
* arrows
* vector indicators
* wind speed
* wind direction

Example:

```text
WIND
18.2 KM/H
→ → → → →
```

Wind visualization should react to orientation and simulation state.

---

# 18. VEHICLE SELECTOR

## Priority: S

Vehicle selection is a major feature.

Possible vehicles:

* Car
* Bus
* Bike
* Auto
* Train
* Tractor
* Aircraft
* Walking
* Other

Each vehicle should have a fictional "spit profile."

Example:

```text
BUS

AERODYNAMIC RESISTANCE
HIGH

TURBULENCE
EXTREME

SPIT DIFFICULTY
★★★★☆
```

The selector should feel like an aerospace equipment selection system rather than a normal dropdown.

Possible presentation:

* large cards
* vehicle illustrations
* animated transitions
* telemetry changes
* unique profile data

---

# 19. VEHICLE PROFILE SYSTEM

## Priority: A

Each vehicle can affect simulation parameters.

Potential parameters:

* aerodynamic resistance
* turbulence
* velocity range
* wind sensitivity
* stability
* difficulty
* recommended angle
* fictional vehicle-specific modifiers

These parameters do not need to represent scientifically accurate vehicle aerodynamics.

They exist to make the simulation and game more interesting.

---

# 20. SENSOR DIAGNOSTICS

## Priority: A

A dedicated technical diagnostics interface should expose the system's actual hardware state.

Example:

```text
GPS
18 SATELLITES
46.73 KM/H
±1.8M

IMU
PITCH 51.24°
ROLL -2.13°
YAW 183.72°

MAGNETOMETER
HEADING 274°

BAROMETRIC
ALTITUDE 31.2M

AUDIO
SPL 63 dB

SYSTEM
THERMAL NOMINAL

COMMON SENSE
OFFLINE
```

Only display measurements that are actually available.

Do not fabricate hardware readings and present them as real sensor data.

---

# 21. CALIBRATION SEQUENCE

## Priority: B

Startup calibration should feel unnecessarily serious.

Example:

```text
CALIBRATION REQUIRED

Place device on a perfectly
horizontal surface.

CALIBRATING...
```

Potential comedy:

```text
CALIBRATION 100%

ERROR

SURFACE TOO FLAT.
```

This is polish and comedy, not core functionality.

---

# 22. MISSION SYSTEM

## Priority: A

Each simulation can be treated as a mission.

Mission contains:

* vehicle
* speed
* wind
* target
* target movement
* difficulty
* player
* score
* result

Example:

```text
MISSION #0421

VEHICLE      BUS
SPEED        46 KM/H
WIND         12 KM/H
PITCH        56.2°
LOCK         94%
RESULT       SUCCESS
```

---

# 23. SPIT OLYMPICS

## Priority: S / A

Spit Olympics is a major part of the project.

SAFE//SPIT becomes a competitive simulation game.

Core principle:

> Two players receive identical conditions.

Example:

```text
MATCH #8F42A7

VEHICLE          BUS
VELOCITY         67.4 KM/H
WIND             18.2 KM/H
WIND DIRECTION   241°
CROSSWIND        6.4 KM/H
TARGET           14.7 M

CONDITIONS LOCKED
```

Both players attempt the same simulated challenge.

The game must simulate the action.

Do not encourage actual spitting at people, vehicles, or property.

---

# 24. SPIT OLYMPICS GAME MODES

## Priority: A

Potential modes:

### Precision Spit

Closest trajectory to optimal trajectory.

### Target Strike

Hit a simulated target.

### Speed Lock

Acquire lock as quickly as possible.

### Crosswind Challenge

Extreme wind conditions.

### Chaos Mode

Unstable conditions.

### Blind Mode

Reduced visual information.

### Vehicle Challenge

Specific vehicle profiles.

### Tournament Mode

Knockout competition.

Final mode selection should be determined after the reference build.

Prefer fewer polished modes over many incomplete modes.

---

# 25. MULTIPLAYER ARCHITECTURE

## Priority: A

There should be two multiplayer plans.

---

## PLAN A — TRUE ONLINE MULTIPLAYER

Potential Supabase-backed system:

```text
Create Match
    ↓
Match Code / Link
    ↓
Opponent Joins
    ↓
Same Scenario
    ↓
Both Play
    ↓
Results
    ↓
Leaderboard
```

Potential capabilities:

* room codes
* invite links
* live match state
* player presence
* synchronized scenario
* score submission

This is optional until its technical reliability is proven.

---

## PLAN B — DETERMINISTIC PASS-AND-PLAY

This must be implemented before true online multiplayer if multiplayer is being developed.

Generate a deterministic scenario seed.

Example:

```text
MATCH SEED
#8F42A7
```

The seed generates:

* vehicle
* speed
* wind
* target
* difficulty
* environmental conditions

Player 1 plays.

Then:

```text
PASS DEVICE
```

Player 2 receives exactly the same scenario.

This provides reliable local multiplayer without networking.

---

# 26. WEBSITE MULTIPLAYER

## Priority: A

The website should eventually host Spit Olympics.

Browser players do not need physical sensors.

They can use:

* mouse
* touch
* keyboard
* virtual controls

The browser sends normalized input into the same simulation model.

Potential architecture:

```text
ANDROID
Real Sensors
    ↓
Input Normalizer
    ↓
Shared Simulation
    ↑
Input Normalizer
    ↑
WEBSITE
Mouse / Touch / Keyboard
```

This could allow:

```text
Android Player
        VS
Website Player
```

under identical simulated conditions.

This is a high-value technical concept, but it must not destabilize the Android core.

---

# 27. SCENARIO SEED SYSTEM

## Priority: A

Multiplayer and repeatable testing should use deterministic scenarios.

A scenario seed should determine:

* vehicle
* vehicle parameters
* speed
* wind speed
* wind direction
* crosswind
* target distance
* target movement
* difficulty
* environmental conditions

Example:

```text
SEED
8F42A7
```

should always produce the same scenario when used with the same scenario-generation version.

This allows:

* fair multiplayer
* repeatable tests
* debugging
* replay
* tournaments
* daily challenges

---

# 28. SCORING SYSTEM

## Priority: S for simulator / A for leaderboard

Potential scoring dimensions:

### Trajectory Precision

Distance from optimal trajectory.

### Impact Accuracy

Distance from target.

### Timing

How close to optimal timing.

### Stability

How steady the player/device was.

### Lock Quality

How accurately the player entered the lock window.

Optional:

### Style Points

Completely useless bonus points.

Example:

```text
PRECISION       4,200
IMPACT          3,100
TIMING          1,400
STABILITY         900
STYLE             242
---------------------
TOTAL           9,842
```

Exact scoring formula is not locked.

The formula should be determined during the simulation design phase and validated during the reference build.

---

# 29. GLOBAL SPIT LEAGUE

## Priority: A

A shared leaderboard can eventually connect the website and Android application.

Categories:

* Overall
* Precision
* Speed
* Crosswind
* Vehicle-specific
* Tournament
* Chaos
* Daily Challenge

Potential profile:

```text
CALLSIGN
MATCHES
WINS
LOSSES
WIN RATE
HIGH SCORE
PERFECT LOCKS
RANK
```

---

# 30. ANONYMOUS USERS

## Priority: S

Do NOT force login before playing.

First visit:

```text
PLAY NOW
```

System generates a random callsign:

```text
SPIT-48291
```

or:

```text
VECTOR-GOBLIN
```

or:

```text
SALIVA-7F31
```

The user should be able to experience the game immediately.

---

# 31. AUTHENTICATION

## Priority: A

Authentication should be optional.

After achieving a score:

```text
SAVE YOUR RECORD

Continue with Google
```

Potential implementation:

* Supabase Auth
* Google OAuth
* anonymous → authenticated account migration

Exact implementation must be validated before being considered critical.

---

# 32. SUPABASE

## Priority: A

Potential uses:

* authentication
* anonymous user identities
* user profiles
* callsigns
* matches
* match seeds
* scores
* leaderboards
* match history
* multiplayer state

Potential schema:

```text
users
profiles
matches
match_players
scores
leaderboard_entries
```

Exact schema must be finalized during the architecture phase.

Do not build unnecessary backend infrastructure before the local application/game is working.

---

# 33. OFFLINE-FIRST / FAILURE RESILIENCE

## Priority: S

The core Android experience must not depend entirely on:

* internet
* Supabase
* online multiplayer
* GPS availability
* optional sensors

The application must have a usable demonstration path when network services fail.

Minimum fallback:

```text
REAL SENSORS
    ↓
if available
    ↓
REAL EXPERIENCE

otherwise

DEMO / SIMULATION MODE
```

The reference build must explicitly test:

* no internet
* Supabase unavailable
* GPS permission denied
* camera permission denied
* sensor unavailable
* inaccurate GPS
* sensor stream interruption
* app backgrounding
* device rotation
* audio failure
* haptic failure

---

# 34. DEMO MODE

## Priority: S

Mandatory.

Demo mode exists so the project can be demonstrated reliably even if real-world conditions are poor.

It should simulate:

* vehicle speed
* wind
* target
* sensor input
* trajectory
* lock
* launch
* scoring

However, real hardware interaction should remain the preferred demo whenever it is working.

The judge should be able to see:

```text
Move phone
    ↓
HUD reacts
    ↓
Trajectory changes
    ↓
Lock
    ↓
Haptic + Audio
    ↓
Simulated Launch
    ↓
Score
```

---

# 35. WEBSITE

## Priority: A

The website should NOT be a conventional marketing landing page.

It should be an independent premium interactive experience.

Concept:

```text
Aerospace Instrumentation
        +
Experimental Web Design
        +
Playful Uselessness
        +
Editorial Typography
        +
Interactive Storytelling
```

Goal:

> Make it feel like a custom $10k experimental website, not a generic AI-generated landing page.

---

# 36. WEBSITE STRUCTURE

Do NOT default to:

```text
Hero
Features
About
Screenshots
Download
Footer
```

Instead consider:

```text
CINEMATIC INTRO
        ↓
SAFE//SPIT WORLD
        ↓
THE "SCIENCE"
        ↓
INTERACTIVE HUD
        ↓
VEHICLE SELECTOR
        ↓
SPIT OLYMPICS
        ↓
GLOBAL LEAGUE
        ↓
ANDROID APP
        ↓
DEPLOY / DOWNLOAD
```

Exact structure remains open.

---

# 37. WEBSITE CINEMATIC INTRO

Potential opening:

```text
BLACK SCREEN

INITIALIZING SALIVARY
DEFENSE NETWORK...

GPS ............ ONLINE
IMU ............ ONLINE
TRAJECTORY ..... ONLINE
SPIT ENGINE .... ONLINE
COMMON SENSE ... OFFLINE
```

Then:

```text
SAFE//SPIT

TACTICAL SALIVARY
BALLISTICS
```

Possible typography sequence:

```text
SPIT.

        ↓

WITH PRECISION.

        ↓

AT SPEED.

        ↓

WHY?

We asked ourselves the same question.
```

---

# 38. WEBSITE INTERACTION

Potential interactions:

* cursor becomes targeting reticle
* mouse movement affects HUD
* scroll controls virtual vehicle movement
* wind particles react to movement
* interactive trajectory
* clickable targets
* keyboard Easter eggs
* interactive diagnostics
* vehicle selector
* embedded Spit Olympics
* animated telemetry
* sound design
* page transitions

Avoid interactions simply because they look cool.

Every major interaction should reinforce the SAFE//SPIT universe.

---

# 39. WEBSITE SPIT OLYMPICS

## Priority: A

Visitors should be able to play directly from the website.

Potential flow:

```text
PLAY NOW
    ↓
RANDOM CALLSIGN
    ↓
SCENARIO
    ↓
SIMULATOR
    ↓
SCORE
    ↓
GLOBAL RANK
    ↓
CHALLENGE FRIEND
```

Potential multiplayer:

```text
CREATE ROOM
    ↓
MATCH CODE
    ↓
FRIEND JOINS
    ↓
SAME CONDITIONS
    ↓
HEAD-TO-HEAD
```

---

# 40. WEBSITE LEADERBOARD

## Priority: A

Potential display:

```text
GLOBAL SPIT LEAGUE

#01 SALIVA_SAM       98,421
#02 SPITFIRE         97,883
#03 VECTOR_VIKING    96,412
#04 BUS_BANDIT       95,771
```

Include:

* rank
* callsign
* score
* category
* vehicle
* recent matches

---

# 41. WEBSITE APP DOWNLOAD

## Priority: A

The website should eventually connect to the final Android APK.

Example:

```text
ANDROID DEPLOYMENT PACKAGE

VERSION
0.1.0 // EXPERIMENTAL

REQUIREMENTS

Android 10+
GPS
Gyroscope
Camera
Questionable sense of responsibility

[ DEPLOY ]
```

The download link can be updated after the hackathon.

---

# 42. WEBSITE VISUAL DIRECTION

Preferred direction:

```text
Tactical Aerospace
        +
Experimental Editorial
        +
Selective Playful Brutalism
        +
Premium Motion Design
```

Do NOT make the entire site generic Neo-Brutalist.

Brutalism can be selectively used for:

* typography
* game screens
* leaderboard
* vehicle cards
* section transitions
* humorous moments

The HUD should remain aerospace/tactical.

---

# 43. PREMIUM WEBSITE RULES

Avoid:

* generic AI SaaS layouts
* excessive cards
* random gradients
* generic 3D blobs
* excessive glassmorphism
* meaningless animations
* generic Three.js scenes
* template-like sections
* excessive shadows
* overuse of glowing effects

Prioritize:

* art direction
* typography
* motion
* composition
* narrative
* sound
* interaction
* micro-interactions
* performance
* restraint

---

# 44. AI COMMANDER

## Priority: B

Optional character/voice system.

Potential behavior:

```text
COMMANDER:

Vehicle velocity is 61 km/h.

Trajectory is questionable.

I have nevertheless calculated
the optimal deployment window.

Do not embarrass us.
```

It should enhance the experience.

It must NOT become a generic chatbot.

---

# 45. VOICE CONTROL

## Priority: B / A IF RELIABLE

Potential commands:

```text
Arm system.
Acquire target.
Fire.
Abort.
```

Potential response:

```text
Negative.
Trajectory unsafe.
```

Voice control must never be required for the core experience.

---

# 46. HAPTICS

## Priority: A

Potential patterns:

```text
SEARCHING
subtle pulse

TARGET ACQUIRED
double pulse

LOCK
strong pulse

DANGER
rapid vibration
```

Haptics are considered high-value because they are inexpensive to implement but can significantly increase perceived polish.

---

# 47. MISSION REPLAY

## Priority: B / A

After simulated launch:

```text
MISSION COMPLETE

TRAJECTORY CAPTURED

ANALYZING...
```

Then:

```text
VEHICLE
BUS

VELOCITY
47.2 KM/H

PITCH
56.8°

DEVIATION
2.4°

LOCK QUALITY
96%

RESULT
★★★★★
```

Potential replay animation.

Only implement after core simulation and scoring are stable.

---

# 48. OPERATOR PROFILE

## Priority: B

Potential profile:

* callsign
* rank
* missions
* wins
* losses
* perfect locks
* precision
* high score
* favorite vehicle

Potential ranks:

```text
ROOKIE SPITTER
FIELD SPITTER
PRECISION SPITTER
ELITE SPITTER
SALIVARY COMMANDER
```

---

# 49. EASTER EGGS

## Priority: C

Possible examples:

```text
WALKING MODE

VELOCITY
4.8 KM/H

COMPUTATIONAL REQUIREMENT
0.0001 TFLOPS

WHY ARE YOU USING THIS?
```

or:

```text
COMMON SENSE
OFFLINE
```

or:

```text
JUPITER POSITION
238.4°

RELEVANCE
ABSOLUTELY NONE
```

Only implement these after the core is reliable.

---

# 50. OPTIONAL ESP32 HARDWARE

## Priority: B / A ONLY IF RELIABLE

ESP32 must NOT be part of the core architecture.

Development order:

```text
PHONE-ONLY CORE
        ↓
COMPLETE + TEST
        ↓
ESP32 EXPERIMENT
        ↓
IF RELIABLE
    ↓
OPTIONAL DEMO ENHANCEMENT

IF UNRELIABLE
    ↓
REMOVE
```

Potential controller:

```text
SAFE//SPIT CONTROL PANEL
```

Components:

* ARM switch
* FIRE button
* LEDs
* buzzer
* rotary encoder
* optional display
* Bluetooth communication

Potential interaction:

```text
PHONE

TARGET LOCKED
      ↓
Physical Controller

GREEN LED
BEEP
      ↓
Judge presses FIRE
```

The Android app MUST always work without the external hardware.

---

# 51. HARDWARE PLAN

## PLAN A — PHONE ONLY

Reliable and complete.

This is mandatory.

## PLAN B — PHONE + ESP32

Only if stable.

Use in the demo only after validation.

## PLAN C — ADDITIONAL PHYSICAL INSTRUMENTATION

Only if everything else is already reliable.

Never allow external hardware to become a single point of failure.

---

# 52. TESTING STRATEGY

Testing is part of the reference build.

The reference build must test:

## Physics

```text
0 km/h → 45°
50 km/h → 57°
200 km/h → 85° clamp
```

## Lock tolerance

```text
target ±4.9° → LOCK
target ±5.0° → LOCK
target ±5.1° → NOT LOCKED
```

## Sensors

* gyro integration
* accelerometer
* magnetometer
* GPS
* sensor interruption
* missing sensors
* noisy sensors
* device rotation

## Camera

* permission granted
* permission denied
* camera unavailable
* app backgrounding

## Audio

* lock transition triggers once
* no duplicate lock sound
* audio failure does not crash app

## Haptics

* state transitions
* unavailable haptics

## Backend

* network available
* network unavailable
* Supabase unavailable
* invalid response
* anonymous user
* authenticated user

## Multiplayer

* deterministic scenario
* pass-and-play
* room creation
* opponent joining
* disconnects

## Website

* desktop
* mobile
* touch
* keyboard
* performance
* reduced-motion considerations

---

# 53. REFERENCE BUILD FAILURE TESTING

The reference build must intentionally attempt to break itself.

Test:

```text
NO INTERNET
GPS DENIED
CAMERA DENIED
SENSOR MISSING
GPS INACCURATE
AUDIO OFF
HAPTICS UNAVAILABLE
APP BACKGROUNDED
SCREEN ROTATED
LOW-END DEVICE
NETWORK FAILURE
SUPABASE FAILURE
MULTIPLAYER DISCONNECT
INVALID DATA
```

Every discovered failure should be documented.

Create:

```text
FAILURE_LOG.md
```

Each issue should record:

```text
Problem
Cause
Impact
Fix
Fallback
Verification
```

---

# 54. REFERENCE BUILD ARTIFACTS

At the end of the reference-build phase, preserve:

```text
REFERENCE-BUILD/
├── source
├── APK
├── documentation
├── screenshots
├── demo recording
├── configuration documentation
├── test results
├── FAILURE_LOG.md
└── BUILD-MANIFEST.md
```

`BUILD-MANIFEST.md` should document:

* what works
* what does not work
* tested devices
* Android versions
* required permissions
* dependencies
* backend configuration
* known limitations
* optional features
* abandoned features
* demo procedure
* recovery procedure

---

# 55. CLAUDE'S ROLE BEFORE IMPLEMENTATION

The first Claude is the planning / architecture preparation agent.

Claude should NOT blindly start implementing the entire product.

Claude must analyze:

1. this master plan
2. the older/basic implementation plan
3. the existing prototype if provided
4. technical feasibility
5. conflicts between plans
6. implementation dependencies
7. feature priorities
8. testing requirements

Claude should produce the complete pre-implementation package required by the main Antigravity implementation agent.

Expected documents may include:

```text
PRODUCT_SPEC.md
ARCHITECTURE.md
TECH_STACK.md
PROJECT_STRUCTURE.md
SIMULATION_SPEC.md
SENSOR_SPEC.md
HUD_SPEC.md
GAME_SPEC.md
MULTIPLAYER_SPEC.md
SUPABASE_SPEC.md
WEBSITE_SPEC.md
TEST_PLAN.md
DEMO_PLAN.md
RISK_REGISTER.md
IMPLEMENTATION_ORDER.md
```

Claude may add additional documents where useful.

The exact final document structure is Claude's responsibility, provided that it remains practical and implementation-oriented.

---

# 56. CLAUDE MUST RECONCILE THE TWO PLANS

The older plan contains concrete implementation details such as:

* Flutter dependencies
* `SafeSpitCalculator`
* `SafeSpitSensorManager`
* GPS velocity
* gyro integration
* HUD painter
* permission gate
* camera passthrough
* audio lock transition
* unit tests

The newer master plan expands the product into:

* sensor fusion
* simulation
* Spit Olympics
* deterministic multiplayer
* website
* Supabase
* leaderboard
* profiles
* optional ESP32
* premium interactive experience

Claude must combine these intelligently.

Do NOT simply duplicate them.

Do NOT remove useful concrete implementation details merely because the newer plan is larger.

Do NOT attempt to implement every optional idea immediately.

The result must be a coherent implementation architecture.

---

# 57. ANTIGRAVITY'S ROLE

After Claude produces the pre-implementation package, Antigravity becomes the primary implementation agent.

Antigravity should receive:

```text
MASTER PLAN
+
OLDER IMPLEMENTATION PLAN
+
CLAUDE'S PRE-IMPLEMENTATION PACKAGE
+
EXISTING PROJECT / PROTOTYPE
```

Antigravity's first goal:

> Build the complete phone-only reference/validation version.

The implementation should proceed in dependency order.

Recommended high-level order:

```text
1. Project foundation
        ↓
2. Domain / simulation logic
        ↓
3. Sensor layer
        ↓
4. Android permissions
        ↓
5. HUD
        ↓
6. Vehicle system
        ↓
7. Trajectory
        ↓
8. Spit Lock
        ↓
9. Audio + haptics
        ↓
10. Demo mode
        ↓
11. Scoring
        ↓
12. Spit Olympics
        ↓
13. Backend / leaderboard
        ↓
14. Website
        ↓
15. Multiplayer
        ↓
16. Optional polish
        ↓
17. ESP32 experiment
```

The exact order may be changed by Claude/Antigravity if technical dependencies require it.

---

# 58. FULL-PROJECT HANDOFF RULE

Whenever an implementation agent modifies the project, it should preserve a complete runnable project state.

Do NOT rely on:

```text
"Here are the 3 files I changed."
```

Instead, workers/agents should return the full relevant project or a complete project archive containing the current state.

This prevents context loss between different agents and sessions.

---

# 59. AGENT HANDOFF ARTIFACTS

Every significant agent should leave behind useful artifacts.

Examples:

```text
DECISIONS.md
FAILURE_LOG.md
TEST_RESULTS.md
CURRENT_STATUS.md
IMPLEMENTATION_NOTES.md
```

Agents should document:

* decisions
* assumptions
* completed work
* incomplete work
* known bugs
* rejected approaches
* next steps
* dependencies
* recovery instructions

---

# 60. REFERENCE BUILD FREEZE

When the reference build is stable:

```text
REFERENCE BUILD v1.0
```

Freeze it.

Preserve:

* source
* APK
* documentation
* test results
* screenshots
* demo video
* configuration
* failure log
* build manifest

Do not continuously modify the frozen reference copy.

Create a separate development copy for further experiments.

---

# 61. FINAL HACKATHON PLAN GENERATION

After the reference build has been tested and frozen, create:

```text
HACKATHON_IMPLEMENTATION_PLAN.md
```

This is NOT the same as the current master plan.

It must be based on what actually happened during the reference build.

It should contain:

* exact project structure
* exact implementation order
* exact dependencies
* exact commands
* known Android issues
* tested sensor behavior
* known limitations
* feature priorities
* fallback implementations
* estimated implementation time
* testing checkpoints
* demo procedure
* emergency recovery plan
* features that must NOT be attempted
* features that can be added if time remains

The final hackathon plan should be execution-oriented.

The objective is:

```text
NO ARCHITECTURAL EXPLORATION
        ↓
NO UNKNOWN CORE FEATURES
        ↓
NO LAST-MINUTE DESIGN DECISIONS
        ↓
FOLLOW VALIDATED PLAN
        ↓
BUILD
```

---

# 62. SEPTEMBER 11 BUILD STRATEGY

The hackathon build should start from a fresh project / clean implementation according to the final validated plan.

The reference build is used for:

* learning
* validation
* comparison
* troubleshooting
* understanding failures
* confirming feasibility

It must NOT be represented as the hackathon-created project.

The hackathon project must comply with the event's rules regarding when and how the project is created and documented.

If a catastrophic implementation problem occurs, the frozen reference build exists as a disaster-recovery/reference artifact.

Any use of pre-existing work must comply with the organizers' rules.

---

# 63. DEMO SCRIPT

The demo should be extremely simple.

Potential script:

```text
"We noticed a serious problem."

PAUSE

"People don't know the correct angle
to spit from moving vehicles."

PAUSE

"So we solved it."
```

Then:

```text
Select Vehicle
        ↓
System Initialization
        ↓
Live Sensors
        ↓
Tactical HUD
        ↓
Physically Move Phone
        ↓
Trajectory Reacts
        ↓
Target Acquisition
        ↓
SPIT LOCK
        ↓
Haptic + Audio
        ↓
Simulated Launch
        ↓
Score
```

Final line:

> You are now certified for high-precision vehicular spitting.

Do not actually spit at people, vehicles, or property during the demonstration.

The demonstration should be simulated.

---

# 64. WOW MOMENT PRINCIPLE

The project should prioritize one extremely convincing interaction over dozens of disconnected features.

Ideal sequence:

```text
JUDGE TOUCHES / MOVES PHONE
        ↓
REAL SENSOR DATA CHANGES
        ↓
HUD RESPONDS
        ↓
TRAJECTORY RESPONDS
        ↓
TARGET ACQUIRED
        ↓
HAPTIC FEEDBACK
        ↓
LOCK SOUND
        ↓
SIMULATED LAUNCH
        ↓
SCORE
```

If this works reliably, SAFE//SPIT already has a strong demonstration.

Everything else should support this experience.

---

# 65. FEATURE CUT ORDER

If development time becomes limited, remove features in this order:

```text
1. Easter eggs
2. AI Commander
3. Advanced AI
4. Extra hardware
5. Online multiplayer
6. Voice control
7. Complex replay
8. Advanced website interactions
9. Tournament systems
10. Non-essential profiles
```

Never cut:

```text
HUD
Sensor response
Vehicle selector
Trajectory
Spit Lock
Core simulation
Demo mode
Basic scoring
Phone-only operation
```

---

# 66. SUCCESS CRITERIA FOR REFERENCE BUILD

The reference build is successful when:

* Android app launches reliably
* core simulation works
* real sensor input works on tested devices
* HUD responds smoothly
* trajectory responds visibly
* vehicle selection affects simulation
* Spit Lock works reliably
* audio triggers correctly
* haptics work where available
* demo mode works without external dependencies
* scoring works
* failure states are handled
* no critical crash remains
* website core experience works if implemented
* Spit Olympics core works if implemented
* deterministic scenarios work
* optional features have been evaluated
* all important failures are documented

The reference build does NOT need every B/C feature.

Reliability is more important than feature count.

---

# 67. FINAL PRODUCT PHILOSOPHY

SAFE//SPIT should feel like:

```text
A military system
        ↓
built by aerospace engineers
        ↓
for an incredibly stupid problem
        ↓
that somehow works.
```

The technical sophistication should be real.

The purpose should be ridiculous.

The interface should be premium.

The interaction should be memorable.

The project should make judges think:

> "Why does this exist?"

followed immediately by:

> "Wait... this is actually really well made."

That is the target.