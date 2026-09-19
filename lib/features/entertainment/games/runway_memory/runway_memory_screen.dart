import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../instructions.dart';

class _Card {
  _Card({required this.pairId, required this.icon, required this.label});
  final int pairId;
  final IconData icon;
  final String label;
  bool faceUp = false;
  bool matched = false;
}

class RunwayMemoryScreen extends StatefulWidget {
  const RunwayMemoryScreen({super.key});

  @override
  State<RunwayMemoryScreen> createState() => _RunwayMemoryScreenState();
}

class _RunwayMemoryScreenState extends State<RunwayMemoryScreen> {
  static const _pairs = <(IconData, String)>[
    (Icons.flight_rounded, 'Jet'),
    (Icons.cloud_rounded, 'Cloud'),
    (Icons.radar_rounded, 'Radar'),
    (Icons.luggage_rounded, 'Bag'),
    (Icons.headset_mic_rounded, 'ATC'),
    (Icons.local_airport_rounded, 'Tower'),
  ];

  late List<_Card> _cards;
  int? _first;
  bool _locked = false;
  int _moves = 0;
  int _best = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _deal();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final best = await LocalStore.instance.runwayMemoryBest();
    if (!mounted) return;
    setState(() => _best = best);
  }

  void _deal() {
    final deck = <_Card>[];
    for (var i = 0; i < _pairs.length; i++) {
      final p = _pairs[i];
      deck.add(_Card(pairId: i, icon: p.$1, label: p.$2));
      deck.add(_Card(pairId: i, icon: p.$1, label: p.$2));
    }
    deck.shuffle(math.Random());
    _cards = deck;
    _first = null;
    _locked = false;
    _moves = 0;
    _won = false;
  }

  Future<void> _flip(int index) async {
    if (_locked || _won) return;
    final card = _cards[index];
    if (card.faceUp || card.matched) return;

    setState(() => card.faceUp = true);

    if (_first == null) {
      _first = index;
      return;
    }

    _locked = true;
    _moves++;
    final a = _cards[_first!];
    final b = card;

    if (a.pairId == b.pairId) {
      a.matched = true;
      b.matched = true;
      _first = null;
      _locked = false;
      if (_cards.every((c) => c.matched)) {
        _won = true;
        await LocalStore.instance.recordRunwayMemoryScore(_moves);
        final best = await LocalStore.instance.runwayMemoryBest();
        if (mounted) setState(() => _best = best);
      } else {
        setState(() {});
      }
    } else {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        a.faceUp = false;
        b.faceUp = false;
        _first = null;
        _locked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12100A),
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
                      'RUNWAY MEMORY',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Instructions',
                    onPressed: () => showActivityInstructions(
                      context,
                      title: 'Runway Memory',
                      body: kGameInstructions['runway_memory']!,
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    color: Colors.white70,
                  ),
                  Text(
                    'Moves $_moves',
                    style: GoogleFonts.sora(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (_best > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Best clear: $_best moves',
                  style: GoogleFonts.sora(
                    color: const Color(0xFFC9A227),
                    fontSize: 12.5,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GridView.builder(
                  itemCount: _cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, i) {
                    final c = _cards[i];
                    final show = c.faceUp || c.matched;
                    return GestureDetector(
                      onTap: () => _flip(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: show
                              ? (c.matched
                                    ? const Color(0xFF2A4A20)
                                    : const Color(0xFF2A2418))
                              : const Color(0xFF1A2F8C),
                          border: Border.all(
                            color: show
                                ? const Color(0xFFC9A227)
                                : Colors.white24,
                          ),
                        ),
                        child: Center(
                          child: show
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(c.icon, color: const Color(0xFFC9A227), size: 28),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.label,
                                      style: GoogleFonts.sora(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                )
                              : Icon(
                                  Icons.flight_takeoff_rounded,
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_won)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    Text(
                      'All pairs matched',
                      style: GoogleFonts.fraunces(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => setState(_deal),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                      ),
                      child: Text(
                        'Deal again',
                        style: GoogleFonts.sora(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
