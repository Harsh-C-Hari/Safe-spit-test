// scoring.dart — SAFE//SPIT
//
// PLANNED deterministic scoring function (Phase 9).
// RULE 2: No Flutter imports.
// RULE 11: No DateTime.now(), no Random() — same inputs → same score, always.
//
// Formula (GAME_SPEC.md §5):
//   score = baseScoreForLock(lockQuality) - distancePenalty(deviationM) + timingBonus(timeToLockMs)
//
// Constants marked PROPOSED — to be tuned during Phase A playtesting.
// Log final values in update.ai/DECISIONS.md.

import 'scenario.dart';

/// Scoring constants — PROPOSED, subject to playtesting tuning.
class ScoringConstants {
  static const int maxPrecisionScore = 500;
  static const int maxImpactScore = 300;
  static const int maxTimingScore = 200;
  static const int maxStyleScore = 100; // cosmetic only

  /// Maximum wind deviation in metres that gives full impact score.
  static const double perfectDeviationM = 0.1;
  /// Deviation beyond which impact score is zero.
  static const double maxDeviationM = 5.0;

  /// Time to lock beyond which no timing bonus is awarded (ms).
  static const int maxTimingMs = 10000;
  /// Fastest time for maximum timing bonus (ms).
  static const int perfectTimingMs = 1000;
}

/// Compute a deterministic [ScoreBreakdown] from the given result.
///
/// [lockQuality] — 0.0..1.0, how centered within tolerance.
/// [deviationM] — lateral wind deviation at impact.
/// [timeToLockMs] — milliseconds from HudLive to first lock.
/// [mode] — game mode for mode-specific weight adjustments.
ScoreBreakdown computeScore({
  required double lockQuality,
  required double deviationM,
  required int timeToLockMs,
  required String mode,
}) {
  // ── Precision score (lock quality) ───────────────────────────────────────
  final int precision = (lockQuality.clamp(0.0, 1.0) *
          ScoringConstants.maxPrecisionScore)
      .round();

  // ── Impact score (wind deviation — closer to target = higher score) ───────
  final double normalizedDeviation =
      (deviationM.abs() - ScoringConstants.perfectDeviationM)
          .clamp(0.0, ScoringConstants.maxDeviationM) /
          ScoringConstants.maxDeviationM;
  final int impact =
      ((1.0 - normalizedDeviation) * ScoringConstants.maxImpactScore).round();

  // ── Timing bonus (faster lock = higher bonus) ─────────────────────────────
  int timing = 0;
  if (timeToLockMs > 0) {
    final double normalizedTime = ((timeToLockMs - ScoringConstants.perfectTimingMs) /
            (ScoringConstants.maxTimingMs - ScoringConstants.perfectTimingMs))
        .clamp(0.0, 1.0);
    timing = ((1.0 - normalizedTime) * ScoringConstants.maxTimingScore).round();
  }

  // ── Style (cosmetic easter egg points, never affects ranking) ────────────
  final int style = _stylePoints(lockQuality, mode);

  // ── Total ─────────────────────────────────────────────────────────────────
  final int total = precision + impact + timing;

  return ScoreBreakdown(
    total: total,
    precision: precision,
    impact: impact,
    timing: timing,
    stability: 0, // PLANNED: derived from lock-hold duration in Phase 9
    style: style,
  );
}

/// Update lock quality given current delta and previous smooth value.
/// Returns the new smoothed lockQuality (exponential smoothing, alpha=0.15).
double updateLockQuality(double previousQuality, double deltaDeg) {
  const double tolerance = 5.0;
  const double alpha = 0.15;
  final double instantQuality = (1.0 - (deltaDeg / tolerance)).clamp(0.0, 1.0);
  return previousQuality * (1.0 - alpha) + instantQuality * alpha;
}

int _stylePoints(double lockQuality, String mode) {
  // Perfect lock in a challenging mode = style points
  if (lockQuality >= 0.99 && mode != 'precision') return 100;
  if (lockQuality >= 0.95) return 50;
  return 0;
}
