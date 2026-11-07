import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/defense_models.dart';
import 'art_utils.dart';
import 'enemy_art.dart';
import 'tower_art.dart';

export 'art_utils.dart' show dynFill, dynStroke, fill, recordPicture, stroke;

/// 塔防美术入口：萝卜、敌人、塔与建造台全部用 Canvas 程序化绘制。
///
/// 敌人身体、塔身与炮塔形状固定，按「类型 + 半径」录制为 Picture 后复用，
/// 每帧只做一次平移/旋转，避免重复创建 Path、Shader 与 Paint。

final Map<int, ui.Picture> _towerBodies = {};
final Map<int, ui.Picture> _padBases = {};
final Map<int, ui.Picture> _carrots = {};

/// 塔身、等级宝石与投影一起录制，升级后按「类型 + 等级 + 半径」取新图层。
ui.Picture _towerBodySprite(TowerKind kind, int level, double radius) {
  final key = kind.index * 1000000 + level * 100000 + radiusKey(radius);
  final cached = _towerBodies[key];
  if (cached != null) return cached;
  final picture = recordPicture((canvas) {
    paintShadow(canvas, Offset.zero, radius, 0.2);
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
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset((i - 1) * radius * 0.36, radius * 0.78),
        radius * 0.11,
        fill(
          i < level
              ? const Color(0xFFFFD24D)
              : const Color(0xFF3B2A1C).withValues(alpha: 0.5),
        ),
      );
    }
  });
  storeSprite(_towerBodies, key, picture);
  return picture;
}

ui.Picture _padBaseSprite(double radius) {
  final key = radiusKey(radius);
  final cached = _padBases[key];
  if (cached != null) return cached;
  final picture = recordPicture((canvas) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, radius * 0.55),
        width: radius * 2.2,
        height: radius * 0.7,
      ),
      fill(Colors.black.withValues(alpha: 0.14)),
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0EAD8), Color(0xFFC8BE9E)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      stroke(const Color(0xFF8E866A), radius * 0.08),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.74,
      fill(const Color(0xFF7F775E).withValues(alpha: 0.18)),
    );
    final plus = stroke(
      const Color(0xFF6E654C).withValues(alpha: 0.8),
      radius * 0.12,
    );
    canvas.drawLine(Offset(-radius * 0.26, 0), Offset(radius * 0.26, 0), plus);
    canvas.drawLine(Offset(0, -radius * 0.26), Offset(0, radius * 0.26), plus);
  });
  storeSprite(_padBases, key, picture);
  return picture;
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
  canvas.drawPicture(_carrotSprite(radius));
  canvas.restore();
}

ui.Picture _carrotSprite(double radius) {
  final key = radiusKey(radius);
  final cached = _carrots[key];
  if (cached != null) return cached;
  final picture = recordPicture((canvas) {
    _paintCarrotBody(canvas, radius);
  });
  storeSprite(_carrots, key, picture);
  return picture;
}

void _paintCarrotBody(Canvas canvas, double radius) {
  paintShadow(canvas, Offset.zero, radius, 0.22);

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
  bool poisoned = false,
  bool boss = false,
  double bob = 0,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy + bob);
  canvas.drawPicture(enemyBodySprite(kind, radius));

  if (poisoned) {
    canvas.drawCircle(
      Offset.zero,
      radius * 1.02,
      dynFill(const Color(0xFF7FD05A).withValues(alpha: 0.2)),
    );
    for (var i = 0; i < 3; i++) {
      final angle = i * 2.1 + 0.4;
      canvas.drawCircle(
        Offset(math.cos(angle), math.sin(angle)) * radius * 0.72,
        radius * 0.11,
        dynFill(const Color(0xFFC9F79B).withValues(alpha: 0.8)),
      );
    }
  }
  if (slowed) {
    canvas.drawCircle(
      Offset.zero,
      radius * 1.05,
      dynFill(const Color(0xFF7FD4FF).withValues(alpha: 0.28)),
    );
    for (var i = 0; i < 3; i++) {
      final angle = i * math.pi / 3;
      canvas.drawLine(
        Offset(math.cos(angle), math.sin(angle)) * radius * 0.4,
        Offset(-math.cos(angle), -math.sin(angle)) * radius * 0.4,
        dynStroke(const Color(0xFFE8FAFF), radius * 0.08),
      );
    }
  }
  if (flash > 0) {
    canvas.drawCircle(
      Offset.zero,
      radius * 1.02,
      dynFill(Colors.white.withValues(alpha: flash.clamp(0.0, 0.7))),
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
      dynFill(Colors.black.withValues(alpha: 0.45)),
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
      dynFill(color),
    );
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
      dynStroke(const Color(0xFFFFE08A), radius * 0.09),
    );
  }

  canvas.drawPicture(_towerBodySprite(kind, level, radius));

  canvas.save();
  canvas.rotate(angle);
  if (recoil > 0) canvas.translate(-recoil * radius * 0.16, 0);
  canvas.drawPicture(towerTurretSprite(kind, radius));
  canvas.restore();
  canvas.restore();
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
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.drawPicture(_padBaseSprite(radius));

  if (armed || selected) {
    final glow = armed ? const Color(0xFF9BE36C) : const Color(0xFFFFE08A);
    final spread = radius * (1.1 + 0.06 * math.sin(pulse * 4));
    canvas.drawCircle(
      Offset.zero,
      spread,
      dynStroke(glow.withValues(alpha: 0.85), radius * 0.1),
    );
    canvas.drawCircle(
      Offset.zero,
      spread + radius * 0.08,
      dynStroke(glow.withValues(alpha: 0.25), radius * 0.16),
    );
  }
  canvas.restore();
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
