import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../flame/painters.dart';

/// 首页主视觉：一根戴叶子的萝卜，配柔和光晕。
class CarrotArt extends StatelessWidget {
  const CarrotArt({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CarrotPainter()),
    );
  }
}

class _CarrotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.46;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE7C4),
            const Color(0xFFFFD39A).withValues(alpha: 0.5),
            Colors.transparent,
          ],
          stops: const [0.35, 0.72, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFE4572E).withValues(alpha: 0.22);
    for (var i = 0; i < 36; i++) {
      final angle = i * math.pi / 18;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.92),
        angle,
        math.pi / 30,
        false,
        ring,
      );
    }
    paintCarrot(canvas, center + Offset(0, radius * 0.05), radius * 0.52);

    final dot = Paint()..color = const Color(0xFF3F7D46).withValues(alpha: 0.3);
    for (final item in [
      Offset(size.width * 0.2, size.height * 0.24),
      Offset(size.width * 0.82, size.height * 0.3),
      Offset(size.width * 0.18, size.height * 0.76),
      Offset(size.width * 0.78, size.height * 0.74),
    ]) {
      canvas.drawCircle(item, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
