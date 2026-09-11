# GAME SPECIFICATION

## Overview
The hackathon demo should feel like a serious tactical aviation/military AR interface used for a ridiculous purpose.

## Flow
1. **App Launch**: Show a fake booting sequence ("INITIALIZING TELEMETRY...").
2. **Ready State**: Show current GPS speed and orientation. Reticle is grey/unlocked.
3. **Tracking State**: As user approaches the correct pitch, reticle turns orange.
4. **Lock State**: When within 5 degrees of target pitch, reticle turns RED, lock sound plays, phone vibrates.
5. **Execution**: The user spits (or taps a mock "EJECT" button for demo purposes). Score is calculated based on `lockQuality`.

## Scoring Formula [PROVEN]
```
Score = Base (100) * lockQuality * difficultyFactor
```
Where `lockQuality = 1.0 - (delta / lockTolerance)` clamped `[0, 1]`.
