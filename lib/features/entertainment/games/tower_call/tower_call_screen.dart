import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../instructions.dart';

class TowerCallScreen extends StatefulWidget {
  const TowerCallScreen({super.key});

  @override
  State<TowerCallScreen> createState() => _TowerCallScreenState();
}

class _TowerCallScreenState extends State<TowerCallScreen> {
  static const _labels = ['Alpha', 'Bravo', 'Charlie', 'Delta'];
  static const _colors = [
    Color(0xFF4D78FF),
    Color(0xFF3DBF9A),
    Color(0xFFC9A227),
    Color(0xFFFF6B6B),
  ];

  final _rng = math.Random();
  final List<int> _sequence = [];
  int _step = 0;
  int _score = 0;
  int _best = 0;
  bool _listening = false;
  bool _playing = false;
  bool _gameOver = false;
  int? _lit;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final best = await LocalStore.instance.towerCallHighScore();
    if (!mounted) return;
    setState(() => _best = best);
  }

  Future<void> _start() async {
    _sequence.clear();
    _score = 0;
    _gameOver = false;
    _listening = false;
    await _nextRound();
  }

  Future<void> _nextRound() async {
    _sequence.add(_rng.nextInt(4));
    _step = 0;
    _listening = false;
    setState(() => _playing = true);
    await _playback();
    if (!mounted) return;
    setState(() {
      _playing = false;
      _listening = true;
    });
  }

  Future<void> _playback() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (final i in _sequence) {
      if (!mounted) return;
      setState(() => _lit = i);
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      setState(() => _lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }
  }

  Future<void> _press(int i) async {
    if (!_listening || _gameOver) return;
    setState(() => _lit = i);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() => _lit = null);

    if (i != _sequence[_step]) {
      setState(() {
        _gameOver = true;
        _listening = false;
        _best = math.max(_best, _score);
      });
      await LocalStore.instance.recordTowerCallScore(_score);
      return;
    }

    _step++;
    if (_step >= _sequence.length) {
      _score++;
      setState(() => _listening = false);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _nextRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1218),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      'TOWER CALL',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Instructions',
                    onPressed: () => showActivityInstructions(
                      context,
                      title: 'Tower Call',
                      body: kGameInstructions['tower_call']!,
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    color: Colors.white70,
                  ),
                  Text(
                    '$_score',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _gameOver
                  ? 'Missed call · Best $_best'
                  : _playing
                      ? 'Tower transmitting…'
                      : _listening
                          ? 'Your turn — repeat the sequence'
                          : 'Copy the tower sequence',
              style: GoogleFonts.sora(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  itemCount: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, i) {
                    final on = _lit == i;
                    return GestureDetector(
                      onTap: () => _press(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: on
                              ? _colors[i]
                              : _colors[i].withValues(alpha: 0.28),
                          border: Border.all(
                            color: _colors[i].withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _labels[i],
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _playing ? null : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                  ),
                  child: Text(
                    _sequence.isEmpty || _gameOver ? 'Contact tower' : 'Restart',
                    style: GoogleFonts.sora(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
