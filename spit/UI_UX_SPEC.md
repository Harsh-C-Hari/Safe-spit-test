# UI / UX SPECIFICATION

## Design Language
- **Colors**: Deep black, neon red (lock), neon orange (tracking), tactical green/cyan (ambient text).
- **Typography**: Monospace, technical fonts (e.g., Share Tech Mono or Roboto Mono).
- **Animations**: Glitch effects, scanning lines, pulse on lock.

## Screens

### 1. Permission/Boot Screen
- Tactical text rendering.
- Request Camera, Location, Sensor permissions sequentially.

### 2. Main HUD (Head-Up Display) [REQUIRED]
- **Background**: Live Camera Feed.
- **Overlays**:
  - Top Left: Current Speed (large, monospace), Wind estimation.
  - Top Right: Target Pitch vs Actual Pitch.
  - Center: The Reticle. Consists of a central crosshair and a moving target circle/arrow.
  - Bottom Left: Vehicle profile selector (Car, Walking, Still).
  - Bottom Right: Seat side selector (Left/Right window).

### Reticle Behavior [VALIDATED]
- If target is above current pitch: Draw an upward arrow above the crosshair.
- If target is below current pitch: Draw a downward arrow below the crosshair.
- When locked: Reticle locks onto the center and scales up slightly with a RED glow.
