import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/defense_models.dart';
import 'art_utils.dart';

final Map<int, ui.Picture> _enemyBodies = {};

/// 敌人身体形状固定，按「类型 + 半径」缓存为 Picture，每帧只做平移。
ui.Picture enemyBodySprite(EnemyKind kind, double radius) {
  final key = kind.index * 100000 + radiusKey(radius);
  final cached = _enemyBodies[key];
  if (cached != null) return cached;
  final picture = recordPicture((canvas) {
    paintShadow(canvas, Offset.zero, radius, 0.18);
    switch (kind) {
      case EnemyKind.slime:
        _paintSlime(canvas, radius);
        break;
      case EnemyKind.runner:
        _paintRunner(canvas, radius);
        break;
      case EnemyKind.beetle:
        _paintBeetle(canvas, radius);
        break;
      case EnemyKind.tank:
        _paintTank(canvas, radius);
        break;
      case EnemyKind.boss:
        _paintBoss(canvas, radius);
        break;
    }
  });
  storeSprite(_enemyBodies, key, picture);
  return picture;
}

void _eyes(
  Canvas canvas,
  double radius, {
  Color color = const Color(0xFF2A2118),
}) {
  final eye = fill(color);
  canvas.drawCircle(Offset(-radius * 0.3, -radius * 0.08), radius * 0.13, eye);
  canvas.drawCircle(Offset(radius * 0.3, -radius * 0.08), radius * 0.13, eye);
  canvas.drawCircle(
    Offset(-radius * 0.27, -radius * 0.12),
    radius * 0.045,
    fill(Colors.white),
  );
  canvas.drawCircle(
    Offset(radius * 0.33, -radius * 0.12),
    radius * 0.045,
    fill(Colors.white),
  );
}

void _paintSlime(Canvas canvas, double radius) {
  final body = Path()
    ..moveTo(-radius, radius * 0.62)
    ..cubicTo(
      -radius,
      -radius * 0.55,
      radius,
      -radius * 0.55,
      radius,
      radius * 0.62,
    )
    ..quadraticBezierTo(0, radius * 0.92, -radius, radius * 0.62)
    ..close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9BE36C), Color(0xFF5BAE3E)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
  );
  canvas.drawPath(body, stroke(const Color(0xFF3E7F2D), radius * 0.07));
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(0, radius * 0.3),
      width: radius * 1.2,
      height: radius * 0.55,
    ),
    fill(const Color(0xFFC6F0A5).withValues(alpha: 0.5)),
  );
  _eyes(canvas, radius);
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(0, radius * 0.2),
      width: radius * 0.42,
      height: radius * 0.3,
    ),
    0.2,
    math.pi - 0.4,
    false,
    stroke(const Color(0xFF2A4A1C), radius * 0.05),
  );
  // 小叶子
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(radius * 0.42, -radius * 0.62),
      width: radius * 0.25,
      height: radius * 0.4,
    ),
    fill(const Color(0xFF3E7F2D)),
  );
}

void _paintRunner(Canvas canvas, double radius) {
  final fur = fill(const Color(0xFFF2A867));
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(0, radius * 0.1),
      width: radius * 1.55,
      height: radius * 1.7,
    ),
    fur,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(0, radius * 0.38),
      width: radius * 1.0,
      height: radius * 0.8,
    ),
    fill(const Color(0xFFFFE7CB)),
  );
  // 耳朵
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.translate(side * radius * 0.38, -radius * 0.62);
    canvas.rotate(side * 0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 0.28),
        width: radius * 0.34,
        height: radius * 0.85,
      ),
      fur,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 0.24),
        width: radius * 0.16,
        height: radius * 0.55,
      ),
      fill(const Color(0xFFFFC7B0)),
    );
    canvas.restore();
  }
  _eyes(canvas, radius);
  canvas.drawCircle(
    Offset(0, radius * 0.16),
    radius * 0.08,
    fill(const Color(0xFFC46A4A)),
  );
  // 脚
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(-radius * 0.42, radius * 0.82),
      width: radius * 0.48,
      height: radius * 0.26,
    ),
    fill(const Color(0xFFD9834C)),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(radius * 0.42, radius * 0.82),
      width: radius * 0.48,
      height: radius * 0.26,
    ),
    fill(const Color(0xFFD9834C)),
  );
}

void _paintBeetle(Canvas canvas, double radius) {
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(0, radius * 0.12),
      width: radius * 1.9,
      height: radius * 1.65,
    ),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF77848F), Color(0xFF3C4650)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(0, radius * 0.12),
      width: radius * 1.9,
      height: radius * 1.65,
    ),
    stroke(const Color(0xFF252D35), radius * 0.08),
  );
  canvas.drawLine(
    Offset(0, -radius * 0.68),
    Offset(0, radius * 0.85),
    stroke(const Color(0xFF232B32).withValues(alpha: 0.7), radius * 0.07),
  );
  for (final side in [-1.0, 1.0]) {
    for (var i = 0; i < 2; i++) {
      canvas.drawCircle(
        Offset(side * radius * 0.42, radius * (0.0 + i * 0.42)),
        radius * 0.11,
        fill(const Color(0xFF9FB0BC).withValues(alpha: 0.6)),
      );
    }
  }
  // 独角
  final horn = Path()
    ..moveTo(radius * 0.05, -radius * 0.7)
    ..lineTo(radius * 0.3, -radius * 1.25)
    ..lineTo(radius * 0.4, -radius * 0.62)
    ..close();
  canvas.drawPath(horn, fill(const Color(0xFF20272D)));
  _eyes(canvas, radius, color: const Color(0xFF11171B));
  // 头甲
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(0, -radius * 0.2),
      width: radius * 1.1,
      height: radius * 0.9,
    ),
    math.pi,
    math.pi,
    false,
    stroke(const Color(0xFF56636D), radius * 0.1),
  );
}

void _paintTank(Canvas canvas, double radius) {
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(0, radius * 0.08),
      width: radius * 1.95,
      height: radius * 1.75,
    ),
    Radius.circular(radius * 0.55),
  );
  canvas.drawRRect(
    body,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB98A5E), Color(0xFF7A5232)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
  );
  canvas.drawRRect(body, stroke(const Color(0xFF5A3A22), radius * 0.08));
  // 岩甲
  for (final side in [-1.0, 1.0]) {
    canvas.drawCircle(
      Offset(side * radius * 0.62, -radius * 0.18),
      radius * 0.28,
      fill(const Color(0xFF8C6239)),
    );
    canvas.drawCircle(
      Offset(side * radius * 0.62, -radius * 0.18),
      radius * 0.28,
      stroke(const Color(0xFF5A3A22), radius * 0.05),
    );
  }
  _eyes(canvas, radius, color: const Color(0xFF2B1A0E));
  // 獠牙
  for (final side in [-1.0, 1.0]) {
    final tusk = Path()
      ..moveTo(side * radius * 0.24, radius * 0.34)
      ..lineTo(side * radius * 0.34, radius * 0.66)
      ..lineTo(side * radius * 0.12, radius * 0.42)
      ..close();
    canvas.drawPath(tusk, fill(const Color(0xFFF4E8CE)));
  }
  // 脚
  for (final side in [-1.0, 1.0]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(side * radius * 0.55, radius * 0.88),
        width: radius * 0.55,
        height: radius * 0.26,
      ),
      fill(const Color(0xFF5D3E24)),
    );
  }
}

void _paintBoss(Canvas canvas, double radius) {
  canvas.drawCircle(
    Offset.zero,
    radius * 1.15,
    fill(const Color(0xFF9A5BC7).withValues(alpha: 0.22)),
  );
  final body = Path()
    ..moveTo(-radius, radius * 0.55)
    ..cubicTo(
      -radius * 1.1,
      -radius * 0.75,
      radius * 1.1,
      -radius * 0.75,
      radius,
      radius * 0.55,
    )
    ..quadraticBezierTo(0, radius * 1.0, -radius, radius * 0.55)
    ..close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB77FE0), Color(0xFF6A3C9E)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
  );
  canvas.drawPath(body, stroke(const Color(0xFF43236B), radius * 0.07));
  // 角
  for (final side in [-1.0, 1.0]) {
    final horn = Path()
      ..moveTo(side * radius * 0.6, -radius * 0.68)
      ..lineTo(side * radius * 0.92, -radius * 1.2)
      ..lineTo(side * radius * 0.78, -radius * 0.55)
      ..close();
    canvas.drawPath(horn, fill(const Color(0xFF3A2350)));
  }
  // 王冠
  final crown = Path()
    ..moveTo(-radius * 0.46, -radius * 0.62)
    ..lineTo(-radius * 0.36, -radius * 1.02)
    ..lineTo(-radius * 0.12, -radius * 0.76)
    ..lineTo(0, -radius * 1.12)
    ..lineTo(radius * 0.14, -radius * 0.76)
    ..lineTo(radius * 0.38, -radius * 1.02)
    ..lineTo(radius * 0.46, -radius * 0.6)
    ..close();
  canvas.drawPath(crown, fill(const Color(0xFFFFC94A)));
  canvas.drawPath(crown, stroke(const Color(0xFFB87A1D), radius * 0.04));
  // 眼睛
  final eye = fill(const Color(0xFFFF4D4D));
  canvas.drawCircle(Offset(-radius * 0.3, -radius * 0.05), radius * 0.15, eye);
  canvas.drawCircle(Offset(radius * 0.3, -radius * 0.05), radius * 0.15, eye);
  canvas.drawCircle(
    Offset(-radius * 0.27, -radius * 0.08),
    radius * 0.05,
    fill(const Color(0xFFFFE8E8)),
  );
  canvas.drawCircle(
    Offset(radius * 0.33, -radius * 0.08),
    radius * 0.05,
    fill(const Color(0xFFFFE8E8)),
  );
  // 獠牙与嘴
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(0, radius * 0.28),
      width: radius * 0.56,
      height: radius * 0.4,
    ),
    math.pi + 0.15,
    math.pi - 0.3,
    false,
    stroke(const Color(0xFF321B47), radius * 0.06),
  );
  for (final side in [-1.0, 1.0]) {
    final tusk = Path()
      ..moveTo(side * radius * 0.22, radius * 0.34)
      ..lineTo(side * radius * 0.3, radius * 0.62)
      ..lineTo(side * radius * 0.1, radius * 0.4)
      ..close();
    canvas.drawPath(tusk, fill(const Color(0xFFF6EDDA)));
  }
}
