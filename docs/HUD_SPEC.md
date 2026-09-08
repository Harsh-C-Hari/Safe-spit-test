# HUD_SPEC.md — SAFE//SPIT

## Verdict on the prototype's `CustomPainter` reticle approach

**Preserve it.** The prototype's `MissileLockReticlePainter` (a `CustomPainter`) is proven, performant (canvas drawing, not widget-tree heavy), and matches exactly the visual grammar described in both plans (center pip, bracket framing, cardinal crosshair, secondary lock ring). There is no architectural reason to replace `CustomPainter` with something else (e.g. a Rive/Lottie animation) for the reference build — it would add a dependency and asset-authoring overhead for no proven benefit. Extend the existing painter with new draw calls (target marker, trajectory line) rather than rewriting it.

## PROVEN elements (confirmed via compiled string/class evidence)

- `MissileLockReticlePainter` with a `paint(canvas, size)` method, `cx`/`cy` center point, configurable `strokeWidth`, `drawCircle` for the center ring, `bracketSize`-driven corner brackets, cardinal crosshair lines, a separate `lockPaint` for the secondary outer ring (rendered conditionally — i.e. only appears on lock, matching the older plan's "rendered upon target acquisition" spec), and a `shouldRepaint(oldDelegate)` override (so it doesn't naively repaint every frame).
- Lock color: `0xFF39FF14` (tactical neon green) — confirmed as a literal constant in the compiled app.
- **Not confirmed:** the "danger/blowback risk" red state color `0xFF073A` described in the older implementation plan was **not found** anywhere in the compiled prototype. Either it was never wired up, or it exists only as a constant that's never reached in the current build. Treat the red/danger state as **PLANNED, not PROVEN** — verify in source before assuming it exists.
- Top diagnostics text confirmed present: pitch tracking readout ("ACTUAL PITCH TRK" style label + target pitch).
- Bottom telemetry confirmed present: `VELOCITY KM/H` readout, `LOCK-ON STATE` with `LOCKED`/`UNLOCKED` text states.
- `PermissionGate` "SYSTEM LOCKED" / "HUD SENSORS UNINITIALIZED." screen — confirmed present, military-styled per spec.
- Green camera tint overlay at 5% opacity — confirmed present.

## HUD layout (target for reference build)

```
┌─────────────────────────────────────────────┐
│ [top diagnostics bar]                        │  version • target pitch • actual pitch
│                                               │
│              [camera passthrough]             │
│         (green-tinted, full bleed)            │
│                                               │
│              [reticle overlay]                │  center pip, corner brackets,
│                                               │  cardinal crosshair, outer lock ring
│                                               │  (PLANNED additions: trajectory arc,
│                                               │   target marker, wind indicator)
│                                               │
│ [bottom telemetry bar]                        │  speed • lock status • (PLANNED: vehicle,
│                                               │  mission info, diagnostics shortcut)
└─────────────────────────────────────────────┘
```

## Elements — status

| Element | Status |
|---|---|
| Camera passthrough | PROVEN |
| Center pip / reticle ring | PROVEN |
| Corner brackets | PROVEN |
| Cardinal crosshair | PROVEN |
| Outer lock ring (on-lock only) | PROVEN |
| Top diagnostics (pitch target/actual) | PROVEN |
| Bottom telemetry (speed, lock status) | PROVEN |
| Green tactical tint | PROVEN |
| Danger/red alert state | PLANNED (not confirmed wired up) |
| Trajectory line/arc rendering | PLANNED |
| Target marker | PLANNED |
| Wind visualization | PLANNED |
| Vehicle indicator | PLANNED |
| Mission/scenario info panel | PLANNED |
| Sensor diagnostics panel | PLANNED |

## Lock transition (state → visual)

```
SEARCHING     → reticle idle color (green outline, no fill), no outer ring
TRAJECTORY    → reticle brackets pulse subtly as Δθ narrows (PLANNED refinement;
  FOUND         prototype currently has no confirmed intermediate visual state
                between "not locked" and "locked" beyond the tolerance boolean)
LOCKING       → PLANNED — brief transitional animation as Δθ crosses into tolerance
SPIT LOCK     → PROVEN pattern to extend: outer ring appears, green intensifies,
                haptic pulse fires once, audio cue fires once (on false→true
                transition only — do not loop, do not refire while held locked)
CLEAR TO      → same visual state as SPIT LOCK; this is presentation language,
  EJECT         not a separate technical state, per the older plan
```

**Critical rule carried over from the prototype's proven design:** the audio/haptic cue fires **once, on the transition**, not continuously while locked. This must be implemented as an edge-triggered check (`wasClear != isClear`), matching the prototype's `_wasClear` boolean pattern — do not implement it as "play sound every frame lock is true," which would create an audio loop bug.

## Colors

| Purpose | Color | Status |
|---|---|---|
| Locked / clear | `#39FF14` (tactical neon green) | PROVEN |
| Danger / blowback risk | `#FF073A` (alert neon red) | PLANNED — spec'd in older plan, not confirmed implemented |
| Camera tint | `#39FF14` @ 5% opacity | PROVEN |

## Typography, animation, performance

- **UNKNOWN / REQUIRES VALIDATION:** exact font family used in the prototype was not confirmed from static analysis beyond the default Flutter font stack (Roboto on Android). No custom font asset was found bundled in the APK beyond `MaterialIcons` and `cupertino_icons`. Recommend picking a monospace/tactical-feeling font (e.g. a bundled `.ttf` such as a condensed monospace) as a PLANNED, low-risk visual upgrade — do not block the reference build on font selection.
- Performance: `CustomPainter.shouldRepaint` is already implemented correctly (avoids full repaint every frame) — preserve this pattern when adding new draw calls (trajectory, target marker, wind arrow). Camera preview + a `CustomPainter` overlay is a well-trodden, performant Flutter pattern; no performance red flags expected on API 24+ hardware from this alone.
- Responsive behavior: **UNKNOWN** — the prototype was built and tested against a single device/screen size (evidence: hardcoded pixel offsets like "70px" corner-bracket sizing described in the older plan, rather than sizes derived from `MediaQuery`). This is a `REQUIRES VALIDATION` item for the reference build: test on at least two different screen sizes/aspect ratios and confirm the reticle sizing scales sensibly, or explicitly convert hardcoded pixel offsets to proportional/`MediaQuery`-derived values.

## Reconciliation with the planning package

This file is a faithful record of the HUD design. It has been light-edited to align with the planning package. Key decisions reflected here:

- **D-13 (Edge-triggered lock state machine):** the audio + haptic cue fires **once on the false→true transition**, not continuously. This is implemented as a `wasClear` boolean in the lock controller. The prototype already uses this pattern; preserve it. See Rule 10 in `update.ai/IMPLEMENTATION_RULES.md`.
- **Danger/red state is PLANNED, not PROVEN.** The `#FF073A` alert red is spec'd in the older plan but was not found anywhere in the compiled prototype. Treat as PLANNED. Do not assume it is wired up.
- **`CustomPainter.shouldRepaint` is the proven pattern.** All new draw calls (trajectory, target marker, wind arrow, vehicle indicator) are added as additional draw calls inside the existing painter, not as a new animation library. See D-10.

The lock state machine is specified in `docs/GAME_SPEC.md` §"The game loop" and `docs/IMPLEMENTATION_ORDER.md` Phase 6.
