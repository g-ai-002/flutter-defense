import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Gradient;

import '../game/balance.dart';
import '../game/engine/defense_engine.dart';
import '../game/engine/entities.dart';
import '../game/engine/path_track.dart';
import '../game/logic_rate.dart';
import '../models/defense_models.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';
import '../theme/level_theme.dart';
import '../utils/constants.dart';
import 'painters.dart';

/// 战场渲染：地貌、路径、萝卜、防御塔、敌人、弹道与特效，全部 Canvas 绘制。
class BoardComponent extends PositionComponent with TapCallbacks {
  BoardComponent({
    required this.engine,
    required this.logicRate,
    required this.pausedNotifier,
    required this.speed,
  }) : _clock = FixedStepClock(logicRate.step) {
    _decorations = _buildDecorations(engine);
    _blobs = _buildBlobs(engine.level.seed);
  }

  final DefenseEngine engine;
  final LogicRate logicRate;
  final ValueNotifier<bool> pausedNotifier;
  final ValueNotifier<double> speed;

  final FixedStepClock _clock;
  late final List<_Decor> _decorations;
  late final List<_Blob> _blobs;
  final Map<String, TextPainter> _textCache = {};
  double _visualTime = 0;
  bool _resultLogged = false;

  LevelPalette get _palette => paletteOf(engine.level.theme);
  PathTrack get _track => engine.track;

  @override
  void update(double dt) {
    super.update(dt);
    _visualTime += dt;
    if (pausedNotifier.value) return;
    _clock.advance(dt * speed.value, engine.update);
    _consumeEvents();
  }

  void _consumeEvents() {
    if (engine.events.isEmpty) return;
    final events = List<GameEvent>.of(engine.events);
    engine.events.clear();
    for (final event in events) {
      switch (event) {
        case GameEvent.build:
          SoundService.play(SoundFx.build);
          final slot = engine.selectedSlot;
          if (slot != null) LogService.info('建造防御塔: 第${slot + 1}号位');
          break;
        case GameEvent.upgrade:
          SoundService.play(SoundFx.upgrade);
          break;
        case GameEvent.sell:
          SoundService.play(SoundFx.sell);
          break;
        case GameEvent.arrowShot:
          SoundService.play(SoundFx.arrow);
          break;
        case GameEvent.cannonShot:
          SoundService.play(SoundFx.cannon);
          break;
        case GameEvent.frostShot:
          SoundService.play(SoundFx.frost);
          break;
        case GameEvent.lightning:
          SoundService.play(SoundFx.lightning);
          break;
        case GameEvent.hit:
          SoundService.play(SoundFx.hit);
          break;
        case GameEvent.leak:
          SoundService.play(SoundFx.leak);
          LogService.warning(
            '敌人突破防线, 萝卜剩余 ${engine.carrotHp}/${engine.carrotMaxHp}',
          );
          break;
        case GameEvent.waveStart:
          SoundService.play(SoundFx.waveStart);
          LogService.info(
            '第 ${engine.waveIndex}/${engine.level.waveCount} 波开始',
          );
          break;
        case GameEvent.waveClear:
          SoundService.play(SoundFx.waveClear);
          LogService.info('第 ${engine.waveIndex} 波清理完毕');
          break;
        case GameEvent.victory:
          SoundService.play(SoundFx.victory);
          _logResult(true);
          break;
        case GameEvent.defeat:
          SoundService.play(SoundFx.defeat);
          _logResult(false);
          break;
        case GameEvent.gold:
          SoundService.play(SoundFx.coin);
          break;
      }
    }
  }

  void _logResult(bool victory) {
    if (_resultLogged) return;
    _resultLogged = true;
    LogService.info(
      '关卡结束: ${engine.level.name} ${victory ? '胜利' : '失败'}, '
      '萝卜 ${engine.carrotHp}/${engine.carrotMaxHp}, '
      '击杀 ${engine.kills}, 漏怪 ${engine.leaked}, 金币收入 ${engine.goldEarned}',
    );
  }

  Offset? _toDesign(Offset local) {
    final layout = _layout();
    final design = (local - layout.origin) / layout.scale;
    if (design.dx < 0 ||
        design.dy < 0 ||
        design.dx > kDesignWidth ||
        design.dy > kDesignHeight) {
      return null;
    }
    return design;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final design = _toDesign(
      Offset(event.localPosition.x, event.localPosition.y),
    );
    if (design == null) return;
    final slot = _slotAt(design);
    if (slot == null) {
      engine.clearSelection();
      return;
    }
    final tower = engine.towerAt(slot);
    if (tower != null) {
      engine.selectSlot(slot);
      SoundService.play(SoundFx.tap);
      return;
    }
    final kind = engine.armedKind;
    if (kind != null) {
      engine.build(slot, kind);
    } else {
      engine.selectSlot(slot);
      SoundService.play(SoundFx.tap);
    }
  }

  int? _slotAt(Offset point) {
    var best = -1;
    var bestDistance = 34.0;
    for (var i = 0; i < engine.slotPositions.length; i++) {
      final distance = (engine.slotPositions[i] - point).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best < 0 ? null : best;
  }

  _Layout _layout() {
    final view = Size(size.x, size.y);
    final top = hudTopInset(view);
    final bottom = hudBottomInset(view);
    final availableHeight = math.max(1.0, view.height - top - bottom);
    var scale = math.min(
      (view.width - 24) / kDesignWidth,
      availableHeight / kDesignHeight,
    );
    scale = scale.clamp(0.15, 1.6);
    final origin = Offset(
      (view.width - kDesignWidth * scale) / 2,
      top + (availableHeight - kDesignHeight * scale) / 2,
    );
    return _Layout(origin: origin, scale: scale);
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final layout = _layout();
    _paintBackdrop(canvas);
    canvas.save();
    canvas.translate(layout.origin.dx, layout.origin.dy);
    canvas.scale(layout.scale);
    final clip = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, kDesignWidth, kDesignHeight),
      const Radius.circular(28),
    );
    canvas.clipRRect(clip);
    _paintGround(canvas);
    _paintDecorations(canvas);
    _paintPath(canvas);
    _paintStart(canvas);
    _paintCarrot(canvas);
    _paintPads(canvas);
    _paintRange(canvas);
    _paintTowers(canvas);
    _paintEnemies(canvas);
    _paintProjectiles(canvas);
    _paintEffects(canvas);
    _paintFloaters(canvas);
    canvas.restore();

    canvas.drawRRect(
      clip.shift(layout.origin),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _palette.frame.withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      clip.shift(layout.origin).deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _paintBackdrop(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final palette = _palette;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(palette.frame, Colors.black, 0.55)!,
            Color.lerp(palette.frame, Colors.black, 0.78)!,
          ],
        ).createShader(rect),
    );
    final glow = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.8,
    );
    canvas.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.accent.withValues(alpha: 0.18),
            palette.accent.withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    final layout = _layout();
    final shadowRect = Rect.fromLTWH(
      layout.origin.dx,
      layout.origin.dy,
      kDesignWidth * layout.scale,
      kDesignHeight * layout.scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(28)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  void _paintGround(Canvas canvas) {
    final palette = _palette;
    const rect = Rect.fromLTWH(0, 0, kDesignWidth, kDesignHeight);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.groundTop, palette.groundBottom],
        ).createShader(rect),
    );
    for (final blob in _blobs) {
      canvas.drawOval(
        Rect.fromCenter(
          center: blob.position,
          width: blob.radius * 2,
          height: blob.radius * 1.3,
        ),
        Paint()
          ..color = (blob.light ? Colors.white : palette.groundDeep).withValues(
            alpha: blob.alpha,
          ),
      );
    }
    // 细微草纹，增加地面层次。
    final random = math.Random(engine.level.seed + 77);
    final linePaint = Paint()
      ..color = palette.groundDeep.withValues(alpha: 0.28)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 90; i++) {
      final x = random.nextDouble() * kDesignWidth;
      final y = random.nextDouble() * kDesignHeight;
      final length = 4 + random.nextDouble() * 7;
      canvas.drawLine(Offset(x, y), Offset(x + length, y - 2), linePaint);
    }
    // 内阴影
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [
            Colors.transparent,
            palette.groundDeep.withValues(alpha: 0.35),
          ],
          stops: const [0.6, 1],
        ).createShader(rect),
    );
  }

  void _paintDecorations(Canvas canvas) {
    final palette = _palette;
    for (final decor in _decorations) {
      canvas.save();
      canvas.translate(decor.position.dx, decor.position.dy);
      canvas.scale(decor.scale * (decor.flip ? -1 : 1), decor.scale);
      _paintDecoration(canvas, engine.level.theme, decor.kind, palette);
      canvas.restore();
    }
  }

  void _paintDecoration(
    Canvas canvas,
    LevelTheme theme,
    int kind,
    LevelPalette palette,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 34, height: 10),
      fill(Colors.black.withValues(alpha: 0.12)),
    );
    final primary = palette.decorPrimary;
    final secondary = palette.decorSecondary;
    switch (theme) {
      case LevelTheme.meadow:
        if (kind == 0) {
          _tree(canvas, primary, secondary);
        } else if (kind == 1) {
          _flower(canvas, secondary);
        } else {
          _bush(canvas, primary);
        }
        break;
      case LevelTheme.forest:
        if (kind == 0) {
          _tree(canvas, primary, secondary);
        } else if (kind == 1) {
          _mushroom(canvas, secondary);
        } else {
          _bush(canvas, primary);
        }
        break;
      case LevelTheme.desert:
        if (kind == 0) {
          _cactus(canvas, primary);
        } else if (kind == 1) {
          _rock(canvas, palette);
        } else {
          _bush(canvas, primary);
        }
        break;
      case LevelTheme.snow:
        if (kind == 0) {
          _pine(canvas, primary, secondary);
        } else if (kind == 1) {
          _rock(canvas, palette);
        } else {
          _ice(canvas, secondary);
        }
        break;
      case LevelTheme.lava:
        if (kind == 0) {
          _deadTree(canvas, primary);
        } else if (kind == 1) {
          _rock(canvas, palette);
        } else {
          _lavaCrack(canvas, secondary);
        }
        break;
      case LevelTheme.night:
        if (kind == 0) {
          _tree(canvas, primary, secondary);
        } else if (kind == 1) {
          _lantern(canvas, secondary);
        } else {
          _reed(canvas, primary);
        }
        break;
    }
  }

  void _tree(Canvas canvas, Color trunk, Color leaf) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, -18, 8, 26),
        const Radius.circular(3),
      ),
      fill(trunk),
    );
    canvas.drawCircle(const Offset(0, -30), 18, fill(leaf));
    canvas.drawCircle(const Offset(-12, -22), 13, fill(leaf));
    canvas.drawCircle(const Offset(12, -22), 14, fill(leaf));
    canvas.drawCircle(
      const Offset(-4, -34),
      9,
      fill(Colors.white.withValues(alpha: 0.16)),
    );
  }

  void _flower(Canvas canvas, Color color) {
    canvas.drawLine(
      const Offset(0, 2),
      const Offset(0, -14),
      stroke(const Color(0xFF4C8F3B), 2),
    );
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi / 2.5;
      canvas.drawCircle(
        Offset(math.cos(angle) * 6, -14 + math.sin(angle) * 6),
        4.5,
        fill(color),
      );
    }
    canvas.drawCircle(const Offset(0, -14), 3, fill(const Color(0xFFF2A03D)));
  }

  void _bush(Canvas canvas, Color color) {
    canvas.drawCircle(const Offset(-8, -6), 11, fill(color));
    canvas.drawCircle(const Offset(8, -6), 12, fill(color));
    canvas.drawCircle(const Offset(0, -13), 10, fill(color));
    canvas.drawOval(
      const Rect.fromLTWH(-16, -4, 32, 7),
      fill(Colors.black.withValues(alpha: 0.08)),
    );
  }

  void _mushroom(Canvas canvas, Color cap) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -14, 10, 18),
        const Radius.circular(4),
      ),
      fill(const Color(0xFFF2E7D0)),
    );
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, -14), width: 36, height: 30),
      math.pi,
      math.pi,
      true,
      fill(cap),
    );
    canvas.drawCircle(
      const Offset(-7, -20),
      3,
      fill(Colors.white.withValues(alpha: 0.65)),
    );
    canvas.drawCircle(
      const Offset(8, -17),
      2.4,
      fill(Colors.white.withValues(alpha: 0.65)),
    );
  }

  void _cactus(Canvas canvas, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, -30, 12, 34),
        const Radius.circular(6),
      ),
      fill(color),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -20, 12, 7),
        const Radius.circular(4),
      ),
      fill(color),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -26, 7, 12),
        const Radius.circular(4),
      ),
      fill(color),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, -15, 12, 7),
        const Radius.circular(4),
      ),
      fill(color),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, -22, 7, 13),
        const Radius.circular(4),
      ),
      fill(color),
    );
  }

  void _rock(Canvas canvas, LevelPalette palette) {
    final path = Path()
      ..moveTo(-18, 4)
      ..lineTo(-12, -12)
      ..lineTo(2, -18)
      ..lineTo(16, -8)
      ..lineTo(18, 4)
      ..close();
    canvas.drawPath(path, fill(palette.padStoneDark));
    canvas.drawPath(
      Path()
        ..moveTo(-12, -12)
        ..lineTo(2, -18)
        ..lineTo(14, -9)
        ..lineTo(0, -4)
        ..close(),
      fill(Colors.white.withValues(alpha: 0.22)),
    );
  }

  void _pine(Canvas canvas, Color color, Color snow) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, -10, 6, 16),
        const Radius.circular(2),
      ),
      fill(const Color(0xFF6B4A2E)),
    );
    for (var i = 0; i < 3; i++) {
      final width = 26.0 - i * 6;
      final y = -10.0 - i * 11;
      final triangle = Path()
        ..moveTo(-width, y)
        ..lineTo(0, y - 18)
        ..lineTo(width, y)
        ..close();
      canvas.drawPath(triangle, fill(color));
      canvas.drawPath(
        Path()
          ..moveTo(-width * 0.7, y - 4)
          ..lineTo(0, y - 16)
          ..lineTo(width * 0.7, y - 4)
          ..close(),
        fill(snow.withValues(alpha: 0.75)),
      );
    }
  }

  void _ice(Canvas canvas, Color color) {
    final crystal = Path()
      ..moveTo(0, -26)
      ..lineTo(9, -8)
      ..lineTo(0, 4)
      ..lineTo(-9, -8)
      ..close();
    canvas.drawPath(
      crystal,
      Paint()
        ..shader = LinearGradient(colors: [color, const Color(0xFF6FAEC8)])
            .createShader(const Rect.fromLTWH(-10, -28, 20, 34)),
    );
    canvas.drawPath(crystal, stroke(Colors.white.withValues(alpha: 0.6), 1.4));
  }

  void _deadTree(Canvas canvas, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, -22, 8, 28),
        const Radius.circular(3),
      ),
      fill(color),
    );
    final branch = stroke(color, 3);
    canvas.drawLine(const Offset(0, -16), const Offset(-16, -26), branch);
    canvas.drawLine(const Offset(0, -10), const Offset(14, -20), branch);
    canvas.drawLine(const Offset(-10, -22), const Offset(-13, -32), branch);
  }

  void _lavaCrack(Canvas canvas, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 16),
      fill(const Color(0xFF3A241E)),
    );
    final paint = stroke(color, 2.4);
    canvas.drawLine(const Offset(-14, 0), const Offset(-4, -3), paint);
    canvas.drawLine(const Offset(-4, -3), const Offset(4, 3), paint);
    canvas.drawLine(const Offset(4, 3), const Offset(14, 0), paint);
    canvas.drawCircle(
      const Offset(0, 0),
      12,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _lantern(Canvas canvas, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2, -26, 4, 30),
        const Radius.circular(2),
      ),
      fill(const Color(0xFF2F4A54)),
    );
    canvas.drawCircle(
      const Offset(0, -28),
      12,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(const Offset(0, -28), 7, fill(color));
    canvas.drawLine(
      const Offset(-6, -34),
      const Offset(6, -34),
      stroke(const Color(0xFF2F4A54), 2),
    );
  }

  void _reed(Canvas canvas, Color color) {
    final paint = stroke(color, 2.2);
    for (var i = 0; i < 5; i++) {
      final x = (i - 2) * 6.0;
      canvas.drawLine(Offset(x, 4), Offset(x * 1.5, -24 - i * 2), paint);
    }
    canvas.drawOval(
      const Rect.fromLTWH(-2, -32, 5, 10),
      fill(const Color(0xFF7C5C3A)),
    );
  }

  void _paintPath(Canvas canvas) {
    final path = Path();
    final points = _track.points;
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final palette = _palette;
    canvas.drawPath(path, stroke(palette.pathEdge, 60));
    canvas.drawPath(path, stroke(palette.pathFill, 50));
    canvas.drawPath(
      path,
      stroke(palette.pathLight.withValues(alpha: 0.35), 26),
    );

    // 路面碎石与虚线
    final random = math.Random(engine.level.seed + 31);
    for (var distance = 26.0; distance < _track.length; distance += 44) {
      final point = _track.pointAt(distance);
      final tangent = _track.tangentAt(distance);
      final normal = Offset(-tangent.dy, tangent.dx);
      final offset = (random.nextDouble() - 0.5) * 30;
      final size = 1.5 + random.nextDouble() * 2.2;
      canvas.drawCircle(
        point + normal * offset,
        size,
        fill(palette.pathEdge.withValues(alpha: 0.45)),
      );
    }
    final dash = stroke(Colors.white.withValues(alpha: 0.28), 3);
    for (var distance = 30.0; distance < _track.length - 40; distance += 58) {
      final a = _track.pointAt(distance);
      final b = _track.pointAt(math.min(distance + 24, _track.length));
      canvas.drawLine(a, b, dash);
    }
  }

  void _paintStart(Canvas canvas) {
    final start = _track.points.first;
    canvas.drawCircle(
      start,
      40,
      Paint()
        ..color = const Color(0xFF26160F).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      start,
      28,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2B1B2C), Color(0xFF120B10)],
        ).createShader(Rect.fromCircle(center: start, radius: 28)),
    );
    canvas.drawCircle(start, 28, stroke(const Color(0xFF5C4330), 3));
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      canvas.drawCircle(
        start + Offset(math.cos(angle), math.sin(angle)) * 30,
        5,
        fill(const Color(0xFF6E5B45)),
      );
    }
    final glow = 0.3 + 0.2 * math.sin(_visualTime * 2);
    canvas.drawCircle(
      start,
      16,
      Paint()
        ..color = const Color(0xFFB84DFF).withValues(alpha: glow * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _paintCarrot(Canvas canvas) {
    final end = _track.points.last;
    paintCarrot(canvas, end, 44, pulse: engine.carrotPulse);
    if (engine.carrotHp <= 0) {
      canvas.drawCircle(
        end,
        56,
        fill(const Color(0xFF3A0D0D).withValues(alpha: 0.35)),
      );
    }
  }

  void _paintPads(Canvas canvas) {
    for (var i = 0; i < engine.slotPositions.length; i++) {
      if (engine.towerAt(i) != null) continue;
      final armed = engine.armedKind != null;
      final affordable =
          armed && engine.gold >= towerStats(engine.armedKind!, 1).cost;
      paintPad(
        canvas,
        engine.slotPositions[i],
        27,
        armed: affordable,
        selected: engine.selectedSlot == i,
        pulse: _visualTime,
      );
    }
  }

  void _paintRange(Canvas canvas) {
    final tower = engine.selectedTower;
    if (tower == null) return;
    final center = tower.position;
    final radius = tower.stats.range;
    canvas.drawCircle(
      center,
      radius,
      fill(const Color(0xFFFFF3C4).withValues(alpha: 0.09)),
    );
    final paint = stroke(const Color(0xFFFFE08A).withValues(alpha: 0.8), 2);
    for (var angle = 0.0; angle < math.pi * 2; angle += math.pi / 18) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        math.pi / 26,
        false,
        paint,
      );
    }
    final kind = tower.canUpgrade && engine.gold >= tower.upgradeCost;
    if (kind) {
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

  void _paintTowers(Canvas canvas) {
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

  void _paintEnemies(Canvas canvas) {
    final alpha = _clock.alpha;
    final sorted = engine.enemies.where((enemy) => enemy.alive).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    for (final enemy in sorted) {
      final position = engine.enemyPosition(enemy, alpha: alpha);
      final bob = math.sin(_visualTime * 7 + enemy.id) * 1.5;
      paintEnemy(
        canvas,
        enemy.kind,
        position,
        enemy.radius,
        flash: enemy.flash,
        hpRatio: enemy.hpRatio,
        slowed: enemy.slowed,
        boss: enemy.isBoss,
        bob: bob,
      );
    }
  }

  void _paintProjectiles(Canvas canvas) {
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
        case TowerKind.lightning:
          break;
      }
    }
  }

  void _paintEffects(Canvas canvas) {
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
          _paintLightning(canvas, effect, t);
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

  void _paintLightning(Canvas canvas, Effect effect, double t) {
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
              math.sin(_visualTime * 70 + i * 2.7) * 4 * (1 - t),
              math.cos(_visualTime * 63 + i * 1.9) * 4 * (1 - t),
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

  void _paintFloaters(Canvas canvas) {
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

  TextPainter _textPainter(
    String text,
    double fontSize,
    Color color, {
    bool bold = false,
  }) {
    final key = '$text|$fontSize|${color.toARGB32()}|$bold';
    final cached = _textCache[key];
    if (cached != null) return cached;
    if (_textCache.length > 160) _textCache.clear();
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
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

class _Layout {
  const _Layout({required this.origin, required this.scale});

  final Offset origin;
  final double scale;
}

class _Blob {
  const _Blob({
    required this.position,
    required this.radius,
    required this.alpha,
    required this.light,
  });

  final Offset position;
  final double radius;
  final double alpha;
  final bool light;
}

List<_Blob> _buildBlobs(int seed) {
  final random = math.Random(seed + 5);
  return List.generate(9, (_) {
    final light = random.nextBool();
    return _Blob(
      position: Offset(
        80 + random.nextDouble() * (kDesignWidth - 160),
        50 + random.nextDouble() * (kDesignHeight - 100),
      ),
      radius: 90 + random.nextDouble() * 150,
      alpha: 0.04 + random.nextDouble() * 0.05,
      light: light,
    );
  });
}

class _Decor {
  const _Decor({
    required this.position,
    required this.kind,
    required this.scale,
    required this.flip,
  });

  final Offset position;
  final int kind;
  final double scale;
  final bool flip;
}

List<_Decor> _buildDecorations(DefenseEngine engine) {
  final random = math.Random(engine.level.seed);
  final result = <_Decor>[];
  final carrot = engine.track.points.last;
  for (var attempt = 0; attempt < 420 && result.length < 34; attempt++) {
    final position = Offset(
      40 + random.nextDouble() * (kDesignWidth - 80),
      36 + random.nextDouble() * (kDesignHeight - 72),
    );
    if (engine.track.distanceTo(position) < 52) continue;
    if ((position - carrot).distance < 96) continue;
    if ((position - engine.track.points.first).distance < 72) continue;
    var rejected = false;
    for (final slot in engine.slotPositions) {
      if ((slot - position).distance < 56) {
        rejected = true;
        break;
      }
    }
    if (rejected) continue;
    for (final other in result) {
      if ((other.position - position).distance < 44) {
        rejected = true;
        break;
      }
    }
    if (rejected) continue;
    result.add(
      _Decor(
        position: position,
        kind: random.nextInt(3),
        scale: 0.8 + random.nextDouble() * 0.55,
        flip: random.nextBool(),
      ),
    );
  }
  return result;
}
