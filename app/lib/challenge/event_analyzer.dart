import 'dart:io';

import 'challenge_state.dart';
import 'score_calculator.dart';

class EventAnalysis {
  final EventDetectionState state;
  final double confidence;

  const EventAnalysis({required this.state, required this.confidence});

  double get score => ChallengeScoreCalculator.calculate(confidence);
}

/// Lightweight local detector based on visual change between the GO frame and
/// the final frame. It evaluates only whether a visible event occurred.
class EventAnalyzer {
  const EventAnalyzer();

  Future<EventAnalysis> analyze(File? startFrame, File? finalFrame) async {
    if (startFrame == null || finalFrame == null) {
      return const EventAnalysis(
        state: EventDetectionState.noEvent,
        confidence: 0.0,
      );
    }

    return analyzeBytes(
      await startFrame.readAsBytes(),
      await finalFrame.readAsBytes(),
    );
  }

  EventAnalysis analyzeBytes(List<int> startBytes, List<int> finalBytes) {
    if (startBytes.isEmpty || finalBytes.isEmpty) {
      return const EventAnalysis(
        state: EventDetectionState.noEvent,
        confidence: 0.0,
      );
    }

    final difference = _sampledDifference(startBytes, finalBytes);
    final confidence = (difference * 2.5).clamp(0.0, 1.0);
    final state = confidence < 0.30
        ? EventDetectionState.noEvent
        : confidence < 0.60
            ? EventDetectionState.lowConfidence
            : EventDetectionState.eventDetected;
    return EventAnalysis(state: state, confidence: confidence);
  }

  double _sampledDifference(List<int> first, List<int> second) {
    const sampleCount = 128;
    var total = 0.0;
    for (var index = 0; index < sampleCount; index++) {
      final firstIndex = (index * first.length / sampleCount).floor();
      final secondIndex = (index * second.length / sampleCount).floor();
      total += (first[firstIndex] - second[secondIndex]).abs() / 255.0;
    }
    return total / sampleCount;
  }
}
