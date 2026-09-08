// haptic_service.dart — SAFE//SPIT
//
// PLANNED: Haptic feedback wrapper (Phase 6/15).
// RULE 10: Haptics fire ONCE per lock transition — not continuously.
// Wraps Flutter's HapticFeedback to allow easy mocking in tests.

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Haptic cues for SAFE//SPIT.
/// All methods are no-ops on devices without a vibrator.
class HapticService {
  /// Fire once on false→true lock acquisition.
  Future<void> onLockAcquired() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('[HapticService] heavyImpact failed: $e');
    }
  }

  /// Optional: fire once on true→false lock loss (A-tier).
  Future<void> onLockLost() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('[HapticService] lightImpact failed: $e');
    }
  }

  /// Confirmation pulse on launch.
  Future<void> onLaunch() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('[HapticService] launch haptic failed: $e');
    }
  }
}
