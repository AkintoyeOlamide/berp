import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../instructions.dart';

enum _Phase { ready, playing, gameOver }

class _Gate {
  _Gate(this.x, this.gapY, this.gapH);
  double x;
  double gapY;
  double gapH;
}

class CloudHopScreen extends StatefulWidget {
  const CloudHopScreen({super.key});

  @override
  State<CloudHopScreen> createState() => _CloudHopScreenState();
}

class _CloudHopScreenState extends State<CloudHopScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final _rng = math.Random();

  _Phase _phase = _Phase.ready;
  double _y = 0.5;
  double _vy = 0;
  double _score = 0;
  int _best = 0;
  Size _size = const Size(360, 640);
  final List<_Gate> _gates = [];
  double _spawn = 0;

  static const _gravity = 980.0;
  static const _flap = -340.0;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _ticker = createTicker(_tick)..start();
  }

  Future<void> _loadBest() async {
    final best = await LocalStore.instance.cloudHopHighScore();
    if (!mounted) return;
    setState(() => _best = best);
  }

  void _start() {
    _y = 0.45;
    _vy = 0;
    _score = 0;
    _gates
      ..clear()
      ..add(_Gate(_size.width + 40, 0.35, 0.28));
    _spawn = 1.6;
    _phase = _Phase.playing;
  }

  void _flapUp() {
    if (_phase != _Phase.playing) {
      _start();
      return;
    }
    _vy = _flap;
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

    _vy += _gravity * dt;
    _y += (_vy * dt) / _size.height;
    _spawn -= dt;

    final speed = 160 + _score * 3;
    for (final g in _gates) {
      g.x -= speed * dt;
    }
    if (_spawn <= 0) {
      final gapH = math.max(0.22, 0.32 - _score * 0.004);
      final gapY = 0.15 + _rng.nextDouble() * (0.7 - gapH);
      _gates.add(_Gate(_size.width + 20, gapY, gapH));
      _spawn = 1.55;
    }
    _gates.removeWhere((g) => g.x < -60);

    final jetX = _size.width * 0.28;
    final jetY = _y * _size.height;

    if (_y < 0.02 || _y > 0.98) {
      _die();
    } else {
      for (final g in _gates) {
        final inX = (jetX - g.x).abs() < 28;
        final gapTop = g.gapY * _size.height;
        final gapBot = (g.gapY + g.gapH) * _size.height;
        if (inX && (jetY < gapTop + 8 || jetY > gapBot - 8)) {
          _die();
          break;
        }
        if (!inX && g.x + 2 < jetX && g.x + speed * dt + 2 >= jetX) {
          _score += 1;
        }
      }
    }
    setState(() {});
  }

  void _die() {
    _phase = _Phase.gameOver;
    final s = _score.floor();
    _best = math.max(_best, s);
    LocalStore.instance.recordCloudHopScore(s);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1440),
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
                      'CLOUD HOP',
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
                      title: 'Cloud Hop',
                      body: kGameInstructions['cloud_hop']!,
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    color: Colors.white70,
                  ),
                  Text(
                    '${_score.floor()}',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
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
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _flapUp,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF2A1F6A),
                                    Color(0xFF4D78FF),
                                    Color(0xFF8EC5FF),
                                  ],
                                ),
                              ),
                            ),
                            ..._gates.expand((g) {
                              final topH = g.gapY * _size.height;
                              final botTop = (g.gapY + g.gapH) * _size.height;
                              return [
                                Positioned(
                                  left: g.x - 28,
                                  top: 0,
                                  child: _CloudPillar(height: topH),
                                ),
                                Positioned(
                                  left: g.x - 28,
                                  top: botTop,
                                  child: _CloudPillar(
                                    height: _size.height - botTop,
                                  ),
                                ),
                              ];
                            }),
                            Positioned(
                              left: _size.width * 0.28 - 18,
                              top: _y * _size.height - 18,
                              child: Transform.rotate(
                                angle: (_vy / 500).clamp(-0.6, 0.8),
                                child: const Icon(
                                  Icons.flight_rounded,
                                  color: Color(0xFFFFF6D8),
                                  size: 36,
                                ),
                              ),
                            ),
                            if (_phase == _Phase.ready)
                              const _Banner(
                                title: 'Cloud Hop',
                                body: 'Tap to climb. Thread the cloud gaps.',
                                action: 'Tap to fly',
                              ),
                            if (_phase == _Phase.gameOver)
                              _Banner(
                                title: 'Weather stop',
                                body: 'Cleared ${_score.floor()} · Best $_best',
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

class _CloudPillar extends StatelessWidget {
  const _CloudPillar({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: height.clamp(8, 2000),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x55FFFFFF), blurRadius: 12),
        ],
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
            color: const Color(0xE01A1440),
            border: Border.all(
              color: AppColors.brandBlueSoft.withValues(alpha: 0.45),
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
