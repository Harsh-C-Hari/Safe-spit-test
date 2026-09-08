// permission_gate.dart — SAFE//SPIT
//
// PROVEN: PermissionGate "SYSTEM LOCKED" screen.
// PLANNED extension: Demo Mode entry button (D-1, Phase 3).
//
// RULE 5: Demo Mode entry is ALWAYS visible alongside "SYSTEM LOCKED".
// RULE 8: "DEMO MODE" text is always shown when Demo Mode is active.
// The user is never uncertain about what they are operating.

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../game/game_state.dart';
import '../hud/missile_lock_reticle_painter.dart';
import '../sensors/sensor_manager.dart';
import '../sensors/demo_mode_source.dart';

/// The permission gate screen.
///
/// PROVEN behavior: Shows "SYSTEM LOCKED" when permissions are denied.
/// PLANNED behavior (Phase 3): Also shows "ENTER DEMO MODE" button.
/// Demo Mode is opt-in, not silent (Rule 5).
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _isChecking = false;
  bool _permissionsGranted = false;
  String _statusMessage = 'HUD SENSORS UNINITIALIZED.';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    final locationStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;

    final granted = locationStatus.isGranted && cameraStatus.isGranted;

    setState(() {
      _permissionsGranted = granted;
      _isChecking = false;
      if (granted) {
        _statusMessage = 'ALL SENSORS ONLINE.';
      } else {
        _statusMessage = 'HUD SENSORS UNINITIALIZED.';
      }
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'REQUESTING SENSOR ACCESS...';
    });

    final locationResult = await Permission.locationWhenInUse.request();
    final cameraResult = await Permission.camera.request();

    final granted = locationResult.isGranted && cameraResult.isGranted;

    setState(() {
      _permissionsGranted = granted;
      _isChecking = false;
      if (granted) {
        _statusMessage = 'ALL SENSORS ONLINE.';
      } else {
        _statusMessage = 'ACCESS DENIED. TACTICAL SYSTEMS OFFLINE.';
      }
    });
  }

  void _enterRealMode() {
    final gameState = context.read<GameState>();
    // enterHud triggers SafeSpitRouter to switch to HudScreen,
    // and GameState now handles starting the real sensors.
    gameState.enterHud(demo: false);
  }

  void _enterDemoMode() {
    final gameState = context.read<GameState>();
    // enterHud triggers SafeSpitRouter to switch to HudScreen,
    // and GameState now handles starting the demo sensors.
    gameState.enterHud(demo: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Tactical background grid
          CustomPaint(painter: _GridPainter()),

          // Green tint
          Container(color: kTacticalGreen.withValues(alpha: 0.02)),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // PROVEN: "SYSTEM LOCKED" branding
                  Text(
                    'SAFE//SPIT',
                    style: TextStyle(
                      color: kTacticalGreen,
                      fontFamily: 'SpaceMono',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TACTICAL TRAJECTORY SYSTEM',
                    style: TextStyle(
                      color: kTacticalGreen.withValues(alpha: 0.6),
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // PROVEN: System locked indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _permissionsGranted
                              ? kTacticalGreen
                              : kDangerRed.withValues(alpha: 0.7)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _permissionsGranted ? 'SYSTEM ARMED' : 'SYSTEM LOCKED',
                          style: TextStyle(
                            color: _permissionsGranted ? kTacticalGreen : kDangerRed,
                            fontFamily: 'SpaceMono',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kTacticalGreen.withValues(alpha: 0.7),
                            fontFamily: 'SpaceMono',
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_isChecking)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: kTacticalGreen,
                        strokeWidth: 1.5,
                      ),
                    )
                  else ...[
                    // Request permissions button
                    if (!_permissionsGranted)
                      _buildButton(
                        label: 'REQUEST SENSOR ACCESS',
                        onTap: _requestPermissions,
                        filled: true,
                      )
                    else
                      _buildButton(
                        label: 'ENTER NORMAL MODE',
                        onTap: _enterRealMode,
                        filled: true,
                      ),

                    const SizedBox(height: 12),

                    // PLANNED (D-1, Phase 3): Demo Mode entry — ALWAYS visible
                    _buildButton(
                      label: 'ENTER DEMO MODE',
                      onTap: _enterDemoMode,
                      filled: false,
                    ),

                    const SizedBox(height: 12),

                    // PLANNED (Phase 8): Vehicle selection
                    Consumer<GameState>(
                      builder: (context, gameState, _) {
                        return _buildButton(
                          label: 'VEHICLE: ${gameState.vehicle.displayName.toUpperCase()}',
                          onTap: () => Navigator.pushNamed(context, '/vehicle_select'),
                          filled: false,
                        );
                      }
                    ),
                  ],

                  const SizedBox(height: 32),

                  Text(
                    'REF BUILD v1.0 — SIMULATION ONLY\nNO REAL SPITTING AT PERSONS OR PROPERTY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTacticalGreen.withValues(alpha: 0.35),
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? kTacticalGreen.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: filled ? kTacticalGreen : kTacticalGreen.withValues(alpha: 0.5),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: filled ? kTacticalGreen : kTacticalGreen.withValues(alpha: 0.7),
              fontFamily: 'SpaceMono',
              fontSize: 12,
              fontWeight: filled ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// Navigation to HUD is handled by the SafeSpitRouter in main.dart.
// PermissionGate calls Navigator.pushReplacement to the HUD wrapper.

/// Simple tactical grid background painter.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = kTacticalGreen.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    const double spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
