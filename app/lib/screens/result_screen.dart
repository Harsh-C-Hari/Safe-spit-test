// result_screen.dart — SAFE//SPIT
//
// UI RESKIN: Matches website design language.
// Background: Black (tactical debrief context) with website accent colors.
// Accent: #C7FF3D acid-green (website) replaces the ad-hoc #39FF14 neon for body text.
// Grade letter glow: keeps #39FF14 neon for S/A only (HUD heritage), warm colors for others.
// Typography: SpaceMono for all tactical text, responsive font sizes.
// Layout: Responsive padding; tablet max-width centering.
//
// RULE 2: No raw sensor imports.
// RULE 5: Demo Mode is clearly labeled.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

import '../game/game_state.dart';
import '../challenge/challenge_state.dart';
import '../services/score_persistence_service.dart';
import '../simulation/scenario.dart';
import '../theme/app_theme.dart';

// ── Grade logic (unchanged) ────────────────────────────────────────────────
String _letterGrade(int total) {
  if (total >= 950) return 'S';
  if (total >= 850) return 'A';
  if (total >= 700) return 'B';
  if (total >= 550) return 'C';
  if (total >= 400) return 'D';
  return 'F';
}

Color _gradeColor(String grade) {
  switch (grade) {
    case 'S':
      return const Color(0xFFB8860B); // Dark gold — readable on light bg
    case 'A':
      return AppColors.black; // Black on light bg
    case 'B':
      return const Color(0xFF006699); // Dark cyan
    case 'C':
      return AppColors.orange; // Website orange (already dark enough)
    case 'D':
      return const Color(0xFFCC4400); // Dark orange
    default:
      return const Color(0xFFCC0000); // Dark red
  }
}

String _gradeLabel(String grade) {
  switch (grade) {
    case 'S':
      return 'LEGENDARY TRAJECTORY';
    case 'A':
      return 'EXCELLENT EXECUTION';
    case 'B':
      return 'SOLID DEPLOYMENT';
    case 'C':
      return 'MARGINAL CLEARANCE';
    case 'D':
      return 'COMPROMISED PROTOCOL';
    default:
      return 'MISSION FAILURE';
  }
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  VideoPlayerController? _videoController;
  bool _showingVideo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = Provider.of<GameState>(context, listen: false);
      final score = gameState.finalScore;
      if (score != null) {
        if (score.total >= 700) {
          _initVideo('assets/video/perfect_ok.mp4');
        } else {
          _initVideo('assets/video/perfect_spit.mp4');
        }
      }
    });
  }

  void _initVideo(String assetPath) {
    setState(() {
      _showingVideo = true;
    });
    _videoController = VideoPlayerController.asset(assetPath)
      ..initialize().then((_) {
        setState(() {}); // Ensure the first frame is shown
        _videoController!.play();
      });

    _videoController!.addListener(() {
      if (_videoController!.value.isInitialized &&
          !_videoController!.value.isPlaying &&
          (_videoController!.value.position >= _videoController!.value.duration ||
           _videoController!.value.position == Duration.zero && _videoController!.value.duration != Duration.zero)) {
           // position == zero check is sometimes needed on some platforms if it wraps around or stops.
           // actually better:
      }
      if (_videoController!.value.isInitialized &&
          _videoController!.value.position >= _videoController!.value.duration) {
        _skipVideo();
      }
    });
  }

  void _skipVideo() {
    if (!mounted) return;
    if (_showingVideo) {
      setState(() {
        _showingVideo = false;
      });
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingVideo) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_videoController != null && _videoController!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: _skipVideo,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final score = gameState.finalScore;
        if (score == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.black),
            ),
          );
        }

        final grade = _letterGrade(score.total);
        final gradeColor = _gradeColor(grade);
        final isDemoMode = gameState.isDemoMode;
        final hPad = responsivePaddingH(context);
        final tab = isTablet(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
                SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: tab ? 640 : double.infinity),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPad,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context, isDemoMode),
                            const SizedBox(height: AppSpacing.lg),
                            if (gameState.challengeResult != null)
                              _buildChallengeResult(context, gameState),
                            if (gameState.challengeResult != null)
                              const SizedBox(height: AppSpacing.lg),
                            _buildGradeBadge(context, grade, gradeColor, score.total),
                            const SizedBox(height: AppSpacing.xl),
                            _buildBreakdown(context, score),
                            const SizedBox(height: AppSpacing.lg),
                            _buildMeta(context, gameState),
                            const SizedBox(height: AppSpacing.xl),
                            _buildActions(context, gameState),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDemoMode) {
    final sz = responsiveFontSize(context, base: 9, scale: 0.024, max: 12);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _mono(context, 'SAFE//SPIT', size: sz, alpha: 0.5),
        if (isDemoMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.acidGreen.withValues(alpha: 0.5)),
            ),
            child: _mono(context, 'DEMO MODE', size: sz * 0.9),
          ),
        _mono(context, 'MISSION REPORT', size: sz, alpha: 0.5),
      ],
    );
  }

  // ── Grade badge ─────────────────────────────────────────────────────────────

  Widget _buildGradeBadge(BuildContext context, String grade, Color gradeColor, int total) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tab = isTablet(context);
    // Grade letter: responsive — ~23% of screen width, clamped 72..120
    final gradeSize = (screenWidth * (tab ? 0.15 : 0.23)).clamp(72.0, 120.0);
    final bracketSize = gradeSize * 0.3;
    final ptsSize = responsiveFontSize(context, base: 22, scale: 0.055, max: 36);
    final labelSz = responsiveFontSize(context, base: 9, scale: 0.024, max: 12);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _mono(context, '[ ', size: bracketSize, alpha: 0.35),
            Text(
              grade,
              style: TextStyle(
                color: gradeColor,
                fontFamily: 'SpaceMono',
                fontSize: gradeSize,
                fontWeight: FontWeight.bold,
                letterSpacing: -4,
                shadows: [
                  Shadow(
                    color: gradeColor.withValues(alpha: 0.5),
                    blurRadius: 24,
                  )
                ],
              ),
            ),
            _mono(context, ' ]', size: bracketSize, alpha: 0.35),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$total pts',
          style: TextStyle(
            color: AppColors.black,
            fontFamily: 'SpaceMono',
            fontSize: ptsSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        _mono(context, _gradeLabel(grade), size: labelSz, alpha: 0.6),
      ],
    );
  }

  // ── Challenge result ────────────────────────────────────────────────────────

  Widget _buildChallengeResult(BuildContext context, GameState gameState) {
    final result = gameState.challengeResult!;
    final eventText = switch (result.eventState) {
      EventDetectionState.eventDetected => 'EVENT DETECTED',
      EventDetectionState.lowConfidence => 'LOW CONFIDENCE',
      EventDetectionState.noEvent => 'NO EVENT DETECTED',
    };
    final snapshotPath = result.snapshotPath;
    final challengeScoreSize = responsiveFontSize(context, base: 24, scale: 0.06, max: 36);
    final labelSz = responsiveFontSize(context, base: 10, scale: 0.026, max: 13);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.acidGreen.withValues(alpha: 0.35)),
        color: Colors.black.withValues(alpha: 0.35),
      ),
      child: Column(
        children: [
          _mono(context, 'CHALLENGE COMPLETE', size: labelSz),
          const SizedBox(height: 12),
          Text(
            '${result.score.toStringAsFixed(2)} / 1.00',
            style: TextStyle(
              color: AppColors.black,
              fontFamily: 'SpaceMono',
              fontSize: challengeScoreSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          _mono(context, eventText, size: labelSz),
          const SizedBox(height: 4),
          _mono(
            context,
            'CONFIDENCE: ${(result.confidence * 100).round()}%',
            size: labelSz * 0.9,
            alpha: 0.65,
          ),
          if (gameState.scoreSyncState != null) ...[
            const SizedBox(height: 6),
            _mono(
              context,
              _syncLabel(gameState.scoreSyncState!),
              size: labelSz * 0.85,
              alpha: 0.6,
            ),
          ],
          if (snapshotPath != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _btn(context, 'VIEW SNAPSHOT',
                  filled: false,
                  onTap: () => _showSnapshot(context, snapshotPath)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _btn(context, 'DELETE SNAPSHOT',
                  filled: false,
                  onTap: () =>
                      _deleteSnapshot(context, gameState, snapshotPath)),
            ),
          ],
        ],
      ),
    );
  }

  String _syncLabel(ScoreSyncState state) {
    switch (state) {
      case ScoreSyncState.synced:
        return 'SCORE SYNCED';
      case ScoreSyncState.pending:
        return 'SCORE SAVED - SYNCING LATER';
      case ScoreSyncState.savedLocally:
        return 'SCORE SAVED LOCALLY';
    }
  }

  void _showSnapshot(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Image.file(File(path), fit: BoxFit.contain),
      ),
    );
  }

  Future<void> _deleteSnapshot(
      BuildContext context, GameState gameState, String path) async {
    try {
      await File(path).delete();
      gameState.clearChallengeSnapshot();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SNAPSHOT DELETED',
              style: AppTextStyles.technicalLabel.copyWith(
                color: AppColors.background,
              ),
            ),
            backgroundColor: AppColors.black,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'COULD NOT DELETE SNAPSHOT',
              style: AppTextStyles.technicalLabel.copyWith(
                color: AppColors.orange,
              ),
            ),
            backgroundColor: AppColors.black,
          ),
        );
      }
    }
  }

  // ── Score breakdown ─────────────────────────────────────────────────────────

  Widget _buildBreakdown(BuildContext context, ScoreBreakdown score) {
    final headerSz = responsiveFontSize(context, base: 9, scale: 0.024, max: 12);
    final totalSz = responsiveFontSize(context, base: 18, scale: 0.045, max: 26);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.acidGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: AppColors.acidGreen.withValues(alpha: 0.08),
            child: Center(
              child: _mono(context, 'SCORE BREAKDOWN', size: headerSz, alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          _scoreRow(context, 'PRECISION', score.precision, 500, 'LOCK QUALITY'),
          _divider(),
          _scoreRow(context, 'IMPACT', score.impact, 300, 'TRAJECTORY DEVIATION'),
          _divider(),
          _scoreRow(context, 'TIMING', score.timing, 200, 'TIME TO LOCK'),
          if (score.style > 0) ...[
            _divider(),
            _scoreRow(context, 'STYLE', score.style, 100, 'BONUS'),
          ],
          const SizedBox(height: 8),
          Container(
            color: AppColors.acidGreen.withValues(alpha: 0.05),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _mono(context, 'TOTAL', size: headerSz * 1.1, alpha: 0.8),
                Text(
                  '${score.total}',
                  style: TextStyle(
                    color: AppColors.black,
                    fontFamily: 'SpaceMono',
                    fontSize: totalSz,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(
    BuildContext context,
    String label,
    int value,
    int maxValue,
    String sub,
  ) {
    final pct = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final barColor = pct >= 0.9
        ? const Color(0xFFFFD700)
        : pct >= 0.6
            ? AppColors.acidGreen
            : AppColors.acidGreen.withValues(alpha: 0.5);
    final labelSz = responsiveFontSize(context, base: 9, scale: 0.026, max: 12);
    final valSz = responsiveFontSize(context, base: 9, scale: 0.026, max: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _mono(context, label, size: labelSz),
                  _mono(context, sub, size: labelSz * 0.82, alpha: 0.4),
                ],
              ),
              _mono(context, '$value / $maxValue', size: valSz),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(0), // No rounding — tactical
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.acidGreen.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.acidGreen.withValues(alpha: 0.1),
        indent: AppSpacing.md,
        endIndent: AppSpacing.md,
      );

  // ── Meta ────────────────────────────────────────────────────────────────────

  Widget _buildMeta(BuildContext context, GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.acidGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _metaRow(context, 'SEED', gameState.seed),
          _metaRow(context, 'MODE', gameState.mode.toUpperCase()),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, String key, String value) {
    final sz = responsiveFontSize(context, base: 9, scale: 0.024, max: 11);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _mono(context, key, size: sz, alpha: 0.4),
          _mono(context, value, size: sz),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, GameState gameState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _btn(context, '↺  RETRY MISSION',
            filled: true, onTap: gameState.retry),
        const SizedBox(height: AppSpacing.sm),
        _btn(context, '←  EXIT TO MENU',
            filled: false, onTap: gameState.reset),
      ],
    );
  }

  Widget _btn(BuildContext context, String label,
      {required bool filled, required VoidCallback onTap}) {
    final sz = responsiveFontSize(context, base: 10, scale: 0.027, max: 13);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.black.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: filled
                ? AppColors.black
                : AppColors.black.withValues(alpha: 0.35),
            width: filled ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: filled
                  ? AppColors.black
                  : AppColors.black.withValues(alpha: 0.55),
              fontFamily: 'SpaceMono',
              fontSize: sz,
              fontWeight: filled ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ── Mono text helper ─────────────────────────────────────────────────────────

  Text _mono(BuildContext context, String text,
      {required double size, double alpha = 1.0}) =>
      Text(
        text,
        style: TextStyle(
          color: AppColors.black.withValues(alpha: alpha),
          fontFamily: 'SpaceMono',
          fontSize: size,
          letterSpacing: 1.2,
        ),
      );
}

// ── Scanline background painter (unchanged — draws relative to size) ──────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.07)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
