class PlayerProfile {
  final String id;
  final String displayName;
  final double bestScore;
  final double totalScore;
  final int gamesPlayed;

  const PlayerProfile({
    required this.id,
    required this.displayName,
    this.bestScore = 0.0,
    this.totalScore = 0.0,
    this.gamesPlayed = 0,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      bestScore: (json['best_score'] as num?)?.toDouble() ?? 0.0,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
      gamesPlayed: json['games_played'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'best_score': bestScore,
      'total_score': totalScore,
      'games_played': gamesPlayed,
    };
  }

  PlayerProfile copyWith({
    String? id,
    String? displayName,
    double? bestScore,
    double? totalScore,
    int? gamesPlayed,
  }) {
    return PlayerProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      bestScore: bestScore ?? this.bestScore,
      totalScore: totalScore ?? this.totalScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    );
  }
}
