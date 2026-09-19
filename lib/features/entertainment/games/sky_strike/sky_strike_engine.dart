import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SkyStrikePhase { ready, playing, paused, gameOver }

class SkyPoint {
  SkyPoint(this.x, this.y);
  double x;
  double y;
}

class Bullet {
  Bullet({required this.x, required this.y, this.fromPlayer = true});
  double x;
  double y;
  final bool fromPlayer;
}

class Enemy {
  Enemy({
    required this.x,
    required this.y,
    required this.speed,
    required this.hp,
    required this.maxHp,
    required this.kind,
    required this.wobble,
  });

  double x;
  double y;
  double speed;
  int hp;
  final int maxHp;
  final int kind; // 0 fighter, 1 bomber
  final double wobble;
  double t = 0;
}

class Spark {
  Spark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
  });

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final Color color;
}

class Star {
  Star({required this.x, required this.y, required this.speed, required this.size});
  double x;
  double y;
  double speed;
  double size;
}

/// Pure Dart game loop for the Sky Strike shooter.
class SkyStrikeEngine {
  SkyStrikeEngine({required this.width, required this.height}) {
    _seedStars();
    reset(keepHighScore: true);
  }

  double width;
  double height;

  final _rng = math.Random();

  SkyStrikePhase phase = SkyStrikePhase.ready;
  int score = 0;
  int highScore = 0;
  int lives = 3;
  int wave = 1;

  late SkyPoint player;
  final List<Bullet> bullets = [];
  final List<Enemy> enemies = [];
  final List<Spark> sparks = [];
  final List<Star> stars = [];

  double _fireCooldown = 0;
  double _spawnCooldown = 0;
  double _invuln = 0;
  double _elapsed = 0;

  static const playerW = 42.0;
  static const playerH = 48.0;

  void resize(double w, double h) {
    width = w;
    height = h;
    player.x = player.x.clamp(playerW / 2, width - playerW / 2);
    player.y = height - 72;
  }

  void _seedStars() {
    stars.clear();
    for (var i = 0; i < 48; i++) {
      stars.add(
        Star(
          x: _rng.nextDouble() * 400,
          y: _rng.nextDouble() * 800,
          speed: 40 + _rng.nextDouble() * 120,
          size: 1 + _rng.nextDouble() * 2.2,
        ),
      );
    }
  }

  void reset({bool keepHighScore = false}) {
    if (!keepHighScore) highScore = math.max(highScore, score);
    score = 0;
    lives = 3;
    wave = 1;
    bullets.clear();
    enemies.clear();
    sparks.clear();
    _fireCooldown = 0;
    _spawnCooldown = 0.4;
    _invuln = 0;
    _elapsed = 0;
    player = SkyPoint(width / 2, height - 72);
    phase = SkyStrikePhase.ready;
  }

  void start() {
    if (phase == SkyStrikePhase.ready || phase == SkyStrikePhase.gameOver) {
      if (phase == SkyStrikePhase.gameOver) reset(keepHighScore: true);
      phase = SkyStrikePhase.playing;
    } else if (phase == SkyStrikePhase.paused) {
      phase = SkyStrikePhase.playing;
    }
  }

  void togglePause() {
    if (phase == SkyStrikePhase.playing) {
      phase = SkyStrikePhase.paused;
    } else if (phase == SkyStrikePhase.paused) {
      phase = SkyStrikePhase.playing;
    }
  }

  void movePlayerTo(double x) {
    if (phase != SkyStrikePhase.playing) return;
    player.x = x.clamp(playerW / 2, width - playerW / 2);
  }

  void nudge(double dx) {
    if (phase != SkyStrikePhase.playing) return;
    player.x = (player.x + dx).clamp(playerW / 2, width - playerW / 2);
  }

  void update(double dt) {
    dt = dt.clamp(0.0, 0.05);
    _scrollStars(dt);

    if (phase != SkyStrikePhase.playing) return;

    _elapsed += dt;
    wave = 1 + (_elapsed / 18).floor();
    if (_invuln > 0) _invuln -= dt;

    _fireCooldown -= dt;
    if (_fireCooldown <= 0) {
      bullets.add(Bullet(x: player.x, y: player.y - playerH / 2));
      _fireCooldown = math.max(0.14, 0.22 - wave * 0.008);
    }

    _spawnCooldown -= dt;
    if (_spawnCooldown <= 0) {
      _spawnEnemy();
      _spawnCooldown = math.max(0.35, 1.1 - wave * 0.07);
    }

    for (final b in bullets) {
      b.y += b.fromPlayer ? -520 * dt : 280 * dt;
    }
    bullets.removeWhere((b) => b.y < -20 || b.y > height + 20);

    for (final e in enemies) {
      e.t += dt;
      e.y += e.speed * dt;
      e.x += math.sin(e.t * 2.2 + e.wobble) * (28 + e.kind * 10) * dt;
      e.x = e.x.clamp(24, width - 24);
    }

    _resolveCombat();
    enemies.removeWhere((e) => e.y > height + 60 || e.hp <= 0);

    for (final s in sparks) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += 180 * dt;
      s.life -= dt;
    }
    sparks.removeWhere((s) => s.life <= 0);

    if (lives <= 0) {
      highScore = math.max(highScore, score);
      phase = SkyStrikePhase.gameOver;
    }
  }

  void _scrollStars(double dt) {
    for (final s in stars) {
      s.y += s.speed * dt;
      if (s.y > height) {
        s.y = -4;
        s.x = _rng.nextDouble() * width;
      }
    }
  }

  void _spawnEnemy() {
    final bomber = _rng.nextDouble() < 0.22 + wave * 0.02;
    final hp = bomber ? 3 + (wave ~/ 3) : 1 + (wave ~/ 4);
    enemies.add(
      Enemy(
        x: 30 + _rng.nextDouble() * (width - 60),
        y: -40,
        speed: (bomber ? 70.0 : 110.0) + wave * 8 + _rng.nextDouble() * 30,
        hp: hp,
        maxHp: hp,
        kind: bomber ? 1 : 0,
        wobble: _rng.nextDouble() * math.pi * 2,
      ),
    );
  }

  void _resolveCombat() {
    for (final e in List<Enemy>.from(enemies)) {
      for (final b in List<Bullet>.from(bullets)) {
        if (!b.fromPlayer) continue;
        final hitW = e.kind == 1 ? 36.0 : 28.0;
        final hitH = e.kind == 1 ? 40.0 : 32.0;
        if ((b.x - e.x).abs() < hitW / 2 && (b.y - e.y).abs() < hitH / 2) {
          bullets.remove(b);
          e.hp -= 1;
          _burst(e.x, e.y, const Color(0xFFFFD36A), count: 6);
          if (e.hp <= 0) {
            score += e.kind == 1 ? 30 : 10;
            _burst(
              e.x,
              e.y,
              e.kind == 1 ? const Color(0xFFFF6B4A) : const Color(0xFF6B92FF),
              count: 16,
            );
          }
          break;
        }
      }

      if (_invuln > 0) continue;
      final pw = playerW * 0.55;
      final ph = playerH * 0.55;
      final ew = e.kind == 1 ? 34.0 : 26.0;
      final eh = e.kind == 1 ? 38.0 : 30.0;
      if ((player.x - e.x).abs() < (pw + ew) / 2 &&
          (player.y - e.y).abs() < (ph + eh) / 2) {
        lives -= 1;
        _invuln = 1.4;
        e.hp = 0;
        _burst(player.x, player.y, const Color(0xFFFF8A80), count: 20);
      }
    }
  }

  void _burst(double x, double y, Color color, {int count = 10}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = 40 + _rng.nextDouble() * 160;
      sparks.add(
        Spark(
          x: x,
          y: y,
          vx: math.cos(a) * sp,
          vy: math.sin(a) * sp,
          life: 0.25 + _rng.nextDouble() * 0.45,
          color: color,
        ),
      );
    }
  }

  bool get isInvulnerable => _invuln > 0;
}
