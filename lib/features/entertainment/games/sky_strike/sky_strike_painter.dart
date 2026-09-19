import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sky_strike_engine.dart';

class SkyStrikePainter extends CustomPainter {
  SkyStrikePainter({required this.engine, required this.blink});

  final SkyStrikeEngine engine;
  final bool blink;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF07122E),
          Color(0xFF122268),
          Color(0xFF1A3A8C),
          Color(0xFF2A5BB0),
        ],
        stops: [0, 0.35, 0.7, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    // Soft horizon glow
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x004D78FF),
            const Color(0x334D78FF),
            const Color(0x556B92FF),
          ],
        ).createShader(
          Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
        ),
    );

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (final s in engine.stars) {
      canvas.drawCircle(Offset(s.x, s.y), s.size, starPaint);
    }

    for (final e in engine.enemies) {
      _drawEnemy(canvas, e);
    }

    for (final b in engine.bullets) {
      final paint = Paint()
        ..color = b.fromPlayer
            ? const Color(0xFFFFF1A8)
            : const Color(0xFFFF6B6B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(b.x, b.y), width: 4, height: 12),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    for (final s in engine.sparks) {
      canvas.drawCircle(
        Offset(s.x, s.y),
        2.2,
        Paint()..color = s.color.withValues(alpha: s.life.clamp(0, 1)),
      );
    }

    if (!(engine.isInvulnerable && blink)) {
      _drawPlayer(canvas, Offset(engine.player.x, engine.player.y));
    }
  }

  void _drawPlayer(Canvas canvas, Offset c) {
    final body = Path()
      ..moveTo(c.dx, c.dy - 22)
      ..lineTo(c.dx + 12, c.dy + 8)
      ..lineTo(c.dx + 4, c.dy + 6)
      ..lineTo(c.dx + 4, c.dy + 18)
      ..lineTo(c.dx - 4, c.dy + 18)
      ..lineTo(c.dx - 4, c.dy + 6)
      ..lineTo(c.dx - 12, c.dy + 8)
      ..close();

    final wing = Path()
      ..moveTo(c.dx - 22, c.dy + 2)
      ..lineTo(c.dx + 22, c.dy + 2)
      ..lineTo(c.dx + 16, c.dy + 10)
      ..lineTo(c.dx - 16, c.dy + 10)
      ..close();

    canvas.drawPath(
      wing,
      Paint()..color = const Color(0xFFE8EEFF),
    );
    canvas.drawPath(
      body,
      Paint()..color = const Color(0xFF6B92FF),
    );
    canvas.drawCircle(
      Offset(c.dx, c.dy - 6),
      3.5,
      Paint()..color = const Color(0xFF1A2F8C),
    );

    // Exhaust glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 22), width: 10, height: 16),
      Paint()
        ..color = const Color(0x88FFB347)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawEnemy(Canvas canvas, Enemy e) {
    final c = Offset(e.x, e.y);
    final color = e.kind == 1
        ? const Color(0xFFFF6B4A)
        : const Color(0xFFFF8A80);
    final scale = e.kind == 1 ? 1.2 : 1.0;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.pi);
    canvas.scale(scale);

    final body = Path()
      ..moveTo(0, -16)
      ..lineTo(10, 10)
      ..lineTo(3, 8)
      ..lineTo(3, 16)
      ..lineTo(-3, 16)
      ..lineTo(-3, 8)
      ..lineTo(-10, 10)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawRect(
      const Rect.fromLTWH(-16, 0, 32, 6),
      Paint()..color = const Color(0xFFE8EEFF),
    );
    canvas.restore();

    if (e.maxHp > 1) {
      final barW = 28.0;
      final ratio = e.hp / e.maxHp;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(e.x, e.y - 28), width: barW, height: 4),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.black45,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(e.x - barW / 2, e.y - 30, barW * ratio, 4),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF6BCB8A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SkyStrikePainter oldDelegate) => true;
}
