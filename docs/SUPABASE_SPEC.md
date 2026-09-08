# SUPABASE_SPEC.md — SAFE//SPIT

> **Status:** PLANNED (new). The backend is optional; the reference build may ship with NoopBackendGateway only. This spec exists so the project could add Supabase without rewriting the app.
> **Cross-references:** `ARCHITECTURE.md` (BackendGateway pattern), `MULTIPLAYER_SPEC.md` (Plan A), `RISK_REGISTER.md` (R-11), `IMPLEMENTATION_ORDER.md` (Phase 12).

## 1. Authentication

- Anonymous first (Supabase anonymous sign-in). Never required to play.
- Optional Google OAuth upgrade for persistent identity. Also never required to play.
- The core game (HUD, lock, launch, score, pass-and-play) works with zero authentication.

## 2. Schema (Postgres)

| Table | Columns | Notes |
|---|---|---|
| `profiles` | `id (uuid, pk)`, `callsign (text, unique)`, `created_at (timestamptz)` | Anonymous IDs map 1:1 to callsigns. |
| `matches` | `id (uuid, pk)`, `scenario_seed (text)`, `created_at (timestamptz)`, `status (text)` | A match is a scenario, not a network session. |
| `match_players` | `match_id (uuid, fk)`, `profile_id (uuid, fk)`, `score (int)`, `vehicle (text)`, `mode (text)`, `created_at (timestamptz)` | One row per player per match. |
| `leaderboard_entries` | SQL view | Aggregates high scores per (mode, vehicle) from `match_players`. |

## 3. Row-Level Security (RLS) policies

- A profile can read all `leaderboard_entries` rows.
- A profile can insert only into its own `match_players` rows (where `profile_id = auth.uid()`).
- A profile cannot mutate `matches` after creation.
- A profile cannot delete any row (scores are immutable once submitted).

## 4. API surface (BackendGateway interface in Dart)

```
abstract interface class BackendGateway {
  Future<Result<ScoreSubmission>> submitScore(ScoreSubmission input);
  Future<Result<Leaderboard>> fetchLeaderboard({required String mode, required String vehicle});
  Future<Result<Match>> createMatch({required String seed});
  Future<Result<Match>> joinMatch({required String matchId});
}
```

Two implementations:
- `NoopBackendGateway` — the default. All calls return `Result.err('backend disabled')`. Never throws. The UI handles the error path explicitly with copy like "Score not saved — backend disabled."
- `SupabaseBackendGateway` — the real implementation. Used only when `supabase_flutter.initialize` succeeds and the `BACKEND_DISABLED` build flag is not set.

Only `submitScore` and `fetchLeaderboard` are used by the reference build. `createMatch` and `joinMatch` are stubs for Plan A (online multiplayer) and are not implemented in the reference build.

## 5. Offline fallback

When the gateway is in Noop mode, all calls are local no-ops with a `Result.err('backend disabled')` return type, never exceptions. The UI handles the error path explicitly with copy like "Score not saved — backend disabled." The user is never blocked by the backend being down.

## 6. What is NOT stored

- GPS coordinates.
- Raw sensor data (NormalizedTelemetry snapshots).
- Video from the camera.
- Anything that would qualify as personal data beyond the anonymous callsign.

## 7. Indexes

- `match_players(profile_id, score DESC)` — for "my scores" queries.
- `matches(created_at DESC)` — for recent matches.
- No more. The dataset is small and the reference build is not optimizing for read-heavy traffic.

## 8. Cost / scale

A free-tier Supabase project is sufficient for the reference build. A paid tier is not required. The reference build may ship with NoopBackendGateway only; Supabase is wired in Phase 12 of `IMPLEMENTATION_ORDER.md` only if time allows.

## 9. Acceptance

The reference build passes the `RISK_REGISTER.md` "Supabase failure" test (R-11) by falling back to NoopBackendGateway and showing the user a clear "not saved online" message.

## Known / Proven / Planned / Unknown

- PROVEN: nothing; Supabase is not in the prototype.
- PLANNED: the schema, the RLS policies, the BackendGateway interface, the Noop default.
- PROPOSED: Plan A (online multiplayer) uses createMatch/joinMatch; the reference build does not implement them.
- UNKNOWN: the exact Supabase project URL and keys (configured at build time, not committed).