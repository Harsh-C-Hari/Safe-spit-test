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
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  double _gravityX = 0.0;
  double _gravityY = 0.0;
  double _gravityZ = 0.0;
  double _pitchDeg = 45.0; // Start at 45 degrees
  double _rollDeg = 0.0;
  
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
    _pitchDeg = 45.0;
    _rollDeg = 0.0;
    _gravityX = 0.0;
    _gravityY = 0.0;
    _gravityZ = 0.0;

    // Use the real accelerometer for interactive pitch
    try {
      _accelSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          const double alpha = 0.1;
          _gravityX = alpha * event.x + (1 - alpha) * _gravityX;
          _gravityY = alpha * event.y + (1 - alpha) * _gravityY;
          _gravityZ = alpha * event.z + (1 - alpha) * _gravityZ;

          _pitchDeg = math.atan2(_gravityZ, _gravityY) * (180.0 / math.pi) + 90.0;
          _pitchDeg = _pitchDeg.clamp(0.0, 180.0);
          
          _rollDeg = math.atan2(_gravityX, _gravityZ) * (180.0 / math.pi);
          _rollDeg = _rollDeg.clamp(-180.0, 180.0);

          _emit();
        },
        onError: (_) {
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
      rollDeg: _rollDeg,    // Real roll
      timestamp: DateTime.now(),
      sensorHealth: const SensorHealth(
        gps: SensorHealthStatus.ok, // Faked
        gyro: SensorHealthStatus.ok, // Real
        accelerometer: SensorHealthStatus.ok, // Real
        magnetometer: SensorHealthStatus.unavailable,
        camera: SensorHealthStatus.permissionDenied,
      ),
      isDemoMode: true,
      isFacingBackwards: _isFacingBackwards,
    );

    _controller?.add(telemetry);
  }

  void _stop() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
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
