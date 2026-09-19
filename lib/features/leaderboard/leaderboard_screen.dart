import 'package:flutter/material.dart';

import '../../core/data/leaderboard_service.dart';
import '../../core/data/local_store.dart';
import '../../core/widgets/pattern_page.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _gameId = LeaderboardService.games.first.$1;
  List<LeaderboardEntry> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final store = LocalStore.instance;
    await LeaderboardService.seedFromLocalBests({
      'sky_strike': await store.skyStrikeHighScore(),
      'jet_dodge': await store.jetDodgeHighScore(),
      'cloud_hop': await store.cloudHopHighScore(),
      'tower_call': await store.towerCallHighScore(),
      'runway_memory': await store.runwayMemoryBest(),
      'quiz': await store.bestQuizScore(),
    });
    final rows = await LeaderboardService.ranks(_gameId);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  bool get _higher =>
      LeaderboardService.games.firstWhere((g) => g.$1 == _gameId).$3;

  String _scoreLabel(int score) {
    if (_gameId == 'runway_memory') return '$score moves';
    return '$score pts';
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Entertainment > Leaderboard',
      title: 'Leaderboard',
      titleSize: 18,
      subtitle: 'CABIN RANKS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final g in LeaderboardService.games)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: g.$2,
                      selected: _gameId == g.$1,
                      onTap: () {
                        setState(() => _gameId = g.$1);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _higher ? 'Highest score ranks first' : 'Fewest moves ranks first',
            style: PatternPage.body(size: 11.5, color: PatternPage.muted),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: CircularProgressIndicator(color: PatternPage.blue),
              ),
            )
          else if (_rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'No ranks yet. Play a round and your score posts here.',
                style: PatternPage.body(size: 13, color: PatternPage.muted),
              ),
            )
          else
            for (var i = 0; i < _rows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RankRow(
                  rank: i + 1,
                  entry: _rows[i],
                  scoreLabel: _scoreLabel(_rows[i].score),
                ),
              ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PatternPage.blue.withValues(alpha: 0.35)
          : const Color(0xFF121212),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? PatternPage.blue.withValues(alpha: 0.55)
                  : PatternPage.divider,
            ),
          ),
          child: Text(
            label,
            style: PatternPage.body(
              size: 11.5,
              weight: FontWeight.w500,
              color: selected ? Colors.white : PatternPage.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.entry,
    required this.scoreLabel,
  });

  final int rank;
  final LeaderboardEntry entry;
  final String scoreLabel;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => const Color(0xFFC9A227),
      2 => const Color(0xFFB8B8BD),
      3 => const Color(0xFFB87333),
      _ => PatternPage.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isYou
            ? PatternPage.blue.withValues(alpha: 0.16)
            : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isYou
              ? PatternPage.blue.withValues(alpha: 0.45)
              : PatternPage.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: PatternPage.panchang(
                size: 13,
                weight: FontWeight.w700,
                color: medal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.isYou ? '${entry.playerName} (you)' : entry.playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PatternPage.body(size: 13, weight: FontWeight.w500),
            ),
          ),
          Text(
            scoreLabel,
            style: PatternPage.body(
              size: 12.5,
              weight: FontWeight.w600,
              color: PatternPage.blue,
            ),
          ),
        ],
      ),
    );
  }
}
