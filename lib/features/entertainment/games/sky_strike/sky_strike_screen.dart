import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../instructions.dart';
import 'sky_strike_engine.dart';
import 'sky_strike_painter.dart';

class SkyStrikeScreen extends StatefulWidget {
  const SkyStrikeScreen({super.key});

  @override
  State<SkyStrikeScreen> createState() => _SkyStrikeScreenState();
}

class _SkyStrikeScreenState extends State<SkyStrikeScreen>
    with SingleTickerProviderStateMixin {
  late final SkyStrikeEngine _engine;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _blink = false;
  double _blinkT = 0;

  @override
  void initState() {
    super.initState();
    _engine = SkyStrikeEngine(width: 360, height: 640);
    _loadHighScore();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _loadHighScore() async {
    final best = await LocalStore.instance.skyStrikeHighScore();
    if (!mounted) return;
    setState(() => _engine.highScore = best);
  }

  Future<void> _persistHighScore() async {
    await LocalStore.instance.recordSkyStrikeScore(_engine.score);
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final wasPlaying = _engine.phase == SkyStrikePhase.playing;
    _engine.update(dt);
    if (wasPlaying && _engine.phase == SkyStrikePhase.gameOver) {
      _persistHighScore();
    }
    _blinkT += dt;
    if (_blinkT > 0.12) {
      _blinkT = 0;
      _blink = !_blink;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onPan(DragUpdateDetails d, BoxConstraints box) {
    _engine.movePlayerTo(d.localPosition.dx);
  }

  void _onTapDown(TapDownDetails d) {
    if (_engine.phase == SkyStrikePhase.ready ||
        _engine.phase == SkyStrikePhase.gameOver) {
      _engine.start();
      return;
    }
    _engine.movePlayerTo(d.localPosition.dx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07122E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      'SKY STRIKE',
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
                      title: 'Sky Strike',
                      body: kGameInstructions['sky_strike']!,
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    color: Colors.white70,
                  ),
                  IconButton(
                    tooltip: 'Pause',
                    onPressed: () {
                      if (_engine.phase == SkyStrikePhase.playing ||
                          _engine.phase == SkyStrikePhase.paused) {
                        setState(_engine.togglePause);
                      }
                    },
                    icon: Icon(
                      _engine.phase == SkyStrikePhase.paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _HudChip(label: 'SCORE', value: '${_engine.score}'),
                  const SizedBox(width: 10),
                  _HudChip(label: 'BEST', value: '${_engine.highScore}'),
                  const SizedBox(width: 10),
                  _HudChip(label: 'WAVE', value: '${_engine.wave}'),
                  const Spacer(),
                  Row(
                    children: List.generate(3, (i) {
                      final on = i < _engine.lives;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: on
                              ? const Color(0xFFFF6B6B)
                              : Colors.white24,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _engine.resize(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: _onTapDown,
                        onPanUpdate: (d) => _onPan(d, constraints),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: SkyStrikePainter(
                                engine: _engine,
                                blink: _blink,
                              ),
                            ),
                            if (_engine.phase == SkyStrikePhase.ready)
                              _OverlayCard(
                                title: 'Sky Strike',
                                body:
                                    'Drag to fly. Your jet auto-fires.\n'
                                    'Survive waves of hostile aircraft.',
                                action: 'Tap to launch',
                              ),
                            if (_engine.phase == SkyStrikePhase.paused)
                              const _OverlayCard(
                                title: 'Paused',
                                body: 'Sky is holding. Resume when ready.',
                                action: 'Tap play above',
                              ),
                            if (_engine.phase == SkyStrikePhase.gameOver)
                              _OverlayCard(
                                title: 'Shot down',
                                body:
                                    'Score ${_engine.score} · Best ${_engine.highScore}',
                                action: 'Tap to fly again',
                              ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Row(
                                children: [
                                  _MoveButton(
                                    icon: Icons.chevron_left_rounded,
                                    onPressed: () => _engine.nudge(-28),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Drag or use arrows',
                                    style: GoogleFonts.sora(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  _MoveButton(
                                    icon: Icons.chevron_right_rounded,
                                    onPressed: () => _engine.nudge(28),
                                  ),
                                ],
                              ),
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

class _HudChip extends StatelessWidget {
  const _HudChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sora(
              color: Colors.white54,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.sora(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({
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
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xE0122268),
            border: Border.all(
              color: AppColors.brandBlueSoft.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                action.toUpperCase(),
                style: GoogleFonts.sora(
                  color: AppColors.brandBlueSoft,
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 52,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
