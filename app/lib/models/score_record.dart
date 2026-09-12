import '../challenge/challenge_state.dart';

class ScoreRecord {
  final String id;
  final String seed;
  final String mode;
  final double score;
  final double confidence;
  final bool eventDetected;
  final DateTime createdAt;

  const ScoreRecord({
    required this.id,
    required this.seed,
    required this.mode,
    required this.score,
    required this.confidence,
    required this.eventDetected,
    required this.createdAt,
  });

  factory ScoreRecord.fromChallenge({
    required ChallengeResult result,
    required String seed,
    required String mode,
    required int physicsPoints,
  }) {
    return ScoreRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}-$seed',
      seed: seed,
      mode: mode,
      score: (physicsPoints * result.score).toDouble(),
      confidence: result.confidence.clamp(0.0, 1.0),
      eventDetected: result.hasEvent,
      createdAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seed': seed,
        'mode': mode,
        'score': score,
        'confidence': confidence,
        'eventDetected': eventDetected,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScoreRecord.fromJson(Map<String, dynamic> json) => ScoreRecord(
        id: json['id'] as String,
        seed: json['seed'] as String,
        mode: json['mode'] as String,
        score: (json['score'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        eventDetected: json['eventDetected'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
