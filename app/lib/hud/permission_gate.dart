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
import '../theme/app_theme.dart';

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
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Tactical background grid
          CustomPaint(painter: _GridPainter()),

          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsivePaddingH(context),
                vertical: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // PROVEN: "SYSTEM LOCKED" branding
                  Text(
                    'SAFE//SPIT',
                    style: TextStyle(
                      color: AppColors.black,
                      fontFamily: 'SpaceMono',
                      fontSize: responsiveFontSize(context, base: 24, scale: 0.06, max: 32),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TACTICAL TRAJECTORY SYSTEM',
                    style: TextStyle(
                      color: AppColors.black.withValues(alpha: 0.6),
                      fontFamily: 'SpaceMono',
                      fontSize: responsiveFontSize(context, base: 8, scale: 0.02, max: 11),
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
                              ? AppColors.black
                              : AppColors.orange,
                          width: 2.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _permissionsGranted ? 'SYSTEM ARMED' : 'SYSTEM LOCKED',
                          style: TextStyle(
                            color: _permissionsGranted ? AppColors.black : AppColors.orange,
                            fontFamily: 'SpaceMono',
                            fontSize: responsiveFontSize(context, base: 15, scale: 0.038, max: 20),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.7),
                            fontFamily: 'SpaceMono',
                            fontSize: responsiveFontSize(context, base: 9, scale: 0.024, max: 12),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_isChecking)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.black,
                        strokeWidth: 1.5,
                      ),
                    )
                  else ...[
                    // Request permissions button
                    if (!_permissionsGranted)
                      AppTacticalButton(
                        label: 'REQUEST SENSOR ACCESS',
                        onPressed: _requestPermissions,
                        filled: true,
                      )
                    else
                      AppTacticalButton(
                        label: 'ENTER NORMAL MODE',
                        onPressed: _enterRealMode,
                        filled: true,
                      ),

                    const SizedBox(height: 12),

                    // PLANNED (D-1, Phase 3): Demo Mode entry — ALWAYS visible
                    AppTacticalButton(
                      label: 'ENTER DEMO MODE',
                      onPressed: _enterDemoMode,
                      filled: false,
                    ),

                  ],

                  const SizedBox(height: 32),

                  Text(
                    'REF BUILD v1.0 — SIMULATION ONLY\nNO REAL SPITTING AT PERSONS OR PROPERTY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.black.withValues(alpha: 0.35),
                      fontFamily: 'SpaceMono',
                      fontSize: responsiveFontSize(context, base: 7, scale: 0.02, max: 10),
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person),
                        color: AppColors.black,
                        onPressed: () => Navigator.pushNamed(context, '/profile'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
      ..color = AppColors.black.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    // Responsive grid spacing: 10% of screen width
    final double spacing = size.width * 0.10;
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
