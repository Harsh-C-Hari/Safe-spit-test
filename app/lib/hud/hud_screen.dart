// hud_screen.dart — SAFE//SPIT
//
// PROVEN: HUD screen with camera passthrough + reticle overlay.
// PLANNED: Extended with NormalizedTelemetry stream, Demo Mode indicator,
//          trajectory line, telemetry bars, diagnostics.
//
// RULE 3: This screen reads NormalizedTelemetry and SimulationResult only.
//         No raw geolocator/sensors_plus imports.
// RULE 5: Demo Mode is always clearly labeled (Rule 8).
// RULE 8: "DEMO MODE" text is always visible when isDemoMode is true.

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_state.dart';
import '../game/spit_lock_controller.dart';
import '../sensors/normalized_telemetry.dart';
import '../simulation/scenario.dart';
import '../simulation/trajectory_model.dart';
import '../simulation/vehicle_profiles.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import 'missile_lock_reticle_painter.dart';

/// The main HUD screen. Displays camera passthrough with tactical reticle overlay.
/// Listens to [GameState] via Provider.
class HudScreen extends StatefulWidget {
  const HudScreen({super.key});

  @override
  State<HudScreen> createState() => _HudScreenState();
}

class _HudScreenState extends State<HudScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _cameraError = false;

  late AnimationController _pulseController;
  late StreamSubscription<LockTransition> _lockTransitionSub;

  final AudioService _audio = AudioService();
  final HapticService _haptic = HapticService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _initCamera();
    _audio.initialize();
    _setupLockTransitionListener();
  }

  void _setupLockTransitionListener() {
    final gameState = context.read<GameState>();
    _lockTransitionSub = gameState.lockController.onTransition.listen(
      (transition) async {
        if (transition.isLockAcquired) {
          // Rule 10: Fire ONCE on false→true edge only.
          await _audio.playLockTone();
          await _haptic.onLockAcquired();
        } else if (transition.isLockLost) {
          // A-tier: optional lost-lock cue
          await _haptic.onLockLost();
        }
      },
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = true);
        return;
      }
      // PROVEN: CameraController(cameras.first, ResolutionPreset.high, enableAudio: false)
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      debugPrint('[HudScreen] Camera error: $e'); // PROVEN debug string pattern
      if (mounted) {
        setState(() => _cameraError = true);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _lockTransitionSub.cancel();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<GameState>(
        builder: (context, gameState, _) {
          final telemetry = gameState.telemetry;
          final simResult = gameState.simResult;
          final lockState = gameState.lockController.state;
          final lockQuality = gameState.lockController.lockQuality;

          // Compute trajectory for HUD arc
          List<TrajectoryPoint>? trajectory;
          if (simResult != null) {
            trajectory = computeTrajectoryArc(
              pitchDeg: telemetry.pitchDeg,
              speedKmh: telemetry.speedKmh,
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── PROVEN: Camera passthrough ───────────────────────────────
              _buildCameraLayer(),

              // ── PROVEN: Green tint overlay (5% opacity) ──────────────────
              Container(color: kCameraTint.withValues(alpha: 0.05)),

              // ── PROVEN: Reticle overlay ──────────────────────────────────
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => CustomPaint(
                  painter: MissileLockReticlePainter(
                    targetPitchDeg: simResult?.targetPitchDeg ?? 45.0,
                    actualPitchDeg: telemetry.pitchDeg,
                    speedKmh: telemetry.speedKmh,
                    lockState: lockState,
                    lockQuality: lockQuality,
                    deltaDeg: simResult?.deltaDeg ?? 0.0,
                    isDemoMode: telemetry.isDemoMode,
                    trajectoryPoints: trajectory,
                    deviationM: simResult?.deviationM,
                    animValue: _pulseController.value,
                  ),
                  size: MediaQuery.of(context).size,
                ),
              ),

              // ── PROVEN: Top diagnostics bar ──────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(simResult, telemetry, lockState),
              ),

              // ── PROVEN: Bottom telemetry bar ─────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(telemetry, lockState, gameState),
              ),

              // ── RULE 8: Demo Mode indicator ──────────────────────────────
              if (telemetry.isDemoMode)
                Positioned(
                  top: 80,
                  right: 16,
                  child: _buildDemoModeIndicator(),
                ),

              // ── LAUNCH button (visible when locked) ──────────────────────
              if (lockState == SpitLockState.locked &&
                  gameState.phase != GamePhase.launched &&
                  gameState.phase != GamePhase.scored)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: _buildLaunchButton(gameState),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── PROVEN: Camera passthrough build ─────────────────────────────────────

  Widget _buildCameraLayer() {
    if (_cameraReady && _cameraController != null) {
      return CameraPreview(_cameraController!);
    }
    if (_cameraError) {
      // PROVEN fallback: black background with camera error indicator
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, color: kTacticalGreen.withValues(alpha: 0.4), size: 48),
              const SizedBox(height: 8),
              Text(
                'OPTICAL SENSOR OFFLINE',
                style: TextStyle(
                  color: kTacticalGreen.withValues(alpha: 0.4),
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Loading state
    return Container(color: Colors.black);
  }

  // ── PROVEN: Top diagnostics bar ──────────────────────────────────────────

  Widget _buildTopBar(
      SimulationResult? simResult, NormalizedTelemetry telemetry, SpitLockState lockState) {
    final double tgt = simResult?.targetPitchDeg ?? 45.0;
    final double act = telemetry.pitchDeg;
    final double delta = simResult?.deltaDeg ?? (act - tgt).abs();

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(12, 36, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: _hudText('SPIT v1.0')),
          Flexible(child: _hudText('TGT ${tgt.toStringAsFixed(1)}°')),
          Flexible(child: _hudText('ACT ${act.toStringAsFixed(1)}°')),
          Flexible(child: _hudText('Δ ${delta.toStringAsFixed(1)}°')),
        ],
      ),
    );
  }

  // ── PROVEN: Bottom telemetry bar ──────────────────────────────────────────

  Widget _buildBottomBar(
      NormalizedTelemetry telemetry, SpitLockState lockState, GameState gameState) {
    final String lockText = lockState == SpitLockState.locked
        ? '■ SPIT LOCK'
        : lockState == SpitLockState.locking
            ? '◈ ACQUIRING'
            : '○ SEARCHING';

    final Color lockColor = lockState == SpitLockState.locked
        ? kTacticalGreen
        : lockState == SpitLockState.locking
            ? kTacticalGreen.withValues(alpha: 0.7)
            : kTacticalGreen.withValues(alpha: 0.4);

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: _hudText('${telemetry.speedKmh.toStringAsFixed(0)} KM/H')),
          Flexible(
            child: _hudText(
              '${_cardinal(telemetry.headingDeg)} ${telemetry.headingDeg.toStringAsFixed(0)}°',
            ),
          ),
          Flexible(
            child: Text(
              lockText,
              style: TextStyle(
                color: lockColor,
                fontFamily: 'SpaceMono',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Flexible(
            child: GestureDetector(
              onTap: () => _showVehicleSelector(context, gameState),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: kTacticalGreen.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _hudText(gameState.vehicle.displayName.toUpperCase()),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_up, color: kTacticalGreen, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVehicleSelector(BuildContext context, GameState gameState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: kTacticalGreen, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SELECT VEHICLE',
                style: _bigHudStyle(size: 16),
              ),
              const SizedBox(height: 16),
              ...VehicleProfiles.all.map((profile) {
                final bool isSelected = profile.id == gameState.vehicle.id;
                return ListTile(
                  title: Text(
                    profile.displayName.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : kTacticalGreen,
                      fontFamily: 'SpaceMono',
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  tileColor: isSelected ? kTacticalGreen : Colors.transparent,
                  onTap: () {
                    gameState.selectVehicle(profile);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── RULE 8: Demo Mode indicator ──────────────────────────────────────────

  Widget _buildDemoModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: kTacticalGreen.withValues(alpha: 0.6)),
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Text(
        'DEMO MODE',
        style: TextStyle(
          color: kTacticalGreen,
          fontFamily: 'SpaceMono',
          fontSize: 10,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ── Launch button ─────────────────────────────────────────────────────────

  Widget _buildLaunchButton(GameState gameState) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          await _haptic.onLaunch();
          gameState.launch();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: kTacticalGreen, width: 2),
            color: Colors.black.withValues(alpha: 0.7),
          ),
          child: const Text(
            '⚡ EXECUTE SPIT PROTOCOL',
            style: TextStyle(
              color: kTacticalGreen,
              fontFamily: 'SpaceMono',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }


  // ── Helpers ────────────────────────────────────────────────────────────────

  String _cardinal(double deg) {
    final d = ((deg % 360) + 360) % 360;
    if (d >= 337.5 || d < 22.5) return 'N';
    if (d < 67.5) return 'NE';
    if (d < 112.5) return 'E';
    if (d < 157.5) return 'SE';
    if (d < 202.5) return 'S';
    if (d < 247.5) return 'SW';
    if (d < 292.5) return 'W';
    return 'NW';
  }

  Widget _hudText(String text) => Text(
        text,
        style: const TextStyle(
          color: kTacticalGreen,
          fontFamily: 'SpaceMono',
          fontSize: 11,
          letterSpacing: 1.0,
        ),
      );

  TextStyle _bigHudStyle({double size = 22}) => TextStyle(
        color: kTacticalGreen,
        fontFamily: 'SpaceMono',
        fontSize: size,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
      );

  TextStyle _smallHudStyle() => const TextStyle(
        color: kTacticalGreen,
        fontFamily: 'SpaceMono',
        fontSize: 13,
        letterSpacing: 1.5,
      );
}
