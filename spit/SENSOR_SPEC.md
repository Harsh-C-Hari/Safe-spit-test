# SENSOR SPECIFICATION

## Accelerometer (Pitch)
- **Source**: `sensors_plus` plugin (`accelerometerEventStream`).
- **Axis Interpretation**:
  - We care about the Y and Z axes.
  - `Pitch = atan2(z, y) * 180 / pi + 90`.
  - Face Down (rear camera to sky) = `0.0`.
  - Upright (rear camera horizontal) = `90.0`.
  - Face Up (rear camera to floor) = `180.0`.
- **Frequency**: Medium/High UI refresh rate (e.g., 30fps).

## GPS (Speed)
- **Source**: `geolocator` plugin.
- **Units**: m/s converted to km/h (`speed * 3.6`).
- **Limitations**: GPS speed is notoriously noisy at walking paces. Implement a small deadband (e.g., < 2.0 km/h = 0) or handle within Simulation.

## Gyroscope
- **Status**: [OPTIONAL] / [CUT FIRST].
- **Usage**: Used to smooth accelerometer noise, but increases complexity heavily. Rely on basic accelerometer filtering (EMA) first.
