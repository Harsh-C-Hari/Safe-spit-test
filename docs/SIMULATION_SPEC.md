# SIMULATION_SPEC.md — SAFE//SPIT

## Core principle

Everything in this file describes **pure functions**: given the same inputs, always the same outputs. No Flutter, no I/O, no randomness except through an explicit, passed-in seed. This is what makes the simulation deterministic, unit-testable, reusable by the website, and safe to use for multiplayer and replay.

## PROVEN core: departure pitch formula

Confirmed byte-for-byte from the shipped prototype's compiled `SafeSpitCalculator` class (matches both the older implementation plan and the latest plan — no conflict here, this formula should be preserved as-is):

```
baseAngle        = 45.0°
maxAngle         = 85.0°
tiltPerSpeedStep = 1.2°
speedStepKmh     = 5.0 km/h

targetPitch(v) = clamp( baseAngle + (v / speedStepKmh) * tiltPerSpeedStep, baseAngle, maxAngle )
```

Test points (PROVEN, confirmed against the prototype's own doc comments and the older implementation plan):

| Speed | Target pitch |
|---|---|
| 0 km/h | 45.0° |
| 50 km/h | 57.0° |
| 200 km/h | 85.0° (clamped) |

Clearance / lock tolerance (PROVEN):

```
Δθ = |actualPitch - targetPitch|
isClearToEject = Δθ <= 5.0°
```

**This is fictional/proprietary heuristic, not real aerodynamics or ballistics.** No user-facing or marketing copy should claim scientific validity. Internally, code comments may keep the "aerospace" flavor text for tone, but must not be presented to the end user as fact.

## Simulation inputs (target shape for the reference build)

```
ScenarioInput {
  scenarioSeed: string          // deterministic RNG seed (for wind, target placement, Spit Olympics)
  vehicle: VehicleProfile       // PLANNED — see below
  speedKmh: double              // from normalized telemetry (real or Demo Mode)
  actualPitchDeg: double        // from normalized telemetry (integrated gyro)
  rollDeg: double                // PLANNED
  yawDeg: double                 // PLANNED
  headingDeg: double              // PLANNED
  windSpeedKmh: double            // PLANNED, derived deterministically from scenarioSeed unless explicitly set
  windDirectionDeg: double        // PLANNED, same
  targetDistanceM: double         // PLANNED — Spit Olympics target placement
}
```

## Simulation outputs

```
SimulationResult {
  targetPitchDeg: double         // PROVEN formula output
  deltaDeg: double                // PROVEN
  isClearToEject: bool            // PROVEN
  lockQuality: 0.0..1.0           // PLANNED — how centered within tolerance, for scoring nuance
  trajectory: List<Point>         // PLANNED — for HUD line/arc rendering and website visualization
  impactPosition: Point           // PLANNED — for Spit Olympics scoring
  deviationM: double              // PLANNED
  score: int                      // PLANNED — see scoring below
}
```

## Vehicle modifiers (PLANNED — not present in the prototype at all)

The prototype has **no vehicle concept whatsoever** — it computes pitch purely from raw GPS speed regardless of vehicle type. The latest plan's vehicle selector (Car, Bus, Bike, Auto, Train, Tractor, Aircraft, Walking, Other) is entirely new work. Recommended approach: vehicle profiles apply **multiplicative/additive fictional modifiers** on top of the proven base formula, never replacing it:

```
targetPitch(v, vehicle) = clamp(
  baseAngle + (v / speedStepKmh) * tiltPerSpeedStep * vehicle.turbulenceFactor + vehicle.angleBias,
  baseAngle,
  maxAngle
)
```

Where `turbulenceFactor` defaults to `1.0` (i.e. "Car" should reproduce the proven formula exactly, so existing test vectors keep passing) and `angleBias` defaults to `0.0`. Each vehicle profile is a small, hand-authored, explicitly fictional data record — do not try to make these "realistic."

## Wind (PLANNED)

Wind is derived deterministically from `scenarioSeed` (so two players in Spit Olympics get identical wind) and applied as a lateral deviation to `impactPosition`, not to the pitch-lock calculation itself — the pitch/lock mechanic (the core WOW moment) must stay exactly as proven and must not become harder to demo because of a new wind variable. Wind only affects the *score/impact* stage, after lock.

## Scoring (PLANNED — UNKNOWN precise formula, propose starting point)

```
score = baseScoreForLock(lockQuality) - distancePenalty(deviationM) + timingBonus(timeToLockMs)
```

Exact constants are UNKNOWN and should be tuned during reference-build playtesting, not decided at planning time. Log tuning decisions in `update.ai/DECISIONS.md` once chosen.

## Determinism requirements

- Given an identical `ScenarioInput` (including `scenarioSeed`), the simulation must produce bit-identical `SimulationResult` on both Android and (if implemented) the website.
- Any randomness (wind, target placement) must derive from `scenarioSeed` via a seeded PRNG, never from wall-clock time, device randomness, or platform RNGs.
- This determinism is what makes Spit Olympics pass-and-play, replay, and daily-challenge features possible without a shared server round-trip.

## Cross-platform strategy (Android + website)

Do **not** force a single shared runtime (e.g. compiling Dart to WASM for the web, or reimplementing the website in Flutter web) purely for code-sharing purposes — this is exactly the kind of "impressive on paper" complexity the master plan warns against (section 48). Instead:

- Maintain `shared-spec/scenario.schema.json`, `shared-spec/result.schema.json`, and `shared-spec/test-vectors.json` as the source of truth for "what the simulation must do."
- Implement the simulation twice — once in Dart (`app/lib/simulation/`), once in TypeScript (`website/src/simulation/`) — both validated against the same `test-vectors.json`.
- CI (or, at minimum, a pre-commit checklist) runs both implementations against the shared test vectors and fails if they diverge.

This is safer for a small team building both platforms concurrently, avoids a brittle cross-language build pipeline, and matches the plan's explicit instruction: *"If deterministic reproduction through a shared specification is safer, recommend that instead."*

## Test cases (minimum required — see TEST_PLAN.md for full matrix)

- `targetPitch(0) == 45.0`
- `targetPitch(50) == 57.0`
- `targetPitch(200) == 85.0` (clamp engaged)
- `targetPitch(-10)` — boundary/negative speed handling (UNKNOWN in prototype; must decide: clamp to 0 before formula, or let formula produce <45° and then clamp — recommend clamping speed to `>= 0` before the formula, since GPS speed should never be negative but defensive coding costs nothing)
- `isClearToEject` boundary: `Δθ = 4.9°` → true; `Δθ = 5.1°` → false; `Δθ = 5.0°` → true (inclusive, per the proven `<=`)
- Vehicle modifier identity: `Car` profile must reproduce the base-formula test points exactly (turbulenceFactor=1.0, angleBias=0.0)
- Determinism: same `scenarioSeed` + same inputs → identical `SimulationResult`, run twice

## Reconciliation with the planning package

This file is a faithful record of the simulation contract. It has been light-edited to align with the planning package. Key decisions reflected here:

- **D-4 (Car identity):** the `Car` vehicle profile uses `turbulenceFactor = 1.0` and `angleBias = 0.0`. It reproduces the proven base formula exactly. Asserted by `shared-spec/test-vectors.json` TV-08.
- **D-5 (Wind does not affect the lock):** wind affects `impactPosition`, `deviationM`, and the crosswind scoring only. The lock tolerance (`deltaDeg <= 5.0`) is wind-independent. Asserted by TV-09.
- **D-11 (Determinism):** the simulation is a pure function of `Scenario + NormalizedTelemetry snapshot`. No `DateTime.now()`, no `Random()`, no platform RNG. Same `(seed, telemetry log)` produces the same result, every time, on Android and on the website.
- **D-14 (Negative speed clamp):** `targetPitch(-10) == targetPitch(0) == 45.0`. Clamp `speedKmh` to `>= 0` before the formula. Asserted by TV-07.
- **D-3 (Cross-platform strategy):** shared-spec, not shared-runtime. Two parallel implementations (Dart + TypeScript) and a shared JSON contract (`shared-spec/scenario.schema.json`, `result.schema.json`, `test-vectors.json`).

The full decision log is in `update.ai/DECISIONS.md`. The test plan is in `docs/TEST_PLAN.md`. The cross-platform parity test asserts every vector in `shared-spec/test-vectors.json`.
