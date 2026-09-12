// game_state.dart — SAFE//SPIT
//
// PLANNED: Game state machine and top-level ChangeNotifier (Phase 6).
// State machine: Idle → HudLive → Locking → Locked → Launched → Scored
// RULE 4: Core game cannot depend on internet (no Supabase calls here).

import 'package:flutter/foundation.dart';

import '../sensors/normalized_telemetry.dart';
import '../simulation/scenario.dart';
import '../simulation/scoring.dart';
import '../simulation/simulation_engine.dart';
import '../sensors/sensor_manager.dart';
import '../sensors/demo_mode_source.dart';
import '../challenge/challenge_state.dart';
import '../services/score_persistence_service.dart';
import '../services/player_service.dart';
import 'dart:async';
import 'spit_lock_controller.dart';

/// The top-level game phase.
enum GamePhase {
  idle, // Waiting for permissions / scenario selection
  hudLive, // HUD active, telemetry streaming
  locking, // Lock acquiring
  locked, // SPIT LOCK acquired
  launched, // Spit launched — simulation frozen
  scored, // Score computed, result available
}

/// The central game state, exposed via Provider (D-8, D-16).
class GameState extends ChangeNotifier {
  // ── Current phase ─────────────────────────────────────────────────────────
  GamePhase _phase = GamePhase.idle;
  GamePhase get phase => _phase;

  // ── Scenario ───────────────────────────────────────────────────────────────
  String _seed = 'DEMO01'; // default demo seed
  String get seed => _seed;

  String _mode = 'precision';
  String get mode => _mode;

  // ── Live simulation ────────────────────────────────────────────────────────
  NormalizedTelemetry _telemetry = NormalizedTelemetry.zero();
  NormalizedTelemetry get telemetry => _telemetry;

  SimulationResult? _simResult;
  SimulationResult? get simResult => _simResult;

  final SpitLockController lockController = SpitLockController();

  // ── Lock timing ───────────────────────────────────────────────────────────
  DateTime? _hudLiveStart;
  int _timeToLockMs = 0;
  int get timeToLockMs => _timeToLockMs;

  // ── Frozen launch state ────────────────────────────────────────────────────
  SimulationResult? _launchedResult;
  SimulationResult? get launchedResult => _launchedResult;

  ScoreBreakdown? _finalScore;
  ScoreBreakdown? get finalScore => _finalScore;
  ChallengeResult? _challengeResult;
  ChallengeResult? get challengeResult => _challengeResult;
  late final ScorePersistenceService _scorePersistence;
  ScoreSyncState? _scoreSyncState;
  ScoreSyncState? get scoreSyncState => _scoreSyncState;

  final PlayerService playerService;

  GameState({required this.playerService}) {
    _scorePersistence = ScorePersistenceService(playerService: playerService);
  }

  void clearChallengeSnapshot() {
    final result = _challengeResult;
    if (result == null) return;
    _challengeResult = result.copyWith();
    notifyListeners();
  }

  // ── Demo mode ─────────────────────────────────────────────────────────────
  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  bool get isFacingBackwards => _telemetry.isFacingBackwards;

  // ── Sensor Management ───────────────────────────────────────────────────────
  SensorManager? _sensorManager;
  DemoModeSource? _demoSource;
  StreamSubscription<NormalizedTelemetry>? _telemetrySub;

  void _cleanupSensors() {
    _telemetrySub?.cancel();
    _telemetrySub = null;
    _sensorManager?.dispose();
    _sensorManager = null;
    _demoSource?.dispose();
    _demoSource = null;
  }

  /// Enter HUD from the permission gate. Sets Demo Mode if [demo] is true.
  void enterHud({bool demo = false}) {
    _cleanupSensors();
    unawaited(_scorePersistence.syncPending());
    
    _isDemoMode = demo;
    if (demo) {
      _demoSource = DemoModeSource();
      _telemetrySub = _demoSource!.stream.listen(onTelemetry);
    } else {
      _sensorManager = SensorManager();
      _sensorManager!.start().then((_) {
        _telemetrySub = _sensorManager!.stream.listen(onTelemetry);
      });
    }

    _hudLiveStart = DateTime.now();
    lockController.reset();
    _setPhase(GamePhase.hudLive);
  }
  void onTelemetry(NormalizedTelemetry telemetry) {
    if (_phase == GamePhase.idle || _phase == GamePhase.launched || _phase == GamePhase.scored) {
      _telemetry = telemetry;
      notifyListeners();
      return;
    }

    _telemetry = telemetry;

    // Run the simulation
    final scenario = ScenarioInput(
      seed: _seed,
      speedKmh: telemetry.speedKmh,
      pitchDeg: telemetry.pitchDeg,
      rollDeg: telemetry.rollDeg,
      windSpeedKmh: 0.0, // TODO: derive from seed in Phase 4 full impl
      windDirectionDeg: 0.0,
      isFacingBackwards: telemetry.isFacingBackwards,
      mode: _mode,
    );

    _simResult = simulate(scenario);

    // Process lock state machine
    lockController.processTick(_simResult!, DateTime.now());

    // Update phase based on lock state
    switch (lockController.state) {
      case SpitLockState.searching:
        if (_phase != GamePhase.hudLive) _setPhase(GamePhase.hudLive);
        break;
      case SpitLockState.locking:
        if (_phase == GamePhase.hudLive) _setPhase(GamePhase.locking);
        break;
      case SpitLockState.locked:
        if (_phase != GamePhase.locked) {
          _timeToLockMs = _hudLiveStart != null
              ? DateTime.now().difference(_hudLiveStart!).inMilliseconds
              : 0;
          _setPhase(GamePhase.locked);
        }
        break;
    }

    notifyListeners();
  }

  /// Launch the spit — freeze simulation and compute score.
  void launch({ChallengeResult? challengeResult}) {
    if (_phase != GamePhase.locked && _phase != GamePhase.locking) return;

    // Freeze the simulation snapshot
    _launchedResult = _simResult;
    _challengeResult = challengeResult;
    _setPhase(GamePhase.launched);

    // Compute deterministic score
    if (_launchedResult != null) {
      _finalScore = computeScore(
        lockQuality: lockController.lockQuality,
        deviationM: _launchedResult!.deviationM,
        timeToLockMs: _timeToLockMs,
        mode: _mode,
      );
      _setPhase(GamePhase.scored);
    }

    if (challengeResult != null) {
      unawaited(_persistChallengeScore(challengeResult));
    }

    notifyListeners();
  }

  Future<void> _persistChallengeScore(ChallengeResult result) async {
    _scoreSyncState = await _scorePersistence.saveChallenge(
      result: result,
      seed: _seed,
      mode: _mode,
      physicsPoints: _finalScore?.total ?? 0,
    );
    notifyListeners();
  }

  /// Start a new round with the same or new scenario, returning to the menu.
  void reset({String? seed, String? mode}) {
    _seed = seed ?? _generateSeed();
    _mode = mode ?? _mode;
    _hudLiveStart = null;
    _timeToLockMs = 0;
    _launchedResult = null;
    _finalScore = null;
    _challengeResult = null;
    _scoreSyncState = null;
    _simResult = null;
    lockController.reset();
    _setPhase(GamePhase.idle);
  }

  /// Instantly restart the current mission without leaving the HUD.
  void retry() {
    _hudLiveStart = DateTime.now();
    _timeToLockMs = 0;
    _launchedResult = null;
    _finalScore = null;
    _challengeResult = null;
    _scoreSyncState = null;
    _simResult = null;
    lockController.reset();
    _setPhase(GamePhase.hudLive);
  }

  void _setPhase(GamePhase phase) {
    _phase = phase;
    notifyListeners();
  }

  String _generateSeed() {
    // Deterministic-ish: use current time truncated to a 6-char hex.
    // In production this would be a seeded RNG (D-19).
    final int millis = DateTime.now().millisecondsSinceEpoch;
    return (millis & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0');
  }

  @override
  void dispose() {
    _cleanupSensors();
    lockController.dispose();
    super.dispose();
  }
}
