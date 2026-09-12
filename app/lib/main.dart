// main.dart — SAFE//SPIT
//
// Application entry point. Sets up Provider tree and routing.
// This is the only file with a main() function.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:camera/camera.dart';

import 'theme/app_theme.dart';

import 'game/game_state.dart';
import 'hud/hud_screen.dart';
import 'hud/permission_gate.dart';
import 'screens/result_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'services/supabase_service.dart';
import 'services/player_service.dart';

late List<CameraDescription> globalCameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    globalCameras = await availableCameras();
  } catch (e) {
    globalCameras = [];
    debugPrint('Camera init failed: $e');
  }

  // Initialize services
  final supabaseService = SupabaseService();
  await supabaseService.initialize();

  final playerService = PlayerService();
  await playerService.initialize();

  // Allow all orientations — layouts are responsive per-screen.
  // (HUD screen stays full-bleed on all sizes; other screens adapt.)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Full-screen immersive mode — tactical aesthetic
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(SafeSpitApp(
    playerService: playerService,
  ));
}

/// Root application widget. Provides global services to the entire tree.
class SafeSpitApp extends StatelessWidget {
  final PlayerService playerService;

  const SafeSpitApp({
    super.key,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: playerService),
        ChangeNotifierProvider<GameState>(
          create: (_) => GameState(playerService: playerService),
        ),
      ],
      child: MaterialApp(
        title: 'SAFE//SPIT',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        // Dark theme used only by HUD/PermissionGate — they set their
        // own scaffold background to Colors.black explicitly.
        darkTheme: AppTheme.themeData,
        themeMode: ThemeMode.light,
        home: const SafeSpitRouter(),
        // Named routes for navigation
        routes: {
          '/gate': (_) => const PermissionGate(),
          '/hud': (_) => const SafeSpitHudWrapper(),
          '/result': (_) => const ResultScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/profile': (_) => const ProfileScreen(),
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
    return Consumer2<GameState, PlayerService>(
      builder: (context, gameState, playerService, _) {
        if (!playerService.isOnboardingComplete) {
          return const OnboardingScreen();
        }

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
