import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/score_record.dart';

class LocalScoreStore {
  static const _historyKey = 'safespit.score_history';
  static const _pendingKey = 'safespit.pending_scores';

  Future<void> save(ScoreRecord record) async {
    final preferences = await SharedPreferences.getInstance();
    final history = await _read(preferences, _historyKey);
    final pending = await _read(preferences, _pendingKey);
    history.removeWhere((item) => item.id == record.id);
    pending.removeWhere((item) => item.id == record.id);
    history.add(record);
    pending.add(record);
    await preferences.setString(_historyKey, _encode(history));
    await preferences.setString(_pendingKey, _encode(pending));
  }

  Future<List<ScoreRecord>> pending() async {
    final preferences = await SharedPreferences.getInstance();
    return _read(preferences, _pendingKey);
  }

  Future<void> markSynced(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final pending = await _read(preferences, _pendingKey);
    pending.removeWhere((item) => item.id == id);
    await preferences.setString(_pendingKey, _encode(pending));
  }

  Future<List<ScoreRecord>> history() async {
    final preferences = await SharedPreferences.getInstance();
    return _read(preferences, _historyKey);
  }

  Future<List<ScoreRecord>> _read(
    SharedPreferences preferences,
    String key,
  ) async {
    final raw = preferences.getString(key);
    if (raw == null) return [];
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return values
          .map((value) => ScoreRecord.fromJson(value as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _encode(List<ScoreRecord> records) => jsonEncode(
        records.map((record) => record.toJson()).toList(),
      );
}
