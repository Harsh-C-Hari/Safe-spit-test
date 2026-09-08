// result_screen.dart — SAFE//SPIT
//
// PLANNED: Dedicated result screen (Phase 9).
// Shows score breakdown, letter grade, mission metadata, and
// RETRY / EXIT TO MENU actions.
//
// RULE 2: No raw sensor imports.
// RULE 5: Demo Mode is clearly labeled.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_state.dart';
import '../simulation/scenario.dart';

const Color _kGreen = Color(0xFF39FF14);

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
    case 'S': return const Color(0xFFFFD700);
    case 'A': return _kGreen;
    case 'B': return const Color(0xFF00BFFF);
    case 'C': return const Color(0xFFFFAA00);
    case 'D': return const Color(0xFFFF6600);
    default:  return const Color(0xFFFF2200);
  }
}

String _gradeLabel(String grade) {
  switch (grade) {
    case 'S': return 'LEGENDARY TRAJECTORY';
    case 'A': return 'EXCELLENT EXECUTION';
    case 'B': return 'SOLID DEPLOYMENT';
    case 'C': return 'MARGINAL CLEARANCE';
    case 'D': return 'COMPROMISED PROTOCOL';
    default:  return 'MISSION FAILURE';
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final score = gameState.finalScore;
        if (score == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: _kGreen)),
          );
        }

        final grade = _letterGrade(score.total);
        final gradeColor = _gradeColor(grade);
        final isDemoMode = gameState.isDemoMode;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isDemoMode),
                        const SizedBox(height: 24),
                        _buildGradeBadge(grade, gradeColor, score.total),
                        const SizedBox(height: 28),
                        _buildBreakdown(score),
                        const SizedBox(height: 24),
                        _buildMeta(gameState),
                        const SizedBox(height: 32),
                        _buildActions(gameState),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildHeader(bool isDemoMode) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _mono('SAFE//SPIT', size: 13, alpha: 0.5),
      if (isDemoMode)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(border: Border.all(color: _kGreen.withValues(alpha: 0.5))),
          child: _mono('DEMO MODE', size: 10),
        ),
      _mono('MISSION REPORT', size: 13, alpha: 0.5),
    ],
  );

  Widget _buildGradeBadge(String grade, Color gradeColor, int total) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _mono('[ ', size: 28, alpha: 0.35),
          Text(
            grade,
            style: TextStyle(
              color: gradeColor,
              fontFamily: 'SpaceMono',
              fontSize: 96,
              fontWeight: FontWeight.bold,
              letterSpacing: -4,
              shadows: [Shadow(color: gradeColor.withValues(alpha: 0.5), blurRadius: 24)],
            ),
          ),
          _mono(' ]', size: 28, alpha: 0.35),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '$total pts',
        style: const TextStyle(
          color: _kGreen, fontFamily: 'SpaceMono',
          fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4,
        ),
      ),
      const SizedBox(height: 4),
      _mono(_gradeLabel(grade), size: 11, alpha: 0.6),
    ],
  );

  Widget _buildBreakdown(ScoreBreakdown score) => Container(
    decoration: BoxDecoration(border: Border.all(color: _kGreen.withValues(alpha: 0.25))),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: _kGreen.withValues(alpha: 0.08),
          child: Center(child: _mono('SCORE BREAKDOWN', size: 11, alpha: 0.6)),
        ),
        const SizedBox(height: 4),
        _scoreRow('PRECISION', score.precision, 500, 'LOCK QUALITY'),
        _divider(),
        _scoreRow('IMPACT',    score.impact,    300, 'TRAJECTORY DEVIATION'),
        _divider(),
        _scoreRow('TIMING',    score.timing,    200, 'TIME TO LOCK'),
        if (score.style > 0) ...[
          _divider(),
          _scoreRow('STYLE',   score.style,     100, 'BONUS'),
        ],
        const SizedBox(height: 8),
        Container(
          color: _kGreen.withValues(alpha: 0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _mono('TOTAL', size: 13, alpha: 0.8),
              Text(
                '${score.total}',
                style: const TextStyle(
                  color: _kGreen, fontFamily: 'SpaceMono',
                  fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _scoreRow(String label, int value, int maxValue, String sub) {
    final pct = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final barColor = pct >= 0.9
        ? const Color(0xFFFFD700)
        : pct >= 0.6
            ? _kGreen
            : _kGreen.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_mono(label, size: 12), _mono(sub, size: 9, alpha: 0.4)],
              ),
              _mono('$value / $maxValue', size: 12),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _kGreen.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1, thickness: 1,
    color: _kGreen.withValues(alpha: 0.1), indent: 16, endIndent: 16,
  );

  Widget _buildMeta(GameState gameState) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(border: Border.all(color: _kGreen.withValues(alpha: 0.15))),
    child: Column(
      children: [
        _metaRow('SEED',    gameState.seed),
        _metaRow('VEHICLE', gameState.vehicle.displayName.toUpperCase()),
        _metaRow('MODE',    gameState.mode.toUpperCase()),
      ],
    ),
  );

  Widget _metaRow(String key, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_mono(key, size: 11, alpha: 0.4), _mono(value, size: 11)],
    ),
  );

  Widget _buildActions(GameState gameState) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _btn('?  RETRY MISSION', filled: true,  onTap: gameState.retry),
      const SizedBox(height: 12),
      _btn('?  EXIT TO MENU',  filled: false, onTap: gameState.reset),
    ],
  );

  Widget _btn(String label, {required bool filled, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? _kGreen.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: filled ? _kGreen : _kGreen.withValues(alpha: 0.35),
            width: filled ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: filled ? _kGreen : _kGreen.withValues(alpha: 0.55),
              fontFamily: 'SpaceMono',
              fontSize: 13,
              fontWeight: filled ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );

  Text _mono(String text, {double size = 12, double alpha = 1.0}) => Text(
    text,
    style: TextStyle(
      color: _kGreen.withValues(alpha: alpha),
      fontFamily: 'SpaceMono', fontSize: size, letterSpacing: 1.2,
    ),
  );
}

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
