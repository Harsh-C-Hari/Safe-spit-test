# TECHNICAL ARCHITECTURE

## Target Architecture

The application MUST strictly separate non-deterministic real-world inputs from the deterministic simulation core.

### Layer 1: Physical Sensors (Hardware Dependent)
- GPS, Accelerometer, Gyroscope, Camera.
- **Output**: Raw, noisy data streams.

### Layer 2: Sensor Abstraction (Core)
- Filters and aggregates raw data.
- Converts Accelerometer `(y, z)` to `pitchDeg` via `atan2(z, y) * 180 / pi + 90`.
- **Output**: `NormalizedTelemetry` stream.

### Layer 3: Deterministic Simulation (Core) [PROVEN]
- Pure Dart functions. No Flutter dependencies.
- Consumes `ScenarioInput` (containing telemetry and vehicle data).
- Emits `SimulationResult` (targetPitch, lock state, etc).
- **Rule**: Same input must always produce the same output.

### Layer 4: State Management (Core)
- Manages the Game Lifecycle (BOOT -> READY -> LIVE).
- Bridges the Simulation with the UI.

### Layer 5: Presentation / HUD (Core)
- Reactive UI consuming State.
- Camera background with AR-style `CustomPaint` overlays.
