// backend_gateway.dart — SAFE//SPIT
//
// PLANNED: BackendGateway interface with NoopBackendGateway default (Phase 12, D-9).
// RULE 4: Core game cannot depend on internet. This interface enforces that
//         structurally — all screens code against this interface, never Supabase directly.
//
// Default: NoopBackendGateway — all methods succeed silently with no network calls.


/// Abstract interface for backend operations.
/// Always code against this, never against Supabase directly.
abstract class BackendGateway {
  /// Submit a score. May be a no-op if offline or unconfigured.
  Future<void> submitScore({
    required String seed,
    required String vehicle,
    required String mode,
    required int score,
    required String callsign,
  });

  /// Fetch the leaderboard. Returns an empty list if unavailable.
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String mode,
    int limit = 20,
  });
}

/// A score entry from the leaderboard.
class LeaderboardEntry {
  final String callsign;
  final int score;
  final String seed;
  final String mode;
  final DateTime timestamp;

  const LeaderboardEntry({
    required this.callsign,
    required this.score,
    required this.seed,
    required this.mode,
    required this.timestamp,
  });
}

/// The default implementation — does nothing, returns empty results.
/// Used when Supabase is not configured or unavailable (D-9, RULE 4).
class NoopBackendGateway implements BackendGateway {
  const NoopBackendGateway();

  @override
  Future<void> submitScore({
    required String seed,
    required String vehicle,
    required String mode,
    required int score,
    required String callsign,
  }) async {
    // No-op: scores are only kept locally in the reference build.
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String mode,
    int limit = 20,
  }) async {
    return const [];
  }
}
