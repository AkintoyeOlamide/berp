import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../instructions.dart';

enum _Phase { ready, playing, gameOver }

class _Obstacle {
  _Obstacle({required this.x, required this.y, required this.w, required this.h});
  double x;
  double y;
  double w;
  double h;
}

class JetDodgeScreen extends StatefulWidget {
  const JetDodgeScreen({super.key});

  @override
  State<JetDodgeScreen> createState() => _JetDodgeScreenState();
}

class _JetDodgeScreenState extends State<JetDodgeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final _rng = math.Random();

  _Phase _phase = _Phase.ready;
  double _lane = 0.5; // 0..1
  double _score = 0;
  int _best = 0;
  double _speed = 220;
  double _spawn = 0.6;
  final List<_Obstacle> _obs = [];
  Size _size = const Size(360, 640);

  @override
  void initState() {
    super.initState();
    _loadBest();
    _ticker = createTicker(_tick)..start();
  }

  Future<void> _loadBest() async {
    final best = await LocalStore.instance.jetDodgeHighScore();
    if (!mounted) return;
    setState(() => _best = best);
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_phase != _Phase.playing) {
      setState(() {});
      return;
    }

    _score += dt * 10;
    _speed = 220 + _score * 1.2;
    _spawn -= dt;
    if (_spawn <= 0) {
      final w = 48 + _rng.nextDouble() * 70;
      _obs.add(
        _Obstacle(
          x: _rng.nextDouble() * (_size.width - w),
          y: -40,
          w: w,
          h: 22 + _rng.nextDouble() * 18,
        ),
      );
      _spawn = math.max(0.35, 0.95 - _score / 400);
    }

    for (final o in _obs) {
      o.y += _speed * dt;
    }
    _obs.removeWhere((o) => o.y > _size.height + 40);

    final px = _lane * (_size.width - 36) + 18;
    const py = 0.78;
    final playerY = _size.height * py;
    for (final o in _obs) {
      if ((px - (o.x + o.w / 2)).abs() < (36 + o.w) / 2 &&
          (playerY - (o.y + o.h / 2)).abs() < (28 + o.h) / 2) {
        _phase = _Phase.gameOver;
        final scoreInt = _score.floor();
        _best = math.max(_best, scoreInt);
        LocalStore.instance.recordJetDodgeScore(scoreInt);
        break;
      }
    }
    setState(() {});
  }

  void _start() {
    _obs.clear();
    _score = 0;
    _speed = 220;
    _spawn = 0.5;
    _lane = 0.5;
    _phase = _Phase.playing;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      'JET DODGE',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Instructions',
                    onPressed: () => showActivityInstructions(
                      context,
                      title: 'Jet Dodge',
                      body: kGameInstructions['jet_dodge']!,
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    color: Colors.white70,
                  ),
                  Text(
                    '${_score.floor()}',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      _size = Size(c.maxWidth, c.maxHeight);
                      final px = _lane * (_size.width - 36) + 18;
                      final py = _size.height * 0.78;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_phase != _Phase.playing) _start();
                        },
                        onPanUpdate: (d) {
                          if (_phase != _Phase.playing) return;
                          setState(() {
                            _lane = (d.localPosition.dx / _size.width)
                                .clamp(0.0, 1.0);
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF0B1C38),
                                    Color(0xFF1A3A6A),
                                    Color(0xFF2E6B9A),
                                  ],
                                ),
                              ),
                            ),
                            ..._obs.map(
                              (o) => Positioned(
                                left: o.x,
                                top: o.y,
                                child: Container(
                                  width: o.w,
                                  height: o.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x66FFFFFF),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: px - 18,
                              top: py - 18,
                              child: Transform.rotate(
                                angle: -math.pi / 2,
                                child: const Icon(
                                  Icons.flight_rounded,
                                  color: Color(0xFF6B92FF),
                                  size: 36,
                                ),
                              ),
                            ),
                            if (_phase == _Phase.ready)
                              _Banner(
                                title: 'Jet Dodge',
                                body: 'Drag left and right to weave through clouds.',
                                action: 'Tap to start',
                              ),
                            if (_phase == _Phase.gameOver)
                              _Banner(
                                title: 'Turbulence',
                                body:
                                    'Distance ${_score.floor()} · Best $_best',
                                action: 'Tap to retry',
                              ),
                          ],
                        ),
                      );
                    },
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

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xE00A1A2E),
            border: Border.all(
              color: AppColors.brandBlueSoft.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.fraunces(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(color: Colors.white70, fontSize: 13.5),
              ),
              const SizedBox(height: 14),
              Text(
                action.toUpperCase(),
                style: GoogleFonts.sora(
                  color: AppColors.brandBlueSoft,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
