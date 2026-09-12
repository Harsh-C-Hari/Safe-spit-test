import '../challenge/challenge_state.dart';
import '../models/score_record.dart';
import 'local_score_store.dart';
import 'supabase_service.dart';
import 'player_service.dart';

enum ScoreSyncState { savedLocally, synced, pending }

class ScorePersistenceService {
  final LocalScoreStore localStore;
  final SupabaseService supabase;
  final PlayerService playerService;

  ScorePersistenceService({
    LocalScoreStore? localStore,
    SupabaseService? supabase,
    required this.playerService,
  })  : localStore = localStore ?? LocalScoreStore(),
        supabase = supabase ?? SupabaseService();

  Future<ScoreSyncState> saveChallenge({
    required ChallengeResult result,
    required String seed,
    required String mode,
    required int physicsPoints,
  }) async {
    final record = ScoreRecord.fromChallenge(
      result: result,
      seed: seed,
      mode: mode,
      physicsPoints: physicsPoints,
    );
    await localStore.save(record);
    await playerService.incrementStats(record.score);

    final playerId = playerService.currentProfile?.id;
    if (playerId == null) {
      return ScoreSyncState.savedLocally;
    }

    try {
      await supabase.submit(record, playerId);
      await localStore.markSynced(record.id);
      return ScoreSyncState.synced;
    } catch (_) {
      return supabase.isConfigured
          ? ScoreSyncState.pending
          : ScoreSyncState.savedLocally;
    }
  }

  Future<void> syncPending() async {
    final playerId = playerService.currentProfile?.id;
    if (playerId == null) return;

    for (final record in await localStore.pending()) {
      try {
        await supabase.submit(record, playerId);
        await localStore.markSynced(record.id);
      } catch (_) {
        return;
      }
    }
  }
}
