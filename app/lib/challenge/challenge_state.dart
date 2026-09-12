enum ChallengeState {
  ready,
  countdown3,
  countdown2,
  countdown1,
  go,
  capturing,
  analyzing,
  scored,
  cameraError,
  noFrame,
  lowConfidence,
}

enum EventDetectionState { noEvent, eventDetected, lowConfidence }

class ChallengeResult {
  final ChallengeState state;
  final EventDetectionState eventState;
  final double confidence;
  final double score;
  final String? snapshotPath;
  final DateTime? goAt;
  final DateTime? snapshotAt;

  const ChallengeResult({
    required this.state,
    required this.eventState,
    required this.confidence,
    required this.score,
    this.snapshotPath,
    this.goAt,
    this.snapshotAt,
  });

  bool get hasEvent => eventState != EventDetectionState.noEvent;

  ChallengeResult copyWith({String? snapshotPath}) => ChallengeResult(
        state: state,
        eventState: eventState,
        confidence: confidence,
        score: score,
        snapshotPath: snapshotPath,
        goAt: goAt,
        snapshotAt: snapshotAt,
      );
}
