import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/score_record.dart';

class SupabaseService {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  bool _initialized = false;
  bool get isConfigured => _url.isNotEmpty && _publishableKey.isNotEmpty;

  Future<bool> initialize() async {
    if (!isConfigured) return false;
    if (_initialized) return true;
    try {
      await Supabase.initialize(
        url: _url,
        publishableKey: _publishableKey,
      );
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> submit(ScoreRecord record, String playerId) async {
    if (!await initialize()) throw StateError('Supabase is not configured');
    final client = Supabase.instance.client;

    await client.from('scores').insert({
      'player_id': playerId,
      'score': record.score,
      'accuracy': record.confidence,
      'event_detected': record.eventDetected,
      'created_at': record.createdAt.toIso8601String(),
    });
  }
}
