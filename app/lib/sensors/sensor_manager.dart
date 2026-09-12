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
import 'package:flutter_compass/flutter_compass.dart';

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
  double _rollDeg = 0.0;
  double? _gpsHeading;
  double? _compassHeading;
  double? _anchorCompassHeading;
  bool _isFacingBackwards = false;

  SensorHealthStatus _gpsHealth = SensorHealthStatus.permissionDenied;
  SensorHealthStatus _gyroHealth = SensorHealthStatus.permissionDenied;

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  final StreamController<NormalizedTelemetry> _controller =
      StreamController<NormalizedTelemetry>.broadcast();

  /// The normalized telemetry stream. Subscribe to receive updates.
  Stream<NormalizedTelemetry> get stream => _controller.stream;

  // ── Public lifecycle ──────────────────────────────────────────────────────

  Future<void> start() async {
    await _startGps();
    await _startAccel();
    _startCompass();
  }

  void dispose() {
    _gpsSubscription?.cancel();
    _accelSubscription?.cancel();
    _compassSubscription?.cancel();
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
          if (_speedKmh > 5.0) {
            _gpsHeading = position.heading;
            _anchorCompassHeading = null; // Clear anchor when moving
          } else {
            // If stopped, capture an anchor
            if (_anchorCompassHeading == null && _compassHeading != null) {
              _anchorCompassHeading = _compassHeading;
            }
          }
          _checkFacingBackwards();
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

  // ── SENSOR: Accelerometer orientation pipeline (Drift-free) ───────────────

  double _gravityX = 0.0;
  double _gravityY = 0.0;
  double _gravityZ = 0.0;

  Future<void> _startAccel() async {
    _gyroHealth = SensorHealthStatus.degraded;
    _emit();

    try {
      // Replace gyro with accelerometer for absolute orientation.
      _accelSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          // Low-pass filter to smooth out all jitter (alpha = 0.1 means 90% previous value, 10% new value)
          const double alpha = 0.1;
          _gravityX = alpha * event.x + (1 - alpha) * _gravityX;
          _gravityY = alpha * event.y + (1 - alpha) * _gravityY;
          _gravityZ = alpha * event.z + (1 - alpha) * _gravityZ;

          // Pitch: Flat face up (Z=9.8, Y=0) is 180. Upright portrait (Z=0, Y=9.8) is 90. Flat face down (Z=-9.8, Y=0) is 0.
          _pitchDeg = math.atan2(_gravityZ, _gravityY) * (180.0 / math.pi) + 90.0;
          _pitchDeg = _pitchDeg.clamp(0.0, 180.0);
          
          // Roll: rotation left/right. 0 is perfectly level left-to-right.
          _rollDeg = math.atan2(_gravityX, _gravityZ) * (180.0 / math.pi);
          _rollDeg = _rollDeg.clamp(-180.0, 180.0);

          _gyroHealth = SensorHealthStatus.ok;
          _emit();
        },
        onError: (Object error) {
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

  // ── Auto-detect Facing Backwards ──────────────────────────────────────────

  void _startCompass() {
    try {
      _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
        if (event.heading != null) {
          _compassHeading = event.heading;
          _checkFacingBackwards();
          _emit();
        }
      }, onError: (e) {
        // compass missing/failed
      });
    } catch (e) {
      // ignore
    }
  }

  void _checkFacingBackwards() {
    if (_gpsHeading != null && _compassHeading != null && _speedKmh > 5.0) {
      // only check when moving significantly
      double diff = (_gpsHeading! - _compassHeading!).abs() % 360.0;
      if (diff > 180.0) diff = 360.0 - diff;
      
      // If difference between vehicle direction and phone facing is > 90 deg
      _isFacingBackwards = diff > 90.0;
    }
  }

  // ── Telemetry emission ────────────────────────────────────────────────────

  void _emit() {
    if (_controller.isClosed) return;
    
    _controller.add(NormalizedTelemetry(
      speedKmh: _speedKmh,
      pitchDeg: _pitchDeg,
      rollDeg: _rollDeg,
      yawDeg: _compassHeading ?? 0.0,
      headingDeg: _gpsHeading, // Real GPS heading (null if never moved)
      anchorCompassHeading: _anchorCompassHeading, // Compass heading when stopped
      timestamp: DateTime.now(),
      sensorHealth: SensorHealth(
        gps: _gpsHealth,
        gyro: _gyroHealth,
      ),
      isDemoMode: false,
      isFacingBackwards: _isFacingBackwards,
    ));
  }
}
