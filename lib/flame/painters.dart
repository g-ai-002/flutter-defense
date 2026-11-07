import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/defense_models.dart';

/// 塔防美术：塔、萝卜、敌人全部用 Canvas 程序化绘制，仓库不携带图片资源。

Paint fill(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.fill;

Paint stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _shadow(Canvas canvas, Offset center, double radius, double opacity) {
  canvas.drawOval(
    Rect.fromCenter(
      center: center + Offset(0, radius * 0.92),
      width: radius * 2.1,
      height: radius * 0.7,
    ),
    fill(Colors.black.withValues(alpha: opacity)),
  );
}

/// 终点萝卜：圆润的橙色身体、绿叶与表情。
void paintCarrot(
  Canvas canvas,
  Offset center,
  double radius, {
  double pulse = 0,
}) {
  final wobble = math.sin(pulse * 22) * 3 * pulse;
  canvas.save();
  canvas.translate(center.dx + wobble, center.dy);
  _shadow(canvas, Offset.zero, radius, 0.22);

  // 土堆
  canvas.drawOval(
    Rect.fromCenter(
      center: const Offset(0, 20),
      width: radius * 2.5,
      height: radius * 0.7,
    ),
    fill(const Color(0xFF8A5A32).withValues(alpha: 0.55)),
  );

  final body = Path()
    ..moveTo(-radius * 0.52, -radius * 0.35)
    ..cubicTo(
      -radius * 0.62,
      radius * 0.15,
      -radius * 0.25,
      radius * 0.75,
      0,
      radius * 1.02,
    )
    ..cubicTo(
      radius * 0.25,
      radius * 0.75,
      radius * 0.62,
      radius * 0.15,
      radius * 0.52,
      -radius * 0.35,
    )
    ..cubicTo(
      radius * 0.3,
      -radius * 0.62,
      -radius * 0.3,
      -radius * 0.62,
      -radius * 0.52,
      -radius * 0.35,
    )
    ..close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFA84D), Color(0xFFE86B21)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
  );
  canvas.drawPath(
    body,
    stroke(const Color(0xFFB9501A).withValues(alpha: 0.65), radius * 0.06),
  );

  // 高光与纹路
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(-radius * 0.22, -radius * 0.04),
      width: radius * 0.28,
      height: radius * 0.6,
    ),
    fill(Colors.white.withValues(alpha: 0.35)),
  );
  for (var i = 0; i < 3; i++) {
    final y = radius * (0.18 + i * 0.22);
    canvas.drawLine(
      Offset(-radius * 0.26, y),
      Offset(radius * 0.24, y - radius * 0.08),
      stroke(const Color(0xFFC25A1C).withValues(alpha: 0.4), radius * 0.045),
    );
  }

  // 叶子
  final leafPaint = fill(const Color(0xFF4C9B45));
  for (final angle in [-0.75, -0.15, 0.55]) {
    canvas.save();
    canvas.translate(0, -radius * 0.42);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 0.4),
        width: radius * 0.34,
        height: radius * 0.8,
      ),
      leafPaint,
    );
    canvas.restore();
  }

  // 表情
  final eye = fill(const Color(0xFF4A2A1A));
  canvas.drawCircle(Offset(-radius * 0.2, radius * 0.02), radius * 0.075, eye);
  canvas.drawCircle(Offset(radius * 0.2, radius * 0.02), radius * 0.075, eye);
  canvas.drawCircle(
    Offset(-radius * 0.17, -radius * 0.01),
    radius * 0.028,
    fill(Colors.white),
  );
  canvas.drawCircle(
    Offset(radius * 0.23, -radius * 0.01),
    radius * 0.028,
    fill(Colors.white),
  );
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(0, radius * 0.18),
      width: radius * 0.3,
      height: radius * 0.22,
    ),
    0.15,
    math.pi - 0.3,
    false,
    stroke(const Color(0xFF8A3B16), radius * 0.05),
  );
  canvas.restore();
}

/// 敌人：每种怪物有独立的轮廓与配色。
void paintEnemy(
  Canvas canvas,
  EnemyKind kind,
  Offset center,
  double radius, {
  double flash = 0,
  double hpRatio = 1,
  bool slowed = false,
  bool boss = false,
  double bob = 0,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy + bob);
  _shadow(canvas, Offset.zero, radius, 0.18);

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

  if (slowed) {
    canvas.drawCircle(
      Offset.zero,
      radius * 1.05,
      fill(const Color(0xFF7FD4FF).withValues(alpha: 0.28)),
    );
    final snow = stroke(const Color(0xFFE8FAFF), radius * 0.08);
    for (var i = 0; i < 3; i++) {
      final angle = i * math.pi / 3;
      canvas.drawLine(
        Offset(math.cos(angle), math.sin(angle)) * radius * 0.4,
        Offset(-math.cos(angle), -math.sin(angle)) * radius * 0.4,
        snow,
      );
    }
  }
  if (flash > 0) {
    canvas.drawCircle(
      Offset.zero,
      radius * 1.02,
      fill(Colors.white.withValues(alpha: flash.clamp(0.0, 0.7))),
    );
  }
  canvas.restore();

  if (hpRatio < 0.999) {
    final width = boss ? radius * 3 : radius * 2.2;
    final top = center.dy - radius - 10;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - width / 2, top, width, 5),
        const Radius.circular(3),
      ),
      fill(Colors.black.withValues(alpha: 0.45)),
    );
    final color = hpRatio > 0.5
        ? const Color(0xFF7ED957)
        : hpRatio > 0.25
        ? const Color(0xFFF7C948)
        : const Color(0xFFF2665A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - width / 2, top, width * hpRatio, 5),
        const Radius.circular(3),
      ),
      fill(color),
    );
  }
}

void _eyes(Canvas canvas, double radius, {Color color = const Color(0xFF2A2118)}) {
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
  canvas.drawPath(
    body,
    stroke(const Color(0xFF3E7F2D), radius * 0.07),
  );
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
  canvas.drawRRect(
    body,
    stroke(const Color(0xFF5A3A22), radius * 0.08),
  );
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

/// 防御塔绘制。角度 0 表示炮口朝右。
void paintTower(
  Canvas canvas,
  TowerKind kind,
  Offset center,
  double radius, {
  double angle = -math.pi / 2,
  int level = 1,
  double recoil = 0,
  bool selected = false,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);

  if (selected) {
    canvas.drawCircle(
      Offset.zero,
      radius * 1.18,
      stroke(const Color(0xFFFFE08A), radius * 0.09),
    );
  }

  _shadow(canvas, Offset.zero, radius, 0.2);
  canvas.drawCircle(
    Offset.zero,
    radius * 1.02,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB98A5E), Color(0xFF7B5233)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
  );
  canvas.drawCircle(
    Offset.zero,
    radius * 1.02,
    stroke(const Color(0xFF5C3A22), radius * 0.06),
  );
  canvas.drawCircle(
    Offset.zero,
    radius * 0.78,
    fill(const Color(0xFFD9B183).withValues(alpha: 0.55)),
  );

  canvas.save();
  canvas.rotate(angle);
  canvas.translate(-recoil * radius * 0.16, 0);
  switch (kind) {
    case TowerKind.arrow:
      _paintArrowTower(canvas, radius);
      break;
    case TowerKind.cannon:
      _paintCannonTower(canvas, radius);
      break;
    case TowerKind.frost:
      _paintFrostTower(canvas, radius);
      break;
    case TowerKind.lightning:
      _paintLightningTower(canvas, radius);
      break;
  }
  canvas.restore();

  // 等级宝石
  for (var i = 0; i < 3; i++) {
    final active = i < level;
    canvas.drawCircle(
      Offset((i - 1) * radius * 0.36, radius * 0.78),
      radius * 0.11,
      fill(
        active
            ? const Color(0xFFFFD24D)
            : const Color(0xFF3B2A1C).withValues(alpha: 0.5),
      ),
    );
  }
  canvas.restore();
}

void _paintArrowTower(Canvas canvas, double r) {
  final wood = fill(const Color(0xFF8A5A32));
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-r * 0.5, -r * 0.14, r * 1.0, r * 0.28),
      Radius.circular(r * 0.12),
    ),
    wood,
  );
  canvas.drawCircle(Offset.zero, r * 0.24, fill(const Color(0xFF5E3C22)));
  // 弓臂
  final bow = stroke(const Color(0xFF4B2E18), r * 0.12);
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(r * 0.12, 0),
      width: r * 0.9,
      height: r * 1.35,
    ),
    -math.pi / 2,
    math.pi,
    false,
    bow,
  );
  canvas.drawLine(
    Offset(r * 0.12, -r * 0.66),
    Offset(r * 0.12, r * 0.66),
    stroke(const Color(0xFFE6D3B3), r * 0.035),
  );
  // 箭
  canvas.drawLine(
    Offset(r * 0.02, 0),
    Offset(r * 0.82, 0),
    stroke(const Color(0xFFF3E2BF), r * 0.07),
  );
  final head = Path()
    ..moveTo(r * 1.02, 0)
    ..lineTo(r * 0.76, -r * 0.12)
    ..lineTo(r * 0.76, r * 0.12)
    ..close();
  canvas.drawPath(head, fill(const Color(0xFFD9DEE2)));
}

void _paintCannonTower(Canvas canvas, double r) {
  // 炮轮
  canvas.drawCircle(
    Offset(-r * 0.12, r * 0.18),
    r * 0.46,
    fill(const Color(0xFF4C3A2B)),
  );
  canvas.drawCircle(
    Offset(-r * 0.12, r * 0.18),
    r * 0.2,
    fill(const Color(0xFF8C7357)),
  );
  // 炮身
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-r * 0.34, -r * 0.24, r * 1.3, r * 0.48),
      Radius.circular(r * 0.22),
    ),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5C6470), Color(0xFF272C34)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
  );
  canvas.drawCircle(
    Offset(r * 0.88, 0),
    r * 0.2,
    fill(const Color(0xFF1B1F25)),
  );
  canvas.drawCircle(
    Offset(r * 0.88, 0),
    r * 0.28,
    stroke(const Color(0xFF6E7681), r * 0.06),
  );
  canvas.drawCircle(Offset(-r * 0.34, 0), r * 0.22, fill(const Color(0xFF3B414B)));
}

void _paintFrostTower(Canvas canvas, double r) {
  canvas.drawCircle(
    Offset.zero,
    r * 0.7,
    fill(const Color(0xFFBDEBFF).withValues(alpha: 0.28)),
  );
  final crystal = Path()
    ..moveTo(r * 0.9, 0)
    ..lineTo(r * 0.18, -r * 0.52)
    ..lineTo(-r * 0.52, 0)
    ..lineTo(r * 0.18, r * 0.52)
    ..close();
  canvas.drawPath(
    crystal,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD8F6FF), Color(0xFF62B9E6)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
  );
  canvas.drawPath(crystal, stroke(const Color(0xFF3E7FA6), r * 0.05));
  canvas.drawLine(
    Offset(-r * 0.2, 0),
    Offset(r * 0.9, 0),
    stroke(Colors.white.withValues(alpha: 0.7), r * 0.05),
  );
  for (var i = 0; i < 3; i++) {
    final a = i * math.pi / 3;
    canvas.drawLine(
      Offset(math.cos(a), math.sin(a)) * r * 0.25,
      Offset(-math.cos(a), -math.sin(a)) * r * 0.25,
      stroke(const Color(0xFFE9FBFF), r * 0.05),
    );
  }
}

void _paintLightningTower(Canvas canvas, double r) {
  final metal = fill(const Color(0xFF5A5470));
  for (var i = 0; i < 3; i++) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r * (0.1 + i * 0.2), r * 0.05),
        width: r * 0.26,
        height: r * 0.8 - i * r * 0.12,
      ),
      metal,
    );
  }
  canvas.drawCircle(
    Offset(r * 0.68, -r * 0.02),
    r * 0.36,
    fill(const Color(0xFFFFE36B).withValues(alpha: 0.28)),
  );
  canvas.drawCircle(
    Offset(r * 0.68, -r * 0.02),
    r * 0.22,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF6C2), Color(0xFFF2B21C)],
      ).createShader(
        Rect.fromCircle(center: Offset(r * 0.68, -r * 0.02), radius: r * 0.24),
      ),
  );
  final bolt = Path()
    ..moveTo(r * 0.86, -r * 0.44)
    ..lineTo(r * 0.68, -r * 0.06)
    ..lineTo(r * 0.82, -r * 0.02)
    ..lineTo(r * 0.58, r * 0.42);
  canvas.drawPath(bolt, stroke(const Color(0xFFFFF6DE), r * 0.07));
}

/// 空建造位：石制圆台 + 加号。
void paintPad(
  Canvas canvas,
  Offset center,
  double radius, {
  bool armed = false,
  bool selected = false,
  double pulse = 0,
}) {
  canvas.drawOval(
    Rect.fromCenter(
      center: center + Offset(0, radius * 0.55),
      width: radius * 2.2,
      height: radius * 0.7,
    ),
    fill(Colors.black.withValues(alpha: 0.14)),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF0EAD8), Color(0xFFC8BE9E)],
      ).createShader(Rect.fromCircle(center: center, radius: radius)),
  );
  canvas.drawCircle(
    center,
    radius,
    stroke(const Color(0xFF8E866A), radius * 0.08),
  );
  canvas.drawCircle(
    center,
    radius * 0.74,
    fill(const Color(0xFF7F775E).withValues(alpha: 0.18)),
  );

  if (armed || selected) {
    final glow = armed ? const Color(0xFF9BE36C) : const Color(0xFFFFE08A);
    final spread = radius * (1.1 + 0.06 * math.sin(pulse * 4));
    canvas.drawCircle(
      center,
      spread,
      stroke(glow.withValues(alpha: 0.85), radius * 0.1),
    );
    canvas.drawCircle(
      center,
      spread + radius * 0.08,
      stroke(glow.withValues(alpha: 0.25), radius * 0.16),
    );
  }
  final plus = stroke(const Color(0xFF6E654C).withValues(alpha: 0.8), radius * 0.12);
  canvas.drawLine(
    center + Offset(-radius * 0.26, 0),
    center + Offset(radius * 0.26, 0),
    plus,
  );
  canvas.drawLine(
    center + Offset(0, -radius * 0.26),
    center + Offset(0, radius * 0.26),
    plus,
  );
}

/// UI 中的塔图标：与战场塔同一套绘制，缩放到指定尺寸。
void paintTowerIcon(
  Canvas canvas,
  TowerKind kind,
  Offset center,
  double radius,
) {
  paintTower(canvas, kind, center, radius, angle: -0.5, level: 1);
}
