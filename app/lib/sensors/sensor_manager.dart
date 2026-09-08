// sensor_manager.dart — SAFE//SPIT
//
// PROVEN pipeline adapted to emit Stream<NormalizedTelemetry> (Phase 2).
// Preserves proven:
//  - GPS speed pipeline (v_ms * 3.6, onError/cancelOnError/onDone)
//  - Gyroscope pitch integration (dt, clamp [0°, 180°])
//  - Camera passthrough pattern
// Adds:
//  - NormalizedTelemetry as the output type
//  - SensorHealth tracking
//  - Explicit Demo Mode bypass
//
// RULE 3: Only this file may import geolocator, sensors_plus, camera.
//         All other app code consumes NormalizedTelemetry only.

import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'normalized_telemetry.dart';

/// The real-sensor implementation of the telemetry pipeline.
///
/// Emits a continuous [Stream<NormalizedTelemetry>] by combining:
/// 1. GPS speed (PROVEN pipeline)
/// 2. Gyroscope pitch integration (PROVEN pipeline)
///
/// Camera is handled separately by [HudScreen] via the camera package
/// (because CameraPreview must live in the widget tree).
class SensorManager {
  // ── Internal state ────────────────────────────────────────────────────────
  double _speedKmh = 0.0;
  double _pitchDeg = 45.0; // SENSOR_SPEC.md: default to 45° (optimal) not 0°
  DateTime? _lastGyroTime;

  SensorHealthStatus _gpsHealth = SensorHealthStatus.permissionDenied;
  SensorHealthStatus _gyroHealth = SensorHealthStatus.permissionDenied;

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  final StreamController<NormalizedTelemetry> _controller =
      StreamController<NormalizedTelemetry>.broadcast();

  /// The normalized telemetry stream. Subscribe to receive updates.
  Stream<NormalizedTelemetry> get stream => _controller.stream;

  // ── Public lifecycle ──────────────────────────────────────────────────────

  /// Start all sensors. Call after permissions are granted.
  Future<void> start() async {
    await _startGps();
    await _startGyro();
  }

  /// Stop all sensors and release resources.
  void dispose() {
    _gpsSubscription?.cancel();
    _gyroSubscription?.cancel();
    _controller.close();
  }

  // ── PROVEN: GPS pipeline ──────────────────────────────────────────────────

  Future<void> _startGps() async {
    _gpsHealth = SensorHealthStatus.degraded; // assume degraded until first fix
    _emit();

    try {
      const LocationSettings settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );

      _gpsSubscription = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
        (Position position) {
          // PROVEN: v_ms * 3.6 → km/h
          _speedKmh = (position.speed * 3.6).clamp(0.0, double.infinity);
          _gpsHealth = SensorHealthStatus.ok;
          _emit();
        },
        onError: (Object error) {
          // PROVEN: explicit onError handler — GPS failure does not crash
          _gpsHealth = SensorHealthStatus.degraded;
          _emit();
        },
        cancelOnError: false, // PROVEN: stream continues after errors
        onDone: () {
          _gpsHealth = SensorHealthStatus.unavailable;
          _emit();
        },
      );
    } catch (e) {
      _gpsHealth = SensorHealthStatus.unavailable;
      _emit();
    }
  }

  // ── PROVEN: Gyroscope pitch integration pipeline ──────────────────────────

  Future<void> _startGyro() async {
    _gyroHealth = SensorHealthStatus.degraded;
    _emit();

    try {
      _gyroSubscription = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          final DateTime now = DateTime.now();
          if (_lastGyroTime != null) {
            // PROVEN: dt from Duration.inMicroseconds
            final double dt =
                now.difference(_lastGyroTime!).inMicroseconds / 1e6;
            // PROVEN: integrate Y-axis angular velocity (pitch)
            final double deltaPitch =
                event.y * (180.0 / math.pi) * dt;
            _pitchDeg = (_pitchDeg + deltaPitch).clamp(0.0, 180.0);
          }
          _lastGyroTime = now;
          _gyroHealth = SensorHealthStatus.ok;
          _emit();
        },
        onError: (Object error) {
          // PROVEN: explicit onError — gyro failure does not crash
          _gyroHealth = SensorHealthStatus.degraded;
          _emit();
        },
        cancelOnError: false, // PROVEN
        onDone: () {
          _gyroHealth = SensorHealthStatus.unavailable;
          _emit();
        },
      );
    } catch (e) {
      _gyroHealth = SensorHealthStatus.unavailable;
      _emit();
    }
  }

  // ── Telemetry emission ────────────────────────────────────────────────────

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(NormalizedTelemetry(
      speedKmh: _speedKmh,
      pitchDeg: _pitchDeg,
      timestamp: DateTime.now(),
      sensorHealth: SensorHealth(
        gps: _gpsHealth,
        gyro: _gyroHealth,
      ),
      isDemoMode: false,
    ));
  }
}
