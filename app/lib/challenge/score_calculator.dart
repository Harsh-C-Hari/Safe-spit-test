class ChallengeScoreCalculator {
  const ChallengeScoreCalculator._();

  static double calculate(double confidence) {
    if (confidence < 0.30) return 0.0;
    if (confidence < 0.60) return 0.5;
    if (confidence < 0.85) return 0.75;
    return 1.0;
  }
}
