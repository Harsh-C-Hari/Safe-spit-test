import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utility to calculate "Fake AR" projection of a 3D impact point onto a 2D screen.
class ArProjection {
  /// Calculates where the spit will land on the screen.
  /// Returns null if the point is behind the camera.
  static Offset? projectImpactPoint({
    required Size screenSize,
    required double speedKmh,
    required double phonePitchDeg,
    required String seatSide,
    required bool isFacingBackwards,
    double? phoneCompassHeading,
    double? carGpsHeading,
    double? anchorCompassHeading,
  }) {
    // 1. Calculate impact point (X, Y, Z) in car-relative coordinates
    // Forward = +Z, Right = +X, Down = +Y
    
    // Spit blows backward proportionally to car speed
    // If facing backwards, wind blows AWAY from user, so it goes +Z (forward relative to car)
    double zBlowback = -(speedKmh / 20.0); 
    if (isFacingBackwards) {
      zBlowback = -zBlowback; // Invert blowback so it goes forward
    }
    
    // Out the window distance (lateral)
    // In India: Driver is Right (+1.5), Passenger is Left (-1.5)
    final double xOut = seatSide == 'driver' ? 1.5 : -1.5;
    
    // Down to the road
    const double yDown = 1.2;

    // 2. Absolute angles of the impact point relative to the car origin
    // targetYaw: 0 is forward, 90 is right, -90 is left.
    // atan2(X, Z) gives angle from Z axis.
    final double targetYawRad = math.atan2(xOut, zBlowback);
    final double targetYawDeg = targetYawRad * 180 / math.pi;
    
    // targetPitch: angle down from the horizon.
    final double horizontalDist = math.sqrt(xOut * xOut + zBlowback * zBlowback);
    final double targetPitchRad = math.atan2(yDown, horizontalDist);
    final double targetPitchDeg = targetPitchRad * 180 / math.pi;

    // 3. Phone's camera orientation
    double phoneYawDeg;
    // 2. Rotate based on looking direction
    // If we have heading data, we can offset the X position based on where the user is looking
    // relative to the car's direction of travel (or anchor heading if stopped)
    final double? referenceHeading = carGpsHeading ?? anchorCompassHeading;
    if (phoneCompassHeading != null && referenceHeading != null) {
      phoneYawDeg = phoneCompassHeading - referenceHeading;
    } else {
      // Fallback if sensors fail completely
      phoneYawDeg = seatSide == 'driver' ? 90.0 : -90.0;
      if (isFacingBackwards) {
        phoneYawDeg = seatSide == 'driver' ? -90.0 : 90.0;
      }
    }
    
    // phonePitchDeg from telemetry: 0 is upright (looking at horizon), 90 is flat (looking at ground)
    final double cameraPitchDeg = phonePitchDeg;

    // 4. Calculate angular difference between camera and target
    // If deltaYaw is positive, target is to the RIGHT of the camera center.
    double deltaYaw = targetYawDeg - phoneYawDeg;
    // Normalize deltaYaw between -180 and 180
    while (deltaYaw > 180) deltaYaw -= 360;
    while (deltaYaw < -180) deltaYaw += 360;

    // If deltaPitch is positive, target is BELOW the camera center.
    final double deltaPitch = targetPitchDeg - cameraPitchDeg;

    // 5. Screen projection
    // If it's more than 90 degrees away, it's behind the camera.
    if (deltaYaw.abs() > 90) return null;

    // Assumed Camera Field of View (FOV)
    const double fovYDeg = 60.0; 
    const double fovXDeg = 45.0; // Typical mobile portrait camera FOV
    
    final double pixelsPerDegX = screenSize.width / fovXDeg;
    final double pixelsPerDegY = screenSize.height / fovYDeg;

    // Camera center
    final double cx = screenSize.width / 2;
    final double cy = screenSize.height / 2;

    final double screenX = cx + (deltaYaw * pixelsPerDegX);
    final double screenY = cy + (deltaPitch * pixelsPerDegY);

    return Offset(screenX, screenY);
  }
}
