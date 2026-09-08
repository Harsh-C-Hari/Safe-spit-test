# MULTIPLAYER_SPEC.md — SAFE//SPIT

> **Status:** PLANNED (new). Plan B (pass-and-play) is the default and fully specified. Plan A (online) is specified only enough to know what would be needed; it is explicitly optional and after Plan B.
> **Cross-references:** `GAME_SPEC.md`, `SUPABASE_SPEC.md`, `RISK_REGISTER.md` (R-12), `IMPLEMENTATION_ORDER.md` (Phase 10, Phase 12).

## 1. Player identity

- Anonymous callsign, generated locally, no login required to play.
- Format: `SPIT-XXXXX` where X is derived from a hash of (device_id, timestamp) (D-20). Deterministic per install; regenerated only on app reinstall.
- The callsign is shown on the result screen and the pass-and-play comparison screen. Never sent to a server in Plan B.
- Plan A may upgrade the callsign to a Supabase anonymous profile; see `SUPABASE_SPEC.md`.

## 2. Plan B — pass-and-play (the default, fully specified)

### 2.1 Flow

Player 1: "Start Spit Olympics" → "Pass-and-Play" → choose vehicle → choose mode → Generate seed (cryptographic random hex, 6 chars) → Show scenario summary to Player 1 (seed, vehicle, mode, target distance) → Player 1 attempt (HudLive → Locking → Locked → Launched → Scored) → "Pass the device" screen (large visual cue, no copy implying networking) → Player 2 attempt (same seed, same vehicle, same mode, same conditions) → Result reveal: both scores, side-by-side, winner named → Optional: "Play again" (same or new seed) or "Exit".

Player 1's score is recorded locally but NOT shown to Player 2 until the result reveal.

### 2.2 Identical-conditions guarantee

- Same Scenario (seed + vehicle + mode) for both players.
- Same Simulation code path; no "multiplayer branch."
- The only difference is the NormalizedTelemetry each player produces by moving the phone.
- No DateTime.now(), no Random(), no platform RNG in the scoring path (D-11).

### 2.3 Anti-cheat (Plan B)

The only cheating surface is Player 2 peeking at Player 1's result. Mitigation: a "result reveal" screen that hides Player 1's score until Player 2 finishes. No other anti-cheat is needed; the simulation is local.

### 2.4 Result submission (Plan B)

- Results stored in-memory for the duration of the match.
- Optional local persistence in shared_preferences (last N matches). Nice-to-have, not required.
- No network call during a Plan B match. If BackendGateway is in Noop mode (the default), the result screen shows "Score not saved online."

### 2.5 Failure modes (Plan B)

| Failure | Recovery |
|---|---|
| Sensor loss mid-attempt | The attempt is abandoned; the player can retry the same seed or skip. The other player's attempt is unaffected. |
| Player declines to play | "Skip" button; the match continues with present players. A 1-player match is valid. |
| App crash mid-match | The match is lost. Plan B does not persist match state across app restarts in the reference build. |
| Device rotation mid-attempt | The HUD must handle rotation; the match is not abandoned. |

### 2.6 Acceptance

Plan B is "done" when: (1) two players can play on a single device with identical conditions, (2) both get a SimulationResult with a score, (3) a winner is named, (4) zero network calls were made (verifiable in airplane mode).

## 3. Plan A — online (specification only, not required to implement)

Plan A is additive on top of Plan B. It cannot ship if Plan B does not work. It is cut-order #5 in the master plan's cut list.

### 3.1 What Plan A adds

- Supabase Realtime presence for a shared "room" between 2-4 devices.
- Room codes (4-character alphanumeric, generated locally, shared out-of-band).
- Server-signed seeds: the server generates and signs the scenario seed so a player cannot choose a favorable seed.
- MatchService on top of BackendGateway (see ARCHITECTURE.md "Multiplayer flow").
- Leaderboard write-through: the match result is submitted to the Supabase leaderboard after the match.

### 3.2 What Plan A does not add

- No new simulation code. The Simulation is the same pure function.
- No new scoring code. The scoring is the same pure function.
- No new HUD code. The HUD is the same; it reads from a MatchState instead of a local GameState.

### 3.3 Degradation

If Supabase is unreachable, MatchService falls back to Plan B with a visible "Backend offline — playing pass-and-play" banner. The user is never blocked by Supabase being down (D-9, R-11).

## 4. Offline behavior

Plan B is total offline. No network call at any point. Verified by the "airplane mode" robustness condition in DEMO_PLAN.md.

## 5. Synchronization

In Plan B, the only "sync" is the scenario seed, generated once and shown to both players. No real-time sync, no shared state, no conflict resolution.

In Plan A, MatchService uses Supabase Realtime for presence and state sync. PLANNED, not specified in detail here; see SUPABASE_SPEC.md for the backend interface.

## Known / Proven / Planned / Unknown

- PROVEN: nothing in multiplayer is proven; the prototype has no multiplayer.
- PLANNED: Plan B (pass-and-play) is fully specified above and is the reference build's target.
- PROPOSED: Plan A (online) is specified only enough to know the surface area.
- UNKNOWN: whether 4-player pass-and-play feels good on a single device; whether the "Pass the device" screen's copy is clear enough.