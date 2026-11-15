import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../game/balance.dart';
import '../game/engine/defense_engine.dart';
import '../game/engine/entities.dart';
import 'fog_art.dart' as fog;
import 'painters.dart';
import 'projectile_art.dart';

/// 战场动态层：萝卜、建造位、射程、塔、敌人、弹道、特效与飘字。
class BoardActorLayer {
  BoardActorLayer({required this.engine});

  final DefenseEngine engine;
  final Map<String, List<TextPainter?>> _textCache = {};
  final Map<int, ui.Picture> _rangeLayers = {};

  /// 建造位石台与塔身底座只在建造、升级、出售后变化，合并录制后每帧各画一次。
  ui.Picture? _padLayer;
  ui.Picture? _towerBodyLayer;
  ui.Picture? _startGlow;
  int _structureKey = -1;
  int _structureLayerBuilds = 0;

  /// 结构图层录制次数，供性能回归测试确认批量图层复用生效。
  int get structureLayerBuilds => _structureLayerBuilds;

  /// 起点光圈录制为渐变精灵，每帧只按呼吸节奏缩放，不再实时模糊。
  void paintStartGlow(Canvas canvas, double visualTime) {
    final start = engine.track.start;
    final scale = 0.92 + 0.16 * math.sin(visualTime * 2);
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.scale(scale);
    canvas.drawPicture(_startGlowSprite());
    canvas.restore();
  }

  ui.Picture _startGlowSprite() {
    final cached = _startGlow;
    if (cached != null) return cached;
    final picture = recordPicture((canvas) {
      canvas.drawCircle(
        Offset.zero,
        24,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x59B84DFF), Color(0x00B84DFF)])
              .createShader(Rect.fromCircle(center: Offset.zero, radius: 24)),
      );
    });
    _startGlow = picture;
    return picture;
  }

  void paintCarrotTarget(Canvas canvas) {
    final end = engine.track.end;
    paintCarrot(canvas, end, 44, pulse: engine.carrotPulse);
    if (engine.carrotHp <= 0) {
      canvas.drawCircle(end, 56, dynFill(const Color(0xFF3A0D0D).withValues(alpha: 0.35)));
    }
  }

  /// 毒雾区上缓慢漂移的雾气，让静态毒圈有呼吸感。
  void paintFogMist(Canvas canvas, double visualTime) =>
      fog.paintFogMist(canvas, engine.level, visualTime);

  void paintPads(Canvas canvas, double visualTime) {
    final armedKind = engine.armedKind;
    final armed = armedKind != null && engine.gold >= towerStats(armedKind, 1).cost;
    final selected = engine.selectedSlot;
    // 石台本身一次性画完，高亮呼吸圈只画需要发光的那几个。
    canvas.drawPicture(_padSprite());
    if (!armed && selected == null) return;
    for (var i = 0; i < engine.slotPositions.length; i++) {
      if (engine.towerAt(i) != null) continue;
      if (!armed && i != selected) continue;
      paintPadGlow(canvas, engine.slotPositions[i], 27, armed: armed, pulse: visualTime);
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
      canvas.drawCircle(marker, 11, dynFill(const Color(0xFF2E7D32)));
      final arrow = Path()
        ..moveTo(marker.dx, marker.dy - 6)
        ..lineTo(marker.dx + 5, marker.dy + 1)
        ..lineTo(marker.dx + 2, marker.dy + 1)
        ..lineTo(marker.dx + 2, marker.dy + 6)
        ..lineTo(marker.dx - 2, marker.dy + 6)
        ..lineTo(marker.dx - 2, marker.dy + 1)
        ..lineTo(marker.dx - 5, marker.dy + 1)
        ..close();
      canvas.drawPath(arrow, dynFill(Colors.white));
    }
  }

  void paintTowers(Canvas canvas) {
    final selected = engine.selectedTower;
    if (selected != null) {
      canvas.save();
      canvas.translate(selected.position.dx, selected.position.dy);
      paintTowerSelection(canvas, 27);
      canvas.restore();
    }
    canvas.drawPicture(_towerBodiesSprite());
    for (final tower in engine.activeTowers) {
      paintTowerTurret(
        canvas,
        tower.kind,
        tower.position,
        27,
        angle: tower.angle,
        recoil: tower.recoil,
      );
    }
  }

  void paintEnemies(Canvas canvas, double visualTime, double alpha) {
    // 引擎已按进度升序维护存活敌人顺序，绘制层不再逐帧排序。
    for (final enemy in engine.frameOrder) {
      if (!enemy.alive) continue;
      final position = engine.enemyPosition(enemy, alpha: alpha);
      final bob = enemy.flying
          ? math.sin(visualTime * 6 + enemy.id) * 3 - 12
          : math.sin(visualTime * 7 + enemy.id) * 1.5;
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
      paintProjectile(canvas, projectile);
    }
  }

  void paintEffects(Canvas canvas, double visualTime) {
    for (final effect in engine.effects) {
      final t = effect.progress;
      final fade = 1 - t;
      final at = effect.position;
      switch (effect.kind) {
        case EffectKind.explosion:
          final radius = effect.radius * (0.35 + 0.85 * t);
          _dot(canvas, at, radius, const Color(0xFFFF9A3D).withValues(alpha: fade * 0.55));
          _ring(
            canvas,
            at,
            radius * 1.05,
            const Color(0xFFFFE1A8).withValues(alpha: fade * 0.85),
            4,
          );
          for (var i = 0; i < 6; i++) {
            _dot(
              canvas,
              _polar(at, i * math.pi / 3 + 0.4, radius * 0.7),
              effect.radius * 0.16 * fade,
              const Color(0xFF6E5B45).withValues(alpha: fade * 0.45),
            );
          }
        case EffectKind.spark:
          for (var i = 0; i < 6; i++) {
            final angle = i * math.pi / 3;
            canvas.drawLine(
              _polar(at, angle, effect.radius * 0.25),
              _polar(at, angle, effect.radius * (0.45 + 0.75 * t)),
              dynStroke(const Color(0xFFFFF0B8).withValues(alpha: fade), 2.4),
            );
          }
        case EffectKind.frostRing:
          _ring(
            canvas,
            at,
            effect.radius * (0.45 + 0.75 * t),
            const Color(0xFFBFF1FF).withValues(alpha: fade),
            3,
          );
          _dot(
            canvas,
            at,
            effect.radius * (0.3 + 0.55 * t),
            const Color(0xFF9FE6FF).withValues(alpha: fade * 0.22),
          );
        case EffectKind.lightning:
          _paintLightning(canvas, effect, t, visualTime);
        case EffectKind.poison:
          final spread = effect.radius * (0.35 + 0.75 * t);
          _dot(canvas, at, spread, const Color(0xFF6FBF4A).withValues(alpha: fade * 0.2));
          _ring(canvas, at, spread, const Color(0xFFA8E36B).withValues(alpha: fade), 2.6);
          for (var i = 0; i < 5; i++) {
            _dot(
              canvas,
              _polar(at, i * math.pi * 2 / 5 + 0.5, spread * 0.7),
              effect.radius * 0.12 * fade,
              const Color(0xFFD9FFAF).withValues(alpha: fade),
            );
          }
        case EffectKind.buildDust:
          _ring(
            canvas,
            at,
            effect.radius * (0.4 + 0.8 * t),
            const Color(0xFFE8D9B0).withValues(alpha: fade),
            3,
          );
          for (var i = 0; i < 5; i++) {
            _dot(
              canvas,
              _polar(at, i * math.pi * 2 / 5, effect.radius * (0.3 + t)),
              3 * fade,
              const Color(0xFFD9C9A3).withValues(alpha: fade),
            );
          }
        case EffectKind.leak:
          _ring(
            canvas,
            at,
            effect.radius * (0.5 + 0.8 * t),
            const Color(0xFFFF6B5A).withValues(alpha: fade),
            4,
          );
          _dot(
            canvas,
            at,
            effect.radius * (0.3 + 0.5 * t),
            const Color(0xFFFF4D3D).withValues(alpha: fade * 0.25),
          );
        case EffectKind.portal:
          for (final point in effect.points) {
            _ring(
              canvas,
              point,
              effect.radius * (0.45 + 0.85 * t),
              const Color(0xFF9B7BFF).withValues(alpha: fade),
              3,
            );
            _dot(
              canvas,
              point,
              effect.radius * (0.3 + 0.4 * t),
              const Color(0xFFD9C4FF).withValues(alpha: fade * 0.3),
            );
          }
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
      final position = floater.position - Offset(0, 30 * t + painter.height / 2);
      painter.paint(canvas, position - Offset(painter.width / 2, 0));
    }
  }

  void dispose() {
    for (final layer in _rangeLayers.values) {
      layer.dispose();
    }
    _rangeLayers.clear();
    _padLayer?.dispose();
    _padLayer = null;
    _towerBodyLayer?.dispose();
    _towerBodyLayer = null;
    _startGlow?.dispose();
    _startGlow = null;
    for (final painters in _textCache.values) {
      for (final painter in painters) {
        painter?.dispose();
      }
    }
    _textCache.clear();
  }

  /// 空白建造位的石台与已建塔的底座合并成两张图层，结构没变时每帧各画一次。
  ui.Picture _padSprite() {
    _ensureStructureLayers();
    return _padLayer!;
  }

  /// 已建塔的底座合并成一张图层，炮塔角度与后坐力仍逐塔实时绘制。
  ui.Picture _towerBodiesSprite() {
    _ensureStructureLayers();
    return _towerBodyLayer!;
  }

  void _ensureStructureLayers() {
    if (_padLayer != null && _structureKey == engine.structureVersion) return;
    _structureKey = engine.structureVersion;
    _padLayer?.dispose();
    _towerBodyLayer?.dispose();
    _structureLayerBuilds += 2;
    _padLayer = recordPicture((padCanvas) {
      for (var i = 0; i < engine.slotPositions.length; i++) {
        if (engine.towerAt(i) == null) paintPadBase(padCanvas, engine.slotPositions[i], 27);
      }
    });
    _towerBodyLayer = recordPicture((bodyCanvas) {
      for (final tower in engine.activeTowers) {
        paintTowerBody(bodyCanvas, tower.kind, tower.position, 27, tower.level);
      }
    });
  }

  /// 射程虚线圈形状固定，按半径缓存，避免每帧重复 36 次 drawArc。
  ui.Picture _rangeSprite(double radius) {
    final key = (radius * 2).round();
    final cached = _rangeLayers[key];
    if (cached != null) return cached;
    final picture = recordPicture((rangeCanvas) {
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
    });
    _rangeLayers[key] = picture;
    return picture;
  }

  void _paintLightning(Canvas canvas, Effect effect, double t, double visualTime) {
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
    canvas.drawPath(path, dynStroke(const Color(0xFFB98CFF).withValues(alpha: (1 - t) * 0.6), 7));
    canvas.drawPath(path, dynStroke(Colors.white.withValues(alpha: 1 - t), 2.2));
  }

  TextPainter _textPainter(String text, double fontSize, Color color, {bool bold = false}) {
    // 透明度按 1/16 量化，飘字渐隐时不再每帧新建 TextPainter；
    // 按文本分组缓存，键比较不再逐帧拼接字符串。
    final alpha = color.a <= 0 ? 0 : (color.a * 16).ceil().clamp(1, 16);
    if (!_textCache.containsKey(text) && _textCache.length > 160) {
      final stale = _textCache.keys.take(32).toList();
      for (final key in stale) {
        for (final painter in _textCache.remove(key) ?? const <TextPainter?>[]) {
          painter?.dispose();
        }
      }
    }
    final variants = _textCache.putIfAbsent(text, () => List<TextPainter?>.filled(32, null));
    final slot = (fontSize >= 26 ? 16 : 0) + (bold ? 8 : 0) + alpha - 1;
    final cached = variants[slot];
    if (cached != null) return cached;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color.withValues(alpha: alpha / 16),
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          shadows: const [Shadow(color: Color(0x99000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    variants[slot] = painter;
    return painter;
  }
}

void _dot(Canvas canvas, Offset at, double radius, Color color) =>
    canvas.drawCircle(at, radius, dynFill(color));

void _ring(Canvas canvas, Offset at, double r, Color c, double w) =>
    canvas.drawCircle(at, r, dynStroke(c, w));

Offset _polar(Offset center, double angle, double radius) =>
    center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
