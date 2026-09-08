// audio_service.dart — SAFE//SPIT
//
// PLANNED: Local audio playback for lock-tone (Phase 6, D-2, D-17).
// RULE 4: Lock tone is a LOCAL asset — no network required.
// RULE 10: Audio fires ONCE per lock transition (edge-triggered, not looping).

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the SAFE//SPIT audio cues.
/// Uses audioplayers (D-17) with a local bundled asset (D-2).
///
/// Critical: [playLockTone] must only be called once per false→true transition.
/// The SpitLockController is responsible for calling it at the right moment.
class AudioService {
  static const String _lockToneAsset = 'audio/lock_tone.wav';

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      // Pre-load the asset so first playback has no latency
      await _player.setSource(AssetSource(_lockToneAsset));
      await _player.setVolume(0.8);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[AudioService] Failed to initialize: $e');
      // Non-fatal — audio is enhancement, not core (Rule 4 implies graceful failure)
      _isInitialized = false;
    }
  }

  /// Play the lock-tone once. Call only on the false→true lock transition.
  Future<void> playLockTone() async {
    if (!_isInitialized) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(_lockToneAsset));
    } catch (e) {
      debugPrint('[AudioService] Failed to play lock tone: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
