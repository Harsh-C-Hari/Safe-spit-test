# SIMULATION SPECIFICATION

## Core Responsibilities
The Simulation Engine is the deterministic heart of the app. It must have ZERO dependencies on Flutter UI or hardware libraries. It takes a `ScenarioInput` and produces a `SimulationResult`.

## Target Pitch Formula [PROVEN]
```dart
// Base target calculation for a car moving forward
final double raw = 90.0 - (speedKmh / 5.0) * 2.0 * turbulenceFactor - bias;
targetPitch = raw.clamp(10.0, 90.0);
```

## Still & Walking Profiles [VALIDATED]
- **Still**: Returns `0.0` (Straight UP).
- **Walking (<= 5km/h)**: Returns `0.0` to absorb GPS noise.
- **Walking (> 5km/h)**: Returns `(0.0 + ((speed - 5.0) * 6.0)).clamp(0.0, 90.0)`.

## Lock Logic [PROVEN]
```dart
bool isLocked = abs(actualPitch - targetPitch) <= lockTolerance;
```
- Standard tolerance = `5.0` degrees.
- Relaxed tolerance (speed < 2km/h or backwards) = `15.0` degrees.

## Known Bugs to Avoid [CRITICAL]
- In the reference build, passenger side pitch was erroneously calculated as `180.0 - baseTargetPitch`. This forces the user to aim at the floor (`180.0`). **DO NOT REPRODUCE THIS BUG.** Left and right windows should use the exact same pitch calculation. The only difference is the physical window the user looks out of.
