// main.dart — SAFE//SPIT
//
// Application entry point. Sets up Provider tree and routing.
// This is the only file with a main() function.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'game/game_state.dart';
import 'hud/hud_screen.dart';
import 'hud/permission_gate.dart';
import 'screens/result_screen.dart';
import 'screens/vehicle_select_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for the HUD experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Full-screen immersive mode — tactical aesthetic
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const SafeSpitApp());
}

/// Root application widget. Provides [GameState] to the entire tree.
class SafeSpitApp extends StatelessWidget {
  const SafeSpitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameState>(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'SAFE//SPIT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'SpaceMono',
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF39FF14),
            secondary: Color(0xFF39FF14),
            surface: Colors.black,
          ),
        ),
        home: const SafeSpitRouter(),
        // Named routes for navigation
        routes: {
          '/gate': (_) => const PermissionGate(),
          '/hud': (_) => const SafeSpitHudWrapper(),
          '/vehicle_select': (_) => const VehicleSelectScreen(),
          '/result': (_) => const ResultScreen(),
        },
      ),
    );
  }
}

/// Router that wraps navigation from gate to HUD.
/// Resolves the import_hud_screen forward declaration in permission_gate.dart.
class SafeSpitRouter extends StatelessWidget {
  const SafeSpitRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        // Scored → show result screen
        if (gameState.phase == GamePhase.scored) {
          return const ResultScreen();
        }
        // Idle → show the gate
        if (gameState.phase == GamePhase.idle) {
          return const PermissionGate();
        }
        // Otherwise show the HUD
        return const SafeSpitHudWrapper();
      },
    );
  }
}

/// Wrapper that connects the sensor stream to GameState before showing HUD.
/// The sensor start is handled by PermissionGate; this just renders the HUD.
class SafeSpitHudWrapper extends StatelessWidget {
  const SafeSpitHudWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const HudScreen();
  }
}
