import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'leaderboard_service.dart';
import 'trip.dart';

/// Offline-first local store for quiz progress, badges, and session hints.
/// Content sync / Supabase auth will plug in here when credentials are ready.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const _quizBestKey = 'quiz_best_score';
  static const _quizAttemptsKey = 'quiz_attempts';
  static const _badgesKey = 'unlocked_badges';
  static const _sessionEmailKey = 'portal_session_email';
  static const _themeModeKey = 'theme_mode';
  static const _fontScaleKey = 'font_scale';
  static const _skyStrikeBestKey = 'sky_strike_best';
  static const _jetDodgeBestKey = 'jet_dodge_best';
  static const _runwayMemoryBestKey = 'runway_memory_best';
  static const _cloudHopBestKey = 'cloud_hop_best';
  static const _towerCallBestKey = 'tower_call_best';
  static const _triviaReadKey = 'trivia_read_count';
  static const _tripsKey = 'trips_json';
  static const _tripsSeededKey = 'trips_seeded';

  Future<ThemeMode> themeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await prefs.setString(_themeModeKey, value);
  }

  Future<double> fontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontScaleKey) ?? 1.0;
  }

  Future<void> setFontScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
  }

  Future<int> bestQuizScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_quizBestKey) ?? 0;
  }

  Future<int> quizAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_quizAttemptsKey) ?? 0;
  }

  Future<void> recordQuizScore(int score, {required int total}) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_quizBestKey) ?? 0;
    if (score > best) await prefs.setInt(_quizBestKey, score);
    final attempts = prefs.getInt(_quizAttemptsKey) ?? 0;
    await prefs.setInt(_quizAttemptsKey, attempts + 1);

    final badges = prefs.getStringList(_badgesKey) ?? <String>[];
    void unlock(String id) {
      if (!badges.contains(id)) badges.add(id);
    }

    unlock('first_quiz');
    if (score >= (total * 0.7).ceil()) unlock('sky_scholar');
    if (score >= total) unlock('perfect');
    await prefs.setStringList(_badgesKey, badges);
    if (score > 0) {
      LeaderboardService.submit(gameId: 'quiz', score: score);
    }
  }

  Future<void> unlockBadge(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final badges = prefs.getStringList(_badgesKey) ?? <String>[];
    if (!badges.contains(id)) {
      badges.add(id);
      await prefs.setStringList(_badgesKey, badges);
    }
  }

  Future<void> markTriviaRead() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_triviaReadKey) ?? 0) + 1;
    await prefs.setInt(_triviaReadKey, count);
    if (count >= 3) await unlockBadge('trivia');
  }

  Future<Set<String>> unlockedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_badgesKey) ?? <String>[]).toSet();
  }

  Future<void> savePortalSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, email);
  }

  Future<String?> portalSessionEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionEmailKey);
  }

  Future<void> clearPortalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
  }

  Future<int> skyStrikeHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_skyStrikeBestKey) ?? 0;
  }

  Future<void> recordSkyStrikeScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_skyStrikeBestKey) ?? 0;
    if (score > best) await prefs.setInt(_skyStrikeBestKey, score);
    if (score >= 100) await unlockBadge('sky_ace');
    if (score > 0) {
      LeaderboardService.submit(gameId: 'sky_strike', score: score);
    }
  }

  Future<int> jetDodgeHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_jetDodgeBestKey) ?? 0;
  }

  Future<void> recordJetDodgeScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_jetDodgeBestKey) ?? 0;
    if (score > best) await prefs.setInt(_jetDodgeBestKey, score);
    if (score >= 80) await unlockBadge('smooth_air');
    if (score > 0) {
      LeaderboardService.submit(gameId: 'jet_dodge', score: score);
    }
  }

  Future<int> runwayMemoryBest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_runwayMemoryBestKey) ?? 0;
  }

  Future<void> recordRunwayMemoryScore(int moves) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_runwayMemoryBestKey) ?? 0;
    if (best == 0 || moves < best) {
      await prefs.setInt(_runwayMemoryBestKey, moves);
    }
    await unlockBadge('memory_pilot');
    LeaderboardService.submit(gameId: 'runway_memory', score: moves);
  }

  Future<int> cloudHopHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cloudHopBestKey) ?? 0;
  }

  Future<void> recordCloudHopScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_cloudHopBestKey) ?? 0;
    if (score > best) await prefs.setInt(_cloudHopBestKey, score);
    if (score >= 8) await unlockBadge('cloud_rider');
    if (score > 0) {
      LeaderboardService.submit(gameId: 'cloud_hop', score: score);
    }
  }

  Future<int> towerCallHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_towerCallBestKey) ?? 0;
  }

  Future<void> recordTowerCallScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_towerCallBestKey) ?? 0;
    if (score > best) await prefs.setInt(_towerCallBestKey, score);
    if (score >= 5) await unlockBadge('tower_copy');
    if (score > 0) {
      LeaderboardService.submit(gameId: 'tower_call', score: score);
    }
  }

  Future<List<Trip>> trips() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_tripsSeededKey) ?? false)) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final seeded = Trip(
        id: 'seed-kteb-ksan',
        originCode: 'KTEB',
        originName: 'Teterboro Airport',
        destCode: 'KSAN',
        destName: 'San Diego Intl.',
        departLabel: 'Depart 10:00 AM',
        arriveLabel: 'Arrive Est. 1:00 PM',
        dateTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10),
        tailNumber: 'N313JD',
        aircraftId: '',
        passengerCount: 6,
      );
      await prefs.setString(_tripsKey, jsonEncode([seeded.toMap()]));
      await prefs.setBool(_tripsSeededKey, true);
      return [seeded];
    }
    final raw = prefs.getString(_tripsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<dynamic, dynamic>>()
        .map(
          (m) => Trip.fromMap(
            m.map((k, v) => MapEntry(k.toString(), v.toString())),
          ),
        )
        .toList();
    return list;
  }

  Future<void> saveTrip(Trip trip) async {
    final current = await trips();
    current.insert(0, trip);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tripsKey,
      jsonEncode(current.map((t) => t.toMap()).toList()),
    );
    await prefs.setBool(_tripsSeededKey, true);
  }
}
