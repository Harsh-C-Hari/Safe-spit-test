class LeaderboardEntry {
  final int rank;
  final String playerId;
  final String displayName;
  final double bestScore;
  final double totalScore;
  final int gamesPlayed;

  const LeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.displayName,
    required this.bestScore,
    required this.totalScore,
    required this.gamesPlayed,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) {
    return LeaderboardEntry(
      rank: rank,
      playerId: json['player_id'] as String,
      displayName: json['display_name'] as String,
      bestScore: (json['best_score'] as num?)?.toDouble() ?? 0.0,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
      gamesPlayed: json['games_played'] as int? ?? 0,
    );
  }
}
