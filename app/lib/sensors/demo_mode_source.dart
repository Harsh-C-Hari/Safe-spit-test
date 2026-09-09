// demo_mode_source.dart — SAFE//SPIT
//
// PLANNED: Demo Mode telemetry source (Phase 2/7).
// RULE 5: Demo Mode must ALWAYS exist. This source is the fallback.
// RULE 8: HUD must visibly show "DEMO MODE" when this source is active.
//
// Demo Mode produces a deterministic sequence that demonstrates the full
// core loop: telemetry → HUD → increasing speed → target pitch rises →
// pitch adjustment → SPIT LOCK → score.
//
// The sequence is designed to run in ~30 seconds and produce a lock.

import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'normalized_telemetry.dart';

/// A hybrid telemetry source for Demo Mode.
/// Speed is locked at a constant 60 km/h, but it uses the REAL gyroscope
/// so the user can interact by physically tilting the device.
class DemoModeSource {
  static const double _peakSpeed = 60.0; // km/h

  StreamController<NormalizedTelemetry>? _controller;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  double _pitchDeg = 45.0; // Start at 45 degrees
  DateTime? _lastGyroTime;
  
  // Simulated forward path is 0° (North)
  static const double _simulatedGpsHeading = 0.0;
  bool _isFacingBackwards = false;

  /// The live telemetry stream. Subscribe to receive updates.
  Stream<NormalizedTelemetry> get stream {
    _controller ??= StreamController<NormalizedTelemetry>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    return _controller!.stream;
  }

  void _start() {
    _lastGyroTime = null;
    _pitchDeg = 45.0;

    // Use the real gyroscope for interactive pitch
    try {
      _gyroSubscription = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          final DateTime now = DateTime.now();
          if (_lastGyroTime != null) {
            final double dt = now.difference(_lastGyroTime!).inMicroseconds / 1e6;
            final double deltaPitch = event.y * (180.0 / math.pi) * dt;
            _pitchDeg = (_pitchDeg + deltaPitch).clamp(0.0, 180.0);
          }
          _lastGyroTime = now;
          _emit();
        },
        onError: (_) {
          // If gyro fails, just emit the constant values
          _emit();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _emit();
    }

    try {
      _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
        if (event.heading != null) {
          double diff = (_simulatedGpsHeading - event.heading!).abs() % 360.0;
          if (diff > 180.0) diff = 360.0 - diff;
          _isFacingBackwards = diff > 90.0;
          _emit();
        }
      });
    } catch (e) {
      // ignore
    }
  }

  void _emit() {
    if (_controller?.isClosed ?? true) return;
    
    final telemetry = NormalizedTelemetry(
      speedKmh: _peakSpeed, // Constant speed
      pitchDeg: _pitchDeg,  // Real pitch
      timestamp: DateTime.now(),
      sensorHealth: const SensorHealth(
        gps: SensorHealthStatus.ok, // Faked
        gyro: SensorHealthStatus.ok, // Real
        accelerometer: SensorHealthStatus.unavailable,
        magnetometer: SensorHealthStatus.unavailable,
        camera: SensorHealthStatus.permissionDenied,
      ),
      isDemoMode: true,
      isFacingBackwards: _isFacingBackwards,
    );

    _controller?.add(telemetry);
  }

  void _stop() {
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  /// Dispose and release resources.
  void dispose() {
    _stop();
    _controller?.close();
    _controller = null;
  }
}
