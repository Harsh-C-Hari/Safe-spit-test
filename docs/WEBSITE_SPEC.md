# WEBSITE_SPEC.md — SAFE//SPIT

> **Status:** PLANNED (new). The website is a premium interactive experience with its own working simulator, not a marketing page. It is the only place where a visitor can play without installing the app.
> **Cross-references:** `ARCHITECTURE.md` (website flow), `SIMULATION_SPEC.md` (cross-platform strategy), `MULTIPLAYER_SPEC.md` (Spit Olympics on web), `GAME_SPEC.md` (modes), `shared-spec/`.

## 1. Visual direction

"Tactical aerospace + selective brutalism + premium motion." Not generic SaaS. Reject the standard "Hero / Features / Screenshots / Footer" structure. The website is an experience, not a landing page.

## 2. Page flow

1. **Cinematic intro** — a boot sequence ("SAFE//SPIT SYSTEM ONLINE"), a "common sense offline" Easter egg, and a clear entry into the product.
2. **World page** — the fictional "science" behind SAFE//SPIT, played completely straight.
3. **Interactive HUD** — an in-browser simulator. Mouse/touch/keyboard input. Runs the shared-spec simulation (the same `test-vectors.json` as the app).
4. **Vehicle selector** — the same vehicle profiles as the app. Selecting a vehicle updates the `vehicle` field of the current `ScenarioInput` and re-runs the simulation.
5. **Spit Olympics** — browser-playable, with optional pass-and-play via a shareable seed URL.
6. **Global League** — a leaderboard view, behind Supabase. Degrades to a static "Backend offline" message when Supabase is unreachable.
7. **Android App** — a download CTA. Placeholder URL until Phase B.

## 3. Interaction model

- Cursor becomes a targeting reticle on the HUD page.
- Scroll = virtual vehicle speed.
- Mouse position = device tilt (pitch).
- Keyboard `Space` = launch.
- Touch: drag to tilt, tap a launch button.

## 4. Input normalization

`MouseInputNormalizer`, `TouchInputNormalizer`, `KeyboardInputNormalizer` all produce `NormalizedTelemetry` and feed the same `Simulation` the Android app uses. This is the cross-platform seam (D-3).

## 5. Trajectory visualization

A 2D canvas/SVG render of `trajectory: List<Point>` from the shared-spec result, with a `LockQualityIndicator` color-coded on green/amber/red. The trajectory is in meters (from the simulation), not pixels; the renderer scales to the canvas.

## 6. Vehicle selector

Same JSON list as the app. Selecting a vehicle in the browser simulator updates the `vehicle` field of the current `ScenarioInput` and re-runs the simulation. The Car profile is the identity (D-4).

## 7. Spit Olympics on web

Same scenario-seed logic as the app. A "Share seed" button produces a URL like `/play?seed=8F42A7&vehicle=car`. Another visitor on the same URL plays the identical scenario. No realtime sync (that is Plan A; the web Spit Olympics is pass-and-play via URL sharing, not live multiplayer).

## 8. Leaderboard on web

Pulls from Supabase if available; otherwise shows a static "Backend offline" message. The leaderboard page never blocks the rest of the site.

## 9. Accessibility

- Keyboard parity for every mouse interaction.
- Reduced-motion media query respected (disable the cinematic intro's heavy animation).
- All colors WCAG AA at minimum.
- The reticle and trajectory have text alternatives (the raw numbers are visible in a telemetry panel).

## 10. Performance

- Target 60fps on a 2020-era laptop.
- 30fps minimum on a mid-range Android phone browser.
- Bundle size under 500KB of JS for the simulator page alone (excluding the framework).

## 11. Mobile browser fallback

The website is not a substitute for the Android app. The mobile browser experience is reduced: only the leaderboard and a static Spit Olympics demo. The full simulator requires desktop or a tablet. This is stated explicitly on the mobile page, with a "Get the app" CTA.

## 12. Tech

Next.js (React) or SvelteKit — either is acceptable. The choice is deferred to the implementation phase. The spec must be implementable in either. The shared-spec JSON contract is the same regardless of framework.

## 13. Acceptance

The website renders the cinematic intro, the simulator page responds to mouse input with a visible trajectory, the vehicle selector updates the simulation, and a shareable seed URL works.

## Known / Proven / Planned / Unknown

- PROVEN: nothing; no website exists.
- PLANNED: all of the above.
- PROPOSED: Next.js vs SvelteKit (deferred to implementation).
- UNKNOWN: whether 60fps is achievable on the target laptop class with the chosen framework.