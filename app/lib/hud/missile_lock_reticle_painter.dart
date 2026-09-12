// missile_lock_reticle_painter.dart — SAFE//SPIT
//
// PROVEN: MissileLockReticlePainter preserved from the prototype.
// Extended with PLANNED elements: trajectory line, target marker, wind indicator.
//
// RULE 1: No changes to the proven visual constants without DECISIONS.md entry.
// D-10: All new draw calls are added inside this CustomPainter, not a new library.
// HUD_SPEC.md: Lock color #39FF14 is PROVEN. Red danger state is PLANNED.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../game/spit_lock_controller.dart';
import '../simulation/scenario.dart';
import '../simulation/trajectory_model.dart';

// ── PROVEN color constants ────────────────────────────────────────────────────
/// Tactical neon green — PROVEN from prototype (#39FF14).
const Color kTacticalGreen = AppColors.acidGreen;
/// Alert neon red — PLANNED (spec'd but not confirmed in prototype).
const Color kDangerRed = AppColors.orange;
/// Camera tint — PROVEN (5% opacity green).
const Color kCameraTint = AppColors.acidGreen;

/// The primary HUD reticle painter.
///
/// Consumes only [SimulationResult] and lock state — never raw sensor data.
/// All draw calls are inside [paint] (no additional widget tree overhead).
class MissileLockReticlePainter extends CustomPainter {
  final double targetPitchDeg;
  final double actualPitchDeg;
  final double speedKmh;
  final SpitLockState lockState;
  final double lockQuality; // 0.0..1.0
  final double deltaDeg;
  final double rollDeg;
  final bool isDemoMode;

  // PLANNED fields
  final List<TrajectoryPoint>? trajectoryPoints;
  final double? deviationM;

  // Animation value for pulsing effects (0.0..1.0)
  final double animValue;

  const MissileLockReticlePainter({
    required this.targetPitchDeg,
    required this.actualPitchDeg,
    required this.speedKmh,
    required this.lockState,
    required this.lockQuality,
    required this.deltaDeg,
    this.rollDeg = 0.0,
    required this.isDemoMode,
    this.trajectoryPoints,
    this.deviationM,
    this.animValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // ── Colors based on lock state ──────────────────────────────────────────
    final Color primaryColor = lockState == SpitLockState.locked ? kTacticalGreen : kTacticalGreen.withValues(alpha: 0.7);
    final Color lockColor = lockState == SpitLockState.locked ? kTacticalGreen : kTacticalGreen.withValues(alpha: 0.3);

    // Base paint
    final Paint basePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Paint lockPaint = Paint()
      ..color = lockColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lockState == SpitLockState.locked ? 2.5 : 1.5;

    // ── PROVEN: Center ring ────────────────────────────────────────────────
    final double centerRingRadius = size.width * 0.06;
    canvas.drawCircle(Offset(cx, cy), centerRingRadius, basePaint);

    // ── PROVEN: Center pip ─────────────────────────────────────────────────────
    final Paint pipPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    // Pip radius: proportional to screen width (was hardcoded 3.0)
    canvas.drawCircle(Offset(cx, cy), size.width * 0.008, pipPaint);

    // ── AIM GUIDE ARROW (hidden when locked) ────────────────────────────────
    if (lockState != SpitLockState.locked) {
      _drawAimArrow(canvas, size, cx, cy, deltaDeg, speedKmh, actualPitchDeg, targetPitchDeg, rollDeg);
    }

    // ── PROVEN: Corner brackets ────────────────────────────────────────────
    final double bracketSize = size.width * 0.08;
    final double margin = size.width * 0.12;
    _drawCornerBrackets(canvas, size, margin, bracketSize, basePaint);

    // ── PROVEN: Cardinal crosshair ─────────────────────────────────────────
    _drawCrosshair(canvas, size, cx, cy, basePaint);

    // ── PROVEN: Outer lock ring (only on SPIT LOCK) ────────────────────────
    if (lockState == SpitLockState.locked || lockState == SpitLockState.locking) {
      final double lockRingRadius = size.width * 0.18;
      final double pulseOffset = lockState == SpitLockState.locked
          ? math.sin(animValue * math.pi * 2) * 2.0
          : 0.0;
      canvas.drawCircle(
        Offset(cx, cy),
        lockRingRadius + pulseOffset,
        lockPaint,
      );

      if (lockState == SpitLockState.locked) {
        // Inner fill at low opacity for the locked "glow" effect
        final Paint glowPaint = Paint()
          ..color = kTacticalGreen.withValues(alpha: 0.06)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), lockRingRadius + pulseOffset, glowPaint);
      }
    }

    // ── PLANNED: Trajectory arc ────────────────────────────────────────────
    if (trajectoryPoints != null && trajectoryPoints!.length > 1) {
      _drawTrajectoryArc(canvas, size, cx, cy, trajectoryPoints!);
    }

    // ── PLANNED: Wind deviation indicator ─────────────────────────────────
    if (deviationM != null && deviationM!.abs() > 0.05) {
      _drawWindIndicator(canvas, size, cx, cy, deviationM!);
    }

    // ── PLANNED: Lock quality arc ──────────────────────────────────────────
    if (lockState != SpitLockState.searching) {
      _drawLockQualityArc(canvas, cx, cy, lockQuality);
    }

    // ── DEMO MODE indicator ────────────────────────────────────────────────
    // (RULE 8: always visible when Demo Mode is active)
    // Rendered by the HudScreen widget, not here, for clean separation.
    // But we draw a subtle corner "DEMO" mark for belt-and-suspenders.
    if (isDemoMode) {
      _drawDemoMark(canvas, size);
    }
  }

  // ── PROVEN: Corner brackets ───────────────────────────────────────────────

  void _drawCornerBrackets(
      Canvas canvas, Size size, double margin, double bracketSize, Paint paint) {
    final double right = size.width - margin;
    final double bottom = size.height - margin;

    // Top-left
    canvas.drawLine(Offset(margin, margin + bracketSize), Offset(margin, margin), paint);
    canvas.drawLine(Offset(margin, margin), Offset(margin + bracketSize, margin), paint);

    // Top-right
    canvas.drawLine(Offset(right, margin + bracketSize), Offset(right, margin), paint);
    canvas.drawLine(Offset(right, margin), Offset(right - bracketSize, margin), paint);

    // Bottom-left
    canvas.drawLine(Offset(margin, bottom - bracketSize), Offset(margin, bottom), paint);
    canvas.drawLine(Offset(margin, bottom), Offset(margin + bracketSize, bottom), paint);

    // Bottom-right
    canvas.drawLine(Offset(right, bottom - bracketSize), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right - bracketSize, bottom), paint);
  }

  // ── PROVEN: Cardinal crosshair ────────────────────────────────────────────

  void _drawCrosshair(Canvas canvas, Size size, double cx, double cy, Paint paint) {
    final double gapRadius = size.width * 0.07;
    final double lineLength = size.width * 0.06;

    // Horizontal lines (left and right of gap)
    canvas.drawLine(Offset(cx - gapRadius - lineLength, cy), Offset(cx - gapRadius, cy), paint);
    canvas.drawLine(Offset(cx + gapRadius, cy), Offset(cx + gapRadius + lineLength, cy), paint);

    // Vertical lines (above and below gap)
    canvas.drawLine(Offset(cx, cy - gapRadius - lineLength), Offset(cx, cy - gapRadius), paint);
    canvas.drawLine(Offset(cx, cy + gapRadius), Offset(cx, cy + gapRadius + lineLength), paint);
  }

  // ── PLANNED: Trajectory arc ───────────────────────────────────────────────

  void _drawTrajectoryArc(Canvas canvas, Size size, double cx, double cy,
      List<TrajectoryPoint> points) {
    final Paint trajectoryPaint = Paint()
      ..color = kTacticalGreen.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Scale the trajectory to fit the HUD — fictional display scaling
    final double scaleX = size.width * 0.003;
    final double scaleY = size.height * 0.015;

    final Path path = Path();
    bool started = false;
    for (final pt in points) {
      if (pt.y < 0) continue; // below ground — stop drawing
      final double px = cx + pt.x * scaleX;
      final double py = cy - pt.y * scaleY; // y+ is up in physics, down in screen
      if (!started) {
        path.moveTo(px, py);
        started = true;
      } else {
        path.lineTo(px, py);
      }
    }
    if (started) canvas.drawPath(path, trajectoryPaint);
  }

  // ── PLANNED: Wind indicator ───────────────────────────────────────────────

  void _drawWindIndicator(
      Canvas canvas, Size size, double cx, double cy, double deviationM) {
    final Paint arrowPaint = Paint()
      ..color = kTacticalGreen.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Simple horizontal arrow showing wind deviation direction
    final double arrowLength = (deviationM.abs() * 5.0).clamp(5.0, 30.0);
    final double arrowY = cy + size.height * 0.15;
    final double arrowDx = deviationM > 0 ? arrowLength : -arrowLength;

    canvas.drawLine(Offset(cx, arrowY), Offset(cx + arrowDx, arrowY), arrowPaint);
    // Arrowhead
    canvas.drawLine(
        Offset(cx + arrowDx, arrowY),
        Offset(cx + arrowDx - 5 * deviationM.sign, arrowY - 5),
        arrowPaint);
    canvas.drawLine(
        Offset(cx + arrowDx, arrowY),
        Offset(cx + arrowDx - 5 * deviationM.sign, arrowY + 5),
        arrowPaint);
  }

  // ── PLANNED: Lock quality arc ─────────────────────────────────────────────

  void _drawLockQualityArc(Canvas canvas, double cx, double cy, double quality) {
    final Paint arcPaint = Paint()
      ..color = kTacticalGreen.withValues(alpha: (0.4 + quality * 0.4).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // FIXED: was hardcoded 60.0 — now proportional to canvas (passed via cx/cy,
    // but we need size here; use cx * 0.35 as proxy since cx = size.width / 2)
    final double radius = cx * 0.35; // ~35% of half-width ≈ 17.5% of full width
    const double startAngle = -math.pi / 2; // top
    final double sweepAngle = quality * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  // ── Demo mode mark ────────────────────────────────────────────────────────

  void _drawDemoMark(Canvas canvas, Size size) {
    final Paint demoPaint = Paint()
      ..color = kTacticalGreen.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // FIXED: was hardcoded offsets (size.width - 52, size.height - 20, 46, 14)
    // Now proportional to canvas size
    final double rectW = size.width * 0.12;
    final double rectH = size.height * 0.025;
    final Rect demoRect = Rect.fromLTWH(
        size.width - rectW - size.width * 0.03,
        size.height - rectH - size.height * 0.02,
        rectW,
        rectH);
    canvas.drawRect(demoRect, demoPaint);
  }

    void _drawAimArrow(Canvas canvas, Size size, double cx, double cy,
      double deltaDeg, double speedKmh, double actualPitch, double targetPitch, double rollDeg) {
    final Paint arrowPaint = Paint()
      ..color = kTacticalGreen.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Positive pitchDiff means target is above actual (need to tilt UP)
    // Negative pitchDiff means target is below actual (need to tilt DOWN)
    final double pitchDiff = targetPitch - actualPitch;
    // targetPitch < actualPitch means target is ABOVE the current aim.
    // The arrow should point UP to tell the user to tilt UP.
    final bool pointUp = targetPitch < actualPitch;

    // Calculate vertical offset based on error magnitude
    // Keep a minimum gap from center so it doesn't overlap the reticle
    // FIXED: was hardcoded 55px gap and 80px max — now proportional to screen
    final double minGap = size.height * 0.12;    // minimum clearance from center
    final double maxOffset = size.height * 0.18; // maximum arrow travel
    double offsetMagnitude = (pitchDiff.abs() / 2.0).clamp(0.0, maxOffset);
    // Add speed factor to make it more sensitive at higher speeds (if speed > 0)
    if (speedKmh > 5.0) {
      offsetMagnitude *= (speedKmh / 30.0).clamp(0.5, 2.0);
    }
    offsetMagnitude = offsetMagnitude.clamp(0.0, maxOffset);

    // Position vertically
    double arrowX = cx;
    final double arrowY = pointUp
        ? cy - minGap - offsetMagnitude
        : cy + minGap + offsetMagnitude;

    // If target is vertical (<45 or >135), we also need strict roll guidance (roll must be <= 15).
    // Show horizontal deviation if roll is off.
    if (targetPitch < 45.0 || targetPitch > 135.0) {
      double r = rollDeg % 360.0;
      if (r > 180) r -= 360.0;

      // If facing down (target near 0), "flat" means roll is ~180 or ~-180.
      if (targetPitch < 45.0) {
        if (r > 0) {
          r -= 180.0;
        } else {
          r += 180.0;
        }
      }

      // If r is positive, phone is tilted right. Target is left.
      // So move arrow left.
      final double maxLateral = size.width * 0.22;
      arrowX -= (r * 2.0).clamp(-maxLateral, maxLateral);
    }

    // Arrow geometry — FIXED: was hardcoded ±10px width, ±18px height
    // Now proportional to screen
    final double arrowHalfW = size.width * 0.025;  // ~2.5% of width
    final double arrowHeight = size.height * 0.035; // ~3.5% of height
    final double dotRadius = size.width * 0.009;    // tip dot

    final Path path = Path();
    if (pointUp) {
      // Triangle pointing UP
      path
        ..moveTo(arrowX, arrowY) // tip
        ..lineTo(arrowX - arrowHalfW, arrowY + arrowHeight)
        ..lineTo(arrowX + arrowHalfW, arrowY + arrowHeight)
        ..close();
    } else {
      // Triangle pointing DOWN
      path
        ..moveTo(arrowX, arrowY) // tip
        ..lineTo(arrowX - arrowHalfW, arrowY - arrowHeight)
        ..lineTo(arrowX + arrowHalfW, arrowY - arrowHeight)
        ..close();
    }

    canvas.drawPath(path, arrowPaint);
    // Small direction dot at tip for visibility
    canvas.drawCircle(Offset(arrowX, arrowY), dotRadius, arrowPaint);
  }

  @override
  bool shouldRepaint(MissileLockReticlePainter oldDelegate) {
    // PROVEN pattern: only repaint when meaningful state changes
    return oldDelegate.targetPitchDeg != targetPitchDeg ||
        oldDelegate.actualPitchDeg != actualPitchDeg ||
        oldDelegate.speedKmh != speedKmh ||
        oldDelegate.lockState != lockState ||
        oldDelegate.lockQuality != lockQuality ||
        oldDelegate.rollDeg != rollDeg ||
        oldDelegate.animValue != animValue ||
        oldDelegate.isDemoMode != isDemoMode;
  }
}
