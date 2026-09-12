import 'package:flutter_test/flutter_test.dart';
import 'package:safespit/challenge/challenge_state.dart';
import 'package:safespit/challenge/event_analyzer.dart';
import 'package:safespit/challenge/score_calculator.dart';

void main() {
  group('ChallengeScoreCalculator', () {
    test('maps confidence to the exact challenge scores', () {
      expect(ChallengeScoreCalculator.calculate(0.0), 0.0);
      expect(ChallengeScoreCalculator.calculate(0.29), 0.0);
      expect(ChallengeScoreCalculator.calculate(0.30), 0.5);
      expect(ChallengeScoreCalculator.calculate(0.59), 0.5);
      expect(ChallengeScoreCalculator.calculate(0.60), 0.75);
      expect(ChallengeScoreCalculator.calculate(0.84), 0.75);
      expect(ChallengeScoreCalculator.calculate(0.85), 1.0);
      expect(ChallengeScoreCalculator.calculate(2.0), 1.0);
    });
  });

  group('EventAnalyzer', () {
    const analyzer = EventAnalyzer();

    test('unchanged frames produce no event', () {
      final result = analyzer.analyzeBytes(List.filled(128, 10), List.filled(128, 10));
      expect(result.state, EventDetectionState.noEvent);
      expect(result.score, 0.0);
    });

    test('small frame change produces low confidence', () {
      final result = analyzer.analyzeBytes(List.filled(128, 10), List.filled(128, 50));
      expect(result.state, EventDetectionState.lowConfidence);
      expect(result.score, 0.5);
    });

    test('large frame change produces a high-confidence event', () {
      final result = analyzer.analyzeBytes(List.filled(128, 0), List.filled(128, 255));
      expect(result.state, EventDetectionState.eventDetected);
      expect(result.score, 1.0);
    });
  });
}
