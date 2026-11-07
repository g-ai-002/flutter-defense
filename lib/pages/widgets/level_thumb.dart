import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/level.dart';
import '../../theme/level_theme.dart';
import '../../utils/constants.dart';

/// 关卡缩略图：按真实路径与建造位绘制迷你地图。
class LevelThumb extends StatelessWidget {
  const LevelThumb({super.key, required this.level, this.locked = false});

  final LevelDef level;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ThumbPainter(level, locked),
      child: const SizedBox.expand(),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.level, this.locked);

  final LevelDef level;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = paletteOf(level.theme);
    final rect = Offset.zero & size;
    final clip = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.save();
    canvas.clipRRect(clip);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            locked ? const Color(0xFFB9B3A5) : palette.groundTop,
            locked ? const Color(0xFF8E887B) : palette.groundBottom,
          ],
        ).createShader(rect),
    );

    final scale = math.min(
      size.width / kDesignWidth,
      size.height / kDesignHeight,
    );
    final origin = Offset(
      (size.width - kDesignWidth * scale) / 2,
      (size.height - kDesignHeight * scale) / 2,
    );
    Offset map(double col, double row) =>
        origin + gridToDesign(col, row) * scale;

    final path = Path();
    for (var i = 0; i < level.path.length; i++) {
      final point = map(level.path[i].col, level.path[i].row);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final road = locked ? const Color(0xFFA19A8C) : palette.pathFill;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(4, 26 * scale)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = road,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, 12 * scale)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.18),
    );
    for (final slot in level.slots) {
      final point = map(slot.col, slot.row);
      canvas.drawCircle(
        point,
        math.max(2.2, 13 * scale),
        Paint()..color = Colors.white.withValues(alpha: locked ? 0.25 : 0.55),
      );
    }
    final end = map(level.path.last.col, level.path.last.row);
    canvas.drawCircle(
      end,
      math.max(4, 22 * scale),
      Paint()..color = locked ? Colors.white24 : const Color(0xFFE4572E),
    );
    canvas.drawCircle(
      end,
      math.max(2, 8 * scale),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.18)],
          stops: const [0.65, 1],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter oldDelegate) =>
      oldDelegate.level.id != level.id || oldDelegate.locked != locked;
}
