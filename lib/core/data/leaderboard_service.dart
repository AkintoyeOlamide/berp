import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.gameId,
    required this.playerName,
    required this.score,
    this.isYou = false,
  });

  final String gameId;
  final String playerName;
  final int score;
  final bool isYou;
}

/// Cabin game ranks. Tries Supabase `game_scores`, then this device.
abstract final class LeaderboardService {
  static const table = 'game_scores';
  static const _localKey = 'game_scores_local';
  static const _seededKey = 'game_scores_seeded';
  static const _guestKey = 'guest_player_name';

  static String? _guestName;

  static const games = <(String id, String label, bool higherIsBetter)>[
    ('sky_strike', 'Sky Strike', true),
    ('jet_dodge', 'Jet Dodge', true),
    ('cloud_hop', 'Cloud Hop', true),
    ('tower_call', 'Tower Call', true),
    ('runway_memory', 'Runway Memory', false),
    ('quiz', 'Quiz', true),
  ];

  static bool get hasGuestName => (_guestName ?? '').trim().isNotEmpty;

  static Future<void> loadGuestName() async {
    if (_guestName != null) return;
    final prefs = await SharedPreferences.getInstance();
    _guestName = prefs.getString(_guestKey);
  }

  static Future<void> setGuestName(String name) async {
    _guestName = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestKey, _guestName!);
  }

  static String playerName() {
    final user = AuthService.currentUser;
    final meta = user?.userMetadata;
    final raw = (meta?['full_name'] ?? meta?['name'])?.toString().trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    final guest = _guestName?.trim();
    if (guest != null && guest.isNotEmpty) return guest;
    return 'Cabin guest';
  }

  /// Posts existing device high scores once so older plays show on ranks.
  static Future<void> seedFromLocalBests(Map<String, int> scores) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) ?? false) return;
    for (final e in scores.entries) {
      if (e.value > 0) {
        await submit(gameId: e.key, score: e.value);
      }
    }
    await prefs.setBool(_seededKey, true);
  }

  static Future<void> submit({
    required String gameId,
    required int score,
  }) async {
    await loadGuestName();
    await _saveLocal(gameId: gameId, score: score);
    try {
      await AuthService.client.from(table).insert({
        'game_id': gameId,
        'player_name': playerName(),
        'score': score,
        'user_id': AuthService.currentUser?.id,
      });
    } catch (_) {
      // Table / RLS may not be set yet — local ranks still work.
    }
  }

  static Future<List<LeaderboardEntry>> ranks(String gameId) async {
    await loadGuestName();
    final higher = games.firstWhere((g) => g.$1 == gameId).$3;
    final remote = await _fetchRemote(gameId, higher: higher);
    if (remote.isNotEmpty) return remote;
    return _localRanks(gameId, higher: higher);
  }

  static Future<List<LeaderboardEntry>> _fetchRemote(
    String gameId, {
    required bool higher,
  }) async {
    try {
      final rows = await AuthService.client
          .from(table)
          .select('player_name, score, user_id')
          .eq('game_id', gameId)
          .order('score', ascending: !higher)
          .limit(25);
      final me = AuthService.currentUser?.id;
      final name = playerName();
      return [
        for (final row in (rows as List<dynamic>))
          LeaderboardEntry(
            gameId: gameId,
            playerName: row['player_name']?.toString() ?? 'Player',
            score: (row['score'] as num?)?.toInt() ?? 0,
            isYou: (me != null && row['user_id'] == me) ||
                row['player_name']?.toString() == name,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _saveLocal({
    required String gameId,
    required int score,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _readLocal(prefs);
    list.add({
      'game_id': gameId,
      'player_name': playerName(),
      'score': score,
    });
    await prefs.setString(_localKey, jsonEncode(list));
  }

  static List<Map<String, dynamic>> _readLocal(SharedPreferences prefs) {
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .cast<Map<dynamic, dynamic>>()
        .map((m) => m.map((k, v) => MapEntry('$k', v)))
        .toList();
  }

  static Future<List<LeaderboardEntry>> _localRanks(
    String gameId, {
    required bool higher,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final mine = playerName();
    final rows = _readLocal(prefs)
        .where((e) => e['game_id'] == gameId)
        .toList();
    final bestByName = <String, int>{};
    for (final row in rows) {
      final name = row['player_name']?.toString() ?? mine;
      final score = (row['score'] as num?)?.toInt() ?? 0;
      final current = bestByName[name];
      if (current == null ||
          (higher && score > current) ||
          (!higher && score < current)) {
        bestByName[name] = score;
      }
    }
    final entries = [
      for (final e in bestByName.entries)
        LeaderboardEntry(
          gameId: gameId,
          playerName: e.key,
          score: e.value,
          isYou: e.key == mine,
        ),
    ];
    entries.sort((a, b) => higher ? b.score.compareTo(a.score) : a.score.compareTo(b.score));
    return entries.take(25).toList();
  }
}
