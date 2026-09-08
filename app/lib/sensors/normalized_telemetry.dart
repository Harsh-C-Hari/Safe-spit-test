// normalized_telemetry.dart — SAFE//SPIT
//
// PLANNED: NormalizedTelemetry and SensorHealth types (Phase 2).
// This is the architectural seam between sensor I/O and everything else.
// RULE 3: All UI code reads ONLY NormalizedTelemetry — never raw sensor events.

/// Health status of a single sensor.
enum SensorHealthStatus {
  ok,
  degraded, // available but not ideal (e.g. no GPS fix indoors)
  unavailable, // hardware or OS says it's not available
  permissionDenied, // user denied the permission
}

/// Per-sensor health snapshot.
class SensorHealth {
  final SensorHealthStatus gps;
  final SensorHealthStatus gyro;
  final SensorHealthStatus accelerometer;
  final SensorHealthStatus magnetometer;
  final SensorHealthStatus camera;

  const SensorHealth({
    this.gps = SensorHealthStatus.permissionDenied,
    this.gyro = SensorHealthStatus.permissionDenied,
    this.accelerometer = SensorHealthStatus.unavailable,
    this.magnetometer = SensorHealthStatus.unavailable,
    this.camera = SensorHealthStatus.permissionDenied,
  });

  const SensorHealth.allDenied()
      : gps = SensorHealthStatus.permissionDenied,
        gyro = SensorHealthStatus.permissionDenied,
        accelerometer = SensorHealthStatus.unavailable,
        magnetometer = SensorHealthStatus.unavailable,
        camera = SensorHealthStatus.permissionDenied;

  const SensorHealth.allOk()
      : gps = SensorHealthStatus.ok,
        gyro = SensorHealthStatus.ok,
        accelerometer = SensorHealthStatus.unavailable,
        magnetometer = SensorHealthStatus.unavailable,
        camera = SensorHealthStatus.ok;

  SensorHealth copyWith({
    SensorHealthStatus? gps,
    SensorHealthStatus? gyro,
    SensorHealthStatus? accelerometer,
    SensorHealthStatus? magnetometer,
    SensorHealthStatus? camera,
  }) {
    return SensorHealth(
      gps: gps ?? this.gps,
      gyro: gyro ?? this.gyro,
      accelerometer: accelerometer ?? this.accelerometer,
      magnetometer: magnetometer ?? this.magnetometer,
      camera: camera ?? this.camera,
    );
  }

  bool get anyDegraded =>
      [gps, gyro, accelerometer, magnetometer, camera]
          .any((s) => s == SensorHealthStatus.degraded);

  bool get anyCritical =>
      [gps, gyro]
          .any((s) =>
              s == SensorHealthStatus.unavailable ||
              s == SensorHealthStatus.permissionDenied);
}

/// The single normalized view of all sensor inputs.
/// This is what HUD, simulation, and game logic consume.
/// Raw sensor packages (geolocator, sensors_plus) must NOT appear outside
/// of lib/sensors/sensor_manager.dart.
class NormalizedTelemetry {
  final double speedKmh; // from GPS
  final double pitchDeg; // integrated gyro, clamped [0°, 180°]
  final double rollDeg; // PLANNED (accelerometer/gyro)
  final double yawDeg; // PLANNED (magnetometer)
  final double headingDeg; // PLANNED (magnetometer)
  final DateTime timestamp;
  final SensorHealth sensorHealth;
  final bool isDemoMode;

  const NormalizedTelemetry({
    required this.speedKmh,
    required this.pitchDeg,
    this.rollDeg = 0.0,
    this.yawDeg = 0.0,
    this.headingDeg = 0.0,
    required this.timestamp,
    required this.sensorHealth,
    this.isDemoMode = false,
  });

  /// Default telemetry when no sensors are available.
  factory NormalizedTelemetry.zero() {
    return NormalizedTelemetry(
      speedKmh: 0.0,
      pitchDeg: 45.0, // Default to optimal angle (per SENSOR_SPEC.md)
      timestamp: DateTime.now(),
      sensorHealth: const SensorHealth.allDenied(),
    );
  }

  NormalizedTelemetry copyWith({
    double? speedKmh,
    double? pitchDeg,
    double? rollDeg,
    double? yawDeg,
    double? headingDeg,
    DateTime? timestamp,
    SensorHealth? sensorHealth,
    bool? isDemoMode,
  }) {
    return NormalizedTelemetry(
      speedKmh: speedKmh ?? this.speedKmh,
      pitchDeg: pitchDeg ?? this.pitchDeg,
      rollDeg: rollDeg ?? this.rollDeg,
      yawDeg: yawDeg ?? this.yawDeg,
      headingDeg: headingDeg ?? this.headingDeg,
      timestamp: timestamp ?? this.timestamp,
      sensorHealth: sensorHealth ?? this.sensorHealth,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }
}
