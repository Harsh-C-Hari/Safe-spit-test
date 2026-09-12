import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player_profile.dart';

class PlayerService extends ChangeNotifier {
  SupabaseClient? _supabase;
  SharedPreferences? _prefs;

  PlayerProfile? _currentProfile;
  bool _isInitialized = false;

  PlayerService({SupabaseClient? supabase}) {
    if (supabase != null) {
      _supabase = supabase;
    } else {
      try {
        _supabase = Supabase.instance.client;
      } catch (_) {
        _supabase = null;
      }
    }
  }

  bool get isInitialized => _isInitialized;
  PlayerProfile? get currentProfile => _currentProfile;

  bool get isOnboardingComplete {
    return _prefs?.getBool('onboarding_complete') ?? false;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();

    await _loadLocalProfile();
    await _ensureAuth();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadLocalProfile() async {
    final profileJson = _prefs?.getString('player_profile');
    if (profileJson != null) {
      try {
        _currentProfile = PlayerProfile.fromJson(jsonDecode(profileJson));
      } catch (e) {
        debugPrint('Failed to parse local profile: $e');
      }
    }
  }

  Future<void> _saveLocalProfile() async {
    if (_currentProfile != null) {
      await _prefs?.setString('player_profile', jsonEncode(_currentProfile!.toJson()));
    } else {
      await _prefs?.remove('player_profile');
    }
    notifyListeners();
  }

  Future<void> _ensureAuth() async {
    try {
      final session = _supabase?.auth.currentSession ??
          (await _supabase?.auth.signInAnonymously())?.session;
      final playerId = session?.user.id;

      if (playerId != null && _currentProfile?.id != playerId) {
        // If we have a new ID or no local profile, set it up
        _currentProfile = PlayerProfile(
          id: playerId,
          displayName: _currentProfile?.displayName ?? 'PLAYER',
          bestScore: _currentProfile?.bestScore ?? 0.0,
          totalScore: _currentProfile?.totalScore ?? 0.0,
          gamesPlayed: _currentProfile?.gamesPlayed ?? 0,
        );
        await _saveLocalProfile();
        // Try fetching remote profile
        await _syncProfileFromRemote();
      }
    } catch (e) {
      debugPrint('Auth initialization failed: $e');
    }

    if (_currentProfile == null) {
      _currentProfile = PlayerProfile(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'OPERATOR',
      );
      await _saveLocalProfile();
    }
  }

  Future<void> _syncProfileFromRemote() async {
    if (_supabase == null || _currentProfile == null) return;
    try {
      final data = await _supabase!.from('players').select().eq('id', _currentProfile!.id).maybeSingle();
      if (data != null) {
        _currentProfile = PlayerProfile.fromJson(data);
        await _saveLocalProfile();
      } else {
        // Remote doesn't exist, create it
        await _syncProfileToRemote();
      }
    } catch (e) {
      debugPrint('Failed to sync profile from remote: $e');
    }
  }

  Future<void> _syncProfileToRemote() async {
    if (_supabase == null || _currentProfile == null) return;
    try {
      final data = _currentProfile!.toJson();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _supabase!.from('players').upsert(data);
    } catch (e) {
      debugPrint('Failed to sync profile to remote: $e');
    }
  }

  Future<void> completeOnboarding(String displayName) async {
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(displayName: displayName);
      await _saveLocalProfile();
      await _syncProfileToRemote();
    }
    await _prefs?.setBool('onboarding_complete', true);
    notifyListeners();
  }

  Future<void> updateDisplayName(String newName) async {
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(displayName: newName);
      await _saveLocalProfile();
      await _syncProfileToRemote();
    }
  }

  Future<void> incrementStats(double score) async {
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(
        bestScore: score > _currentProfile!.bestScore ? score : _currentProfile!.bestScore,
        totalScore: _currentProfile!.totalScore + score,
        gamesPlayed: _currentProfile!.gamesPlayed + 1,
      );
      await _saveLocalProfile();
      await _syncProfileToRemote();
    }
  }

  Future<void> resetLocalData() async {
    await _prefs?.clear();
    _currentProfile = null;
    _isInitialized = false;
    notifyListeners();
  }
}
