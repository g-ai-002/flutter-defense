import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Gradient;

import '../game/engine/defense_engine.dart';
import '../game/engine/path_track.dart';
import '../theme/level_theme.dart';
import '../utils/constants.dart';
import 'art_utils.dart';
import 'board_layout.dart';
import 'fog_art.dart' as fog;

/// 战场静态层：地貌、装饰、土路、起点底座与屏幕背景，录制后复用。
class BoardGround {
  BoardGround({required this.engine}) {
    _decorations = _buildDecorations(engine);
    _blobs = _buildBlobs(engine.level.seed);
  }

  final DefenseEngine engine;
  late final List<_Decor> _decorations;
  late final List<_Blob> _blobs;

  ui.Picture? _staticLayer;
  ui.Picture? _backdropLayer;
  ui.Picture? _startGlow;
  Size _backdropSize = Size.zero;
  int _staticLayerBuilds = 0;
  int _backdropBuilds = 0;

  LevelPalette get _palette => paletteOf(engine.level.theme);
  PathTrack get _track => engine.track;

  /// 静态图层被录制的次数，供性能回归测试确认缓存生效。
  int get staticLayerBuilds => _staticLayerBuilds;

  /// 屏幕背景图层被录制的次数，尺寸不变时应保持为 1。
  int get backdropBuilds => _backdropBuilds;

  void paintBackdrop(Canvas canvas, Size view, BoardLayout layout) {
    if (_backdropLayer == null || _backdropSize != view) {
      _backdropLayer?.dispose();
      final recorder = ui.PictureRecorder();
      _recordBackdrop(Canvas(recorder), view, layout);
      _backdropLayer = recorder.endRecording();
      _backdropSize = view;
      _backdropBuilds++;
    }
    canvas.drawPicture(_backdropLayer!);
  }

  /// 地貌、装饰、土路与起点底座都是静态内容，只录制一次。
  void paintStatic(Canvas canvas) {
    if (_staticLayer == null) _buildStaticLayer();
    canvas.drawPicture(_staticLayer!);
  }

  /// 起点光圈录制为渐变精灵，每帧只按呼吸节奏缩放，不再实时模糊。
  void paintStartGlow(Canvas canvas, double visualTime) {
    final start = _track.start;
    final scale = 0.92 + 0.16 * math.sin(visualTime * 2);
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.scale(scale);
    canvas.drawPicture(_startGlowSprite());
    canvas.restore();
  }

  void dispose() {
    _staticLayer?.dispose();
    _backdropLayer?.dispose();
    _startGlow?.dispose();
    _staticLayer = null;
    _backdropLayer = null;
    _startGlow = null;
  }

  ui.Picture _startGlowSprite() {
    final cached = _startGlow;
    if (cached != null) return cached;
    final picture = recordPicture((canvas) {
      final rect = Rect.fromCircle(center: Offset.zero, radius: 24);
      canvas.drawCircle(
        Offset.zero,
        24,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x59B84DFF), Color(0x00B84DFF)])
              .createShader(rect),
      );
    });
    _startGlow = picture;
    return picture;
  }

  void _buildStaticLayer() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintGround(canvas);
    _paintDecorations(canvas);
    _paintPath(canvas);
    fog.paintFogGround(canvas, engine.level);
    _paintPortals(canvas);
    _paintStartBase(canvas);
    _staticLayer = recorder.endRecording();
    _staticLayerBuilds++;
  }

  void _recordBackdrop(Canvas canvas, Size view, BoardLayout layout) {
    final rect = Offset.zero & view;
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
          colors: [palette.accent.withValues(alpha: 0.18), palette.accent.withValues(alpha: 0)],
        ).createShader(glow),
    );
    final shadowRect = Rect.fromLTWH(
      layout.origin.dx,
      layout.origin.dy,
      kDesignWidth * layout.scale,
      kDesignHeight * layout.scale,
    );
    final shadow = RRect.fromRectAndRadius(shadowRect, const Radius.circular(28));
    // 用三层同心圆角矩形代替实时高斯模糊，静态背景重放时更省 GPU。
    for (var i = 3; i >= 1; i--) {
      canvas.drawRRect(
        shadow.inflate(i * 7.0),
        Paint()..color = Colors.black.withValues(alpha: 0.09),
      );
    }
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
        Rect.fromCenter(center: blob.position, width: blob.radius * 2, height: blob.radius * 1.3),
        Paint()
          ..color = (blob.light ? Colors.white : palette.groundDeep).withValues(alpha: blob.alpha),
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
          colors: [Colors.transparent, palette.groundDeep.withValues(alpha: 0.35)],
          stops: const [0.6, 1],
        ).createShader(rect),
    );
  }

  void _paintDecorations(Canvas canvas) {
    final palette = _palette;
    final painters = switch (engine.level.theme) {
      LevelTheme.meadow => [_tree, _flower, _bush],
      LevelTheme.forest => [_tree, _mushroom, _bush],
      LevelTheme.desert => [_cactus, _rock, _bush],
      LevelTheme.snow => [_pine, _rock, _ice],
      LevelTheme.lava => [_deadTree, _rock, _lavaCrack],
      LevelTheme.night => [_tree, _lantern, _reed],
    };
    for (final decor in _decorations) {
      canvas.save();
      canvas.translate(decor.position.dx, decor.position.dy);
      canvas.scale(decor.scale * (decor.flip ? -1 : 1), decor.scale);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 6), width: 34, height: 10),
        fill(Colors.black.withValues(alpha: 0.12)),
      );
      painters[decor.kind](canvas, palette);
      canvas.restore();
    }
  }

  void _tree(Canvas canvas, LevelPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -18, 8, 26), const Radius.circular(3)),
      fill(palette.decorPrimary),
    );
    final leaf = fill(palette.decorSecondary);
    for (final (dx, dy, radius) in const [
      (0.0, -30.0, 18.0),
      (-12.0, -22.0, 13.0),
      (12.0, -22.0, 14.0),
    ]) {
      canvas.drawCircle(Offset(dx, dy), radius, leaf);
    }
    canvas.drawCircle(const Offset(-4, -34), 9, fill(Colors.white.withValues(alpha: 0.16)));
  }

  void _flower(Canvas canvas, LevelPalette palette) {
    canvas.drawLine(const Offset(0, 2), const Offset(0, -14), stroke(const Color(0xFF4C8F3B), 2));
    final petal = fill(palette.decorSecondary);
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi / 2.5;
      canvas.drawCircle(Offset(math.cos(angle) * 6, -14 + math.sin(angle) * 6), 4.5, petal);
    }
    canvas.drawCircle(const Offset(0, -14), 3, fill(const Color(0xFFF2A03D)));
  }

  void _bush(Canvas canvas, LevelPalette palette) {
    final color = fill(palette.decorPrimary);
    for (final (dx, dy, radius) in const [
      (-8.0, -6.0, 11.0),
      (8.0, -6.0, 12.0),
      (0.0, -13.0, 10.0),
    ]) {
      canvas.drawCircle(Offset(dx, dy), radius, color);
    }
    canvas.drawOval(
      const Rect.fromLTWH(-16, -4, 32, 7),
      fill(Colors.black.withValues(alpha: 0.08)),
    );
  }

  void _mushroom(Canvas canvas, LevelPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -14, 10, 18), const Radius.circular(4)),
      fill(const Color(0xFFF2E7D0)),
    );
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, -14), width: 36, height: 30),
      math.pi,
      math.pi,
      true,
      fill(palette.decorSecondary),
    );
    final dot = fill(Colors.white.withValues(alpha: 0.65));
    for (final (dx, dy, radius) in const [(-7.0, -20.0, 3.0), (8.0, -17.0, 2.4)]) {
      canvas.drawCircle(Offset(dx, dy), radius, dot);
    }
  }

  void _cactus(Canvas canvas, LevelPalette palette) {
    final paint = fill(palette.decorPrimary);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -30, 12, 34), const Radius.circular(6)),
      paint,
    );
    for (final rect in const [
      Rect.fromLTWH(-18, -20, 12, 7),
      Rect.fromLTWH(-18, -26, 7, 12),
      Rect.fromLTWH(8, -15, 12, 7),
      Rect.fromLTWH(14, -22, 7, 13),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    }
  }

  void _rock(Canvas canvas, LevelPalette palette) {
    canvas.drawPath(
      Path()
        ..moveTo(-18, 4)
        ..lineTo(-12, -12)
        ..lineTo(2, -18)
        ..lineTo(16, -8)
        ..lineTo(18, 4)
        ..close(),
      fill(palette.padStoneDark),
    );
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

  void _pine(Canvas canvas, LevelPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -10, 6, 16), const Radius.circular(2)),
      fill(const Color(0xFF6B4A2E)),
    );
    final branch = fill(palette.decorPrimary);
    final snow = fill(palette.decorSecondary.withValues(alpha: 0.75));
    for (var i = 0; i < 3; i++) {
      final width = 26.0 - i * 6;
      final y = -10.0 - i * 11;
      canvas.drawPath(
        Path()
          ..moveTo(-width, y)
          ..lineTo(0, y - 18)
          ..lineTo(width, y)
          ..close(),
        branch,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-width * 0.7, y - 4)
          ..lineTo(0, y - 16)
          ..lineTo(width * 0.7, y - 4)
          ..close(),
        snow,
      );
    }
  }

  void _ice(Canvas canvas, LevelPalette palette) {
    final crystal = Path()
      ..moveTo(0, -26)
      ..lineTo(9, -8)
      ..lineTo(0, 4)
      ..lineTo(-9, -8)
      ..close();
    canvas.drawPath(
      crystal,
      Paint()
        ..shader = LinearGradient(colors: [palette.decorSecondary, const Color(0xFF6FAEC8)])
            .createShader(const Rect.fromLTWH(-10, -28, 20, 34)),
    );
    canvas.drawPath(crystal, stroke(Colors.white.withValues(alpha: 0.6), 1.4));
  }

  void _deadTree(Canvas canvas, LevelPalette palette) {
    final color = palette.decorPrimary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -22, 8, 28), const Radius.circular(3)),
      fill(color),
    );
    final branch = stroke(color, 3);
    canvas.drawLine(const Offset(0, -16), const Offset(-16, -26), branch);
    canvas.drawLine(const Offset(0, -10), const Offset(14, -20), branch);
    canvas.drawLine(const Offset(-10, -22), const Offset(-13, -32), branch);
  }

  void _lavaCrack(Canvas canvas, LevelPalette palette) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 16),
      fill(const Color(0xFF3A241E)),
    );
    final paint = stroke(palette.decorSecondary, 2.4);
    canvas.drawLine(const Offset(-14, 0), const Offset(-4, -3), paint);
    canvas.drawLine(const Offset(-4, -3), const Offset(4, 3), paint);
    canvas.drawLine(const Offset(4, 3), const Offset(14, 0), paint);
    canvas.drawCircle(
      Offset.zero,
      12,
      Paint()
        ..color = palette.decorSecondary.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _lantern(Canvas canvas, LevelPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -26, 4, 30), const Radius.circular(2)),
      fill(const Color(0xFF2F4A54)),
    );
    canvas.drawCircle(
      const Offset(0, -28),
      12,
      Paint()
        ..color = palette.decorSecondary.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(const Offset(0, -28), 7, fill(palette.decorSecondary));
    canvas.drawLine(
      const Offset(-6, -34),
      const Offset(6, -34),
      stroke(const Color(0xFF2F4A54), 2),
    );
  }

  void _reed(Canvas canvas, LevelPalette palette) {
    final paint = stroke(palette.decorPrimary, 2.2);
    for (var i = 0; i < 5; i++) {
      final x = (i - 2) * 6.0;
      canvas.drawLine(Offset(x, 4), Offset(x * 1.5, -24 - i * 2), paint);
    }
    canvas.drawOval(const Rect.fromLTWH(-2, -32, 5, 10), fill(const Color(0xFF7C5C3A)));
  }

  void _paintPath(Canvas canvas) {
    final palette = _palette;
    final light = engine.level.hasBranch ? 0.2 : 0.35;
    for (final track in engine.tracks) {
      final path = Path();
      final points = track.points;
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, stroke(palette.pathEdge, 60));
      canvas.drawPath(path, stroke(palette.pathFill, 50));
      canvas.drawPath(path, stroke(palette.pathLight.withValues(alpha: light), 26));

      // 路面碎石与虚线
      final random = math.Random(engine.level.seed + 31);
      for (var distance = 26.0; distance < track.length; distance += 44) {
        final point = track.pointAt(distance);
        final tangent = track.tangentAt(distance);
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
      for (var distance = 30.0; distance < track.length - 40; distance += 58) {
        final a = track.pointAt(distance);
        final b = track.pointAt(math.min(distance + 24, track.length));
        canvas.drawLine(a, b, dash);
      }
    }
  }

  /// 传送门入口与出口：紫色漩涡静态记录，动态层只补粒子与跳跃反馈。
  void _paintPortals(Canvas canvas) {
    for (final portal in engine.level.portals) {
      for (final center in [portal.entryDesign, portal.exitDesign]) {
        final rect = Rect.fromCircle(center: center, radius: 44);
        canvas.drawCircle(
          center,
          44,
          Paint()
            ..shader = const RadialGradient(colors: [Color(0x997C4DFF), Color(0x002A0A4A)])
                .createShader(rect),
        );
        canvas.drawCircle(center, 31, stroke(const Color(0xFF7C4DFF), 3));
        canvas.drawCircle(center, 21, stroke(Colors.white.withValues(alpha: 0.5), 1.6));
        for (var i = 0; i < 4; i++) {
          final angle = i * math.pi / 2 + 0.7;
          canvas.drawCircle(
            center + Offset(math.cos(angle), math.sin(angle)) * 26,
            4,
            fill(const Color(0xFFD9C4FF)),
          );
        }
      }
    }
  }

  void _paintStartBase(Canvas canvas) {
    final start = _track.start;
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
        ..shader = const RadialGradient(colors: [Color(0xFF2B1B2C), Color(0xFF120B10)])
            .createShader(Rect.fromCircle(center: start, radius: 28)),
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
  }
}

typedef _Blob = ({Offset position, double radius, double alpha, bool light});

List<_Blob> _buildBlobs(int seed) {
  final random = math.Random(seed + 5);
  return List.generate(9, (_) {
    final light = random.nextBool();
    return (
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

typedef _Decor = ({Offset position, int kind, double scale, bool flip});

List<_Decor> _buildDecorations(DefenseEngine engine) {
  final random = math.Random(engine.level.seed);
  final result = <_Decor>[];
  final track = engine.track;
  final carrot = track.end;
  final portals = [
    for (final portal in engine.level.portals) ...[portal.entryDesign, portal.exitDesign],
  ];
  for (var attempt = 0; attempt < 420 && result.length < 34; attempt++) {
    final position = Offset(
      40 + random.nextDouble() * (kDesignWidth - 80),
      36 + random.nextDouble() * (kDesignHeight - 72),
    );
    var nearRoad = false;
    for (final route in engine.tracks) {
      if (route.distanceTo(position) < 52) {
        nearRoad = true;
        break;
      }
    }
    if (nearRoad) continue;
    if ((position - carrot).distance < 96) continue;
    if ((position - track.start).distance < 72) continue;
    if (portals.any((portal) => (portal - position).distance < 72)) continue;
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
    result.add((
      position: position,
      kind: random.nextInt(3),
      scale: 0.8 + random.nextDouble() * 0.55,
      flip: random.nextBool(),
    ));
  }
  return result;
}
