import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/balance.dart';
import '../game/engine/defense_engine.dart';
import '../game/engine/entities.dart';
import '../models/defense_models.dart';
import 'painters.dart';

/// 战场动态层：萝卜、建造位、射程、塔、敌人、弹道、特效与飘字。
class BoardActorLayer {
  BoardActorLayer({required this.engine});

  final DefenseEngine engine;
  final Map<String, TextPainter> _textCache = {};
  final Map<int, ui.Picture> _rangeLayers = {};
  final List<Enemy> _enemyOrder = [];

  void paintCarrotTarget(Canvas canvas) {
    final end = engine.track.points.last;
    paintCarrot(canvas, end, 44, pulse: engine.carrotPulse);
    if (engine.carrotHp <= 0) {
      canvas.drawCircle(
        end,
        56,
        fill(const Color(0xFF3A0D0D).withValues(alpha: 0.35)),
      );
    }
  }

  void paintPads(Canvas canvas, double visualTime) {
    final armedKind = engine.armedKind;
    final armed = armedKind != null;
    final armedCost = armed ? towerStats(armedKind, 1).cost : 0;
    for (var i = 0; i < engine.slotPositions.length; i++) {
      if (engine.towerAt(i) != null) continue;
      paintPad(
        canvas,
        engine.slotPositions[i],
        27,
        armed: armed && engine.gold >= armedCost,
        selected: engine.selectedSlot == i,
        pulse: visualTime,
      );
    }
  }

  void paintRange(Canvas canvas) {
    final tower = engine.selectedTower;
    if (tower == null) return;
    final center = tower.position;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawPicture(_rangeSprite(tower.stats.range));
    canvas.restore();

    final canUpgrade = tower.canUpgrade && engine.gold >= tower.upgradeCost;
    if (canUpgrade) {
      final marker = tower.position + const Offset(0, -42);
      canvas.drawCircle(marker, 11, fill(const Color(0xFF2E7D32)));
      final arrow = Path()
        ..moveTo(marker.dx, marker.dy - 6)
        ..lineTo(marker.dx + 5, marker.dy + 1)
        ..lineTo(marker.dx + 2, marker.dy + 1)
        ..lineTo(marker.dx + 2, marker.dy + 6)
        ..lineTo(marker.dx - 2, marker.dy + 6)
        ..lineTo(marker.dx - 2, marker.dy + 1)
        ..lineTo(marker.dx - 5, marker.dy + 1)
        ..close();
      canvas.drawPath(arrow, fill(Colors.white));
    }
  }

  void paintTowers(Canvas canvas) {
    for (final tower in engine.activeTowers) {
      paintTower(
        canvas,
        tower.kind,
        tower.position,
        27,
        angle: tower.angle,
        level: tower.level,
        recoil: tower.recoil,
        selected: engine.selectedSlot == tower.slotIndex,
      );
    }
  }

  void paintEnemies(Canvas canvas, double visualTime, double alpha) {
    final order = _enemyOrder..clear();
    for (final enemy in engine.enemies) {
      if (enemy.alive) order.add(enemy);
    }
    order.sort(_byDistance);
    for (final enemy in order) {
      final position = engine.enemyPosition(enemy, alpha: alpha);
      final bob = math.sin(visualTime * 7 + enemy.id) * 1.5;
      paintEnemy(
        canvas,
        enemy.kind,
        position,
        enemy.radius,
        flash: enemy.flash,
        hpRatio: enemy.hpRatio,
        slowed: enemy.slowed,
        poisoned: enemy.poisoned,
        boss: enemy.isBoss,
        bob: bob,
      );
    }
  }

  void paintProjectiles(Canvas canvas) {
    for (final projectile in engine.projectiles) {
      final direction = projectile.lastTarget - projectile.position;
      final angle = math.atan2(direction.dy, direction.dx);
      switch (projectile.kind) {
        case TowerKind.arrow:
          canvas.save();
          canvas.translate(projectile.position.dx, projectile.position.dy);
          canvas.rotate(angle);
          canvas.drawLine(
            const Offset(-16, 0),
            const Offset(6, 0),
            stroke(const Color(0xFFF6E7C6), 3),
          );
          final head = Path()
            ..moveTo(12, 0)
            ..lineTo(4, -4)
            ..lineTo(4, 4)
            ..close();
          canvas.drawPath(head, fill(const Color(0xFFD7DEE3)));
          canvas.restore();
          break;
        case TowerKind.cannon:
          final arc = math.sin(projectile.progress * math.pi) * 26;
          canvas.drawOval(
            Rect.fromCenter(
              center: projectile.position + const Offset(0, 6),
              width: 16,
              height: 6,
            ),
            fill(Colors.black.withValues(alpha: 0.22)),
          );
          canvas.drawCircle(
            projectile.position - Offset(0, arc),
            7,
            fill(const Color(0xFF2A2A30)),
          );
          canvas.drawCircle(
            projectile.position - Offset(2, arc + 2),
            2.5,
            fill(const Color(0xFF8E8E99)),
          );
          break;
        case TowerKind.frost:
          canvas.save();
          canvas.translate(projectile.position.dx, projectile.position.dy);
          canvas.rotate(angle);
          final shard = Path()
            ..moveTo(8, 0)
            ..lineTo(0, -5)
            ..lineTo(-8, 0)
            ..lineTo(0, 5)
            ..close();
          canvas.drawPath(shard, fill(const Color(0xFFCFF4FF)));
          canvas.drawPath(shard, stroke(const Color(0xFF6EC6EC), 1.5));
          canvas.drawCircle(
            Offset.zero,
            10,
            Paint()
              ..color = const Color(0xFF9FE6FF).withValues(alpha: 0.28)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          canvas.restore();
          break;
        case TowerKind.poison:
          final arc = math.sin(projectile.progress * math.pi) * 12;
          final center = projectile.position - Offset(0, arc);
          canvas.drawCircle(
            center,
            9,
            fill(const Color(0xFF6FBF4A).withValues(alpha: 0.9)),
          );
          canvas.drawCircle(
            center + const Offset(-3, 2),
            7,
            stroke(const Color(0xFFCBEF9A), 1.4),
          );
          canvas.drawCircle(
            center + const Offset(3, -3),
            2.4,
            fill(const Color(0xFFE7FFCB)),
          );
          break;
        case TowerKind.lightning:
          break;
      }
    }
  }

  void paintEffects(Canvas canvas, double visualTime) {
    for (final effect in engine.effects) {
      final t = effect.progress;
      switch (effect.kind) {
        case EffectKind.explosion:
          final radius = effect.radius * (0.35 + 0.85 * t);
          canvas.drawCircle(
            effect.position,
            radius,
            fill(const Color(0xFFFF9A3D).withValues(alpha: (1 - t) * 0.55)),
          );
          canvas.drawCircle(
            effect.position,
            radius * 1.05,
            stroke(
              const Color(0xFFFFE1A8).withValues(alpha: (1 - t) * 0.85),
              4,
            ),
          );
          for (var i = 0; i < 6; i++) {
            final angle = i * math.pi / 3 + 0.4;
            canvas.drawCircle(
              effect.position +
                  Offset(math.cos(angle), math.sin(angle)) * radius * 0.7,
              effect.radius * 0.16 * (1 - t),
              fill(const Color(0xFF6E5B45).withValues(alpha: (1 - t) * 0.45)),
            );
          }
          break;
        case EffectKind.spark:
          final paint = stroke(
            const Color(0xFFFFF0B8).withValues(alpha: 1 - t),
            2.4,
          );
          for (var i = 0; i < 6; i++) {
            final angle = i * math.pi / 3;
            final inner = effect.radius * 0.25;
            final outer = effect.radius * (0.45 + 0.75 * t);
            canvas.drawLine(
              effect.position +
                  Offset(math.cos(angle), math.sin(angle)) * inner,
              effect.position +
                  Offset(math.cos(angle), math.sin(angle)) * outer,
              paint,
            );
          }
          break;
        case EffectKind.frostRing:
          canvas.drawCircle(
            effect.position,
            effect.radius * (0.45 + 0.75 * t),
            stroke(const Color(0xFFBFF1FF).withValues(alpha: 1 - t), 3),
          );
          canvas.drawCircle(
            effect.position,
            effect.radius * (0.3 + 0.55 * t),
            fill(const Color(0xFF9FE6FF).withValues(alpha: (1 - t) * 0.22)),
          );
          break;
        case EffectKind.lightning:
          _paintLightning(canvas, effect, t, visualTime);
          break;
        case EffectKind.poison:
          final spread = effect.radius * (0.35 + 0.75 * t);
          canvas.drawCircle(
            effect.position,
            spread,
            fill(const Color(0xFF6FBF4A).withValues(alpha: (1 - t) * 0.2)),
          );
          canvas.drawCircle(
            effect.position,
            spread,
            stroke(const Color(0xFFA8E36B).withValues(alpha: 1 - t), 2.6),
          );
          for (var i = 0; i < 5; i++) {
            final angle = i * math.pi * 2 / 5 + 0.5;
            canvas.drawCircle(
              effect.position +
                  Offset(math.cos(angle), math.sin(angle)) * spread * 0.7,
              effect.radius * 0.12 * (1 - t),
              fill(const Color(0xFFD9FFAF).withValues(alpha: 1 - t)),
            );
          }
          break;
        case EffectKind.buildDust:
          canvas.drawCircle(
            effect.position,
            effect.radius * (0.4 + 0.8 * t),
            stroke(const Color(0xFFE8D9B0).withValues(alpha: 1 - t), 3),
          );
          for (var i = 0; i < 5; i++) {
            final angle = i * math.pi * 2 / 5;
            canvas.drawCircle(
              effect.position +
                  Offset(math.cos(angle), math.sin(angle)) *
                      effect.radius *
                      (0.3 + t),
              3 * (1 - t),
              fill(const Color(0xFFD9C9A3).withValues(alpha: 1 - t)),
            );
          }
          break;
        case EffectKind.leak:
          canvas.drawCircle(
            effect.position,
            effect.radius * (0.5 + 0.8 * t),
            stroke(const Color(0xFFFF6B5A).withValues(alpha: 1 - t), 4),
          );
          canvas.drawCircle(
            effect.position,
            effect.radius * (0.3 + 0.5 * t),
            fill(const Color(0xFFFF4D3D).withValues(alpha: (1 - t) * 0.25)),
          );
          break;
      }
    }
  }

  void paintFloaters(Canvas canvas) {
    for (final floater in engine.floaters) {
      final t = floater.progress;
      final painter = _textPainter(
        floater.text,
        floater.big ? 26 : 20,
        floater.color.withValues(alpha: 1 - t),
        bold: true,
      );
      final position =
          floater.position - Offset(0, 30 * t + painter.height / 2);
      painter.paint(canvas, position - Offset(painter.width / 2, 0));
    }
  }

  void dispose() {
    for (final layer in _rangeLayers.values) {
      layer.dispose();
    }
    _rangeLayers.clear();
    _textCache.clear();
  }

  /// 射程虚线圈形状固定，按半径缓存，避免每帧重复 36 次 drawArc。
  ui.Picture _rangeSprite(double radius) {
    final key = (radius * 2).round();
    final cached = _rangeLayers[key];
    if (cached != null) return cached;
    final recorder = ui.PictureRecorder();
    final rangeCanvas = Canvas(recorder);
    rangeCanvas.drawCircle(
      Offset.zero,
      radius,
      fill(const Color(0xFFFFF3C4).withValues(alpha: 0.09)),
    );
    final paint = stroke(const Color(0xFFFFE08A).withValues(alpha: 0.8), 2);
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    for (var angle = 0.0; angle < math.pi * 2; angle += math.pi / 18) {
      rangeCanvas.drawArc(rect, angle, math.pi / 26, false, paint);
    }
    final picture = recorder.endRecording();
    _rangeLayers[key] = picture;
    return picture;
  }

  void _paintLightning(
    Canvas canvas,
    Effect effect,
    double t,
    double visualTime,
  ) {
    final paint = stroke(Colors.white.withValues(alpha: 1 - t), 2.2);
    final glow = stroke(
      const Color(0xFFB98CFF).withValues(alpha: (1 - t) * 0.6),
      7,
    );
    final path = Path();
    for (var i = 0; i < effect.points.length; i++) {
      final point = effect.points[i];
      final offset = i == 0
          ? Offset.zero
          : Offset(
              math.sin(visualTime * 70 + i * 2.7) * 4 * (1 - t),
              math.cos(visualTime * 63 + i * 1.9) * 4 * (1 - t),
            );
      final p = point + offset;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  TextPainter _textPainter(
    String text,
    double fontSize,
    Color color, {
    bool bold = false,
  }) {
    // 透明度按 1/16 量化，飘字渐隐时不再每帧新建 TextPainter。
    final alpha = color.a <= 0 ? 0 : (color.a * 16).ceil().clamp(1, 16);
    final key = '$text|$fontSize|$alpha|$bold';
    final cached = _textCache[key];
    if (cached != null) return cached;
    if (_textCache.length > 160) _textCache.clear();
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color.withValues(alpha: alpha / 16),
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          shadows: const [
            Shadow(
              color: Color(0x99000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _textCache[key] = painter;
    return painter;
  }
}

int _byDistance(Enemy a, Enemy b) => a.distance.compareTo(b.distance);
