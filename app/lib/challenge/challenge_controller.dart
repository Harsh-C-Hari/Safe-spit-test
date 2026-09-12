import 'dart:async';
import 'dart:io';

import 'challenge_state.dart';
import 'event_analyzer.dart';

class ChallengeController {
  static const detectionWindow = Duration(milliseconds: 1000);

  final EventAnalyzer analyzer;
  ChallengeState _state = ChallengeState.ready;
  bool _isRunning = false;

  ChallengeController({EventAnalyzer? analyzer})
      : analyzer = analyzer ?? const EventAnalyzer();

  ChallengeState get state => _state;
  bool get isRunning => _isRunning;

  Future<ChallengeResult> run({
    required Future<File?> Function() captureFrame,
    required Future<void> Function() onCountdownCue,
    required Future<void> Function() onGoCue,
    void Function(ChallengeState state)? onStateChanged,
  }) async {
    if (_isRunning) {
      return const ChallengeResult(
        state: ChallengeState.noFrame,
        eventState: EventDetectionState.noEvent,
        confidence: 0.0,
        score: 0.0,
      );
    }

    _isRunning = true;
    try {
      await _countdown(ChallengeState.countdown3, onCountdownCue, onStateChanged);
      await _countdown(ChallengeState.countdown2, onCountdownCue, onStateChanged);
      await _countdown(ChallengeState.countdown1, onCountdownCue, onStateChanged);

      _setState(ChallengeState.go, onStateChanged);
      await onGoCue();
      _setState(ChallengeState.capturing, onStateChanged);

      final goAt = DateTime.now();
      final startFrame = await captureFrame();
      await Future<void>.delayed(detectionWindow);
      final finalFrame = await captureFrame();
      final snapshotAt = DateTime.now();
      if (startFrame == null || finalFrame == null) {
        _setState(ChallengeState.noFrame, onStateChanged);
        return const ChallengeResult(
          state: ChallengeState.noFrame,
          eventState: EventDetectionState.noEvent,
          confidence: 0.0,
          score: 0.0,
        );
      }

      _setState(ChallengeState.analyzing, onStateChanged);
      final analysis = await analyzer.analyze(startFrame, finalFrame);
      final resultState = analysis.state == EventDetectionState.lowConfidence
          ? ChallengeState.lowConfidence
          : ChallengeState.scored;
      _setState(resultState, onStateChanged);
      return ChallengeResult(
        state: resultState,
        eventState: analysis.state,
        confidence: analysis.confidence,
        score: analysis.score,
        snapshotPath: finalFrame.path,
        goAt: goAt,
        snapshotAt: snapshotAt,
      );
    } on CameraCaptureException {
      _setState(ChallengeState.cameraError, onStateChanged);
      return const ChallengeResult(
        state: ChallengeState.cameraError,
        eventState: EventDetectionState.noEvent,
        confidence: 0.0,
        score: 0.0,
      );
    } catch (_) {
      _setState(ChallengeState.cameraError, onStateChanged);
      return const ChallengeResult(
        state: ChallengeState.cameraError,
        eventState: EventDetectionState.noEvent,
        confidence: 0.0,
        score: 0.0,
      );
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _countdown(
    ChallengeState state,
    Future<void> Function() cue,
    void Function(ChallengeState state)? onStateChanged,
  ) async {
    _setState(state, onStateChanged);
    await cue();
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  void _setState(
    ChallengeState state,
    void Function(ChallengeState state)? onStateChanged,
  ) {
    _state = state;
    onStateChanged?.call(state);
  }
}

class CameraCaptureException implements Exception {
  final String message;

  const CameraCaptureException(this.message);

  @override
  String toString() => message;
}
