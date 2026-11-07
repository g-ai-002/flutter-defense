import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/defense_models.dart';
import 'art_utils.dart';

final Map<int, ui.Picture> _towerTurrets = {};

/// 炮塔形状固定，按「类型 + 半径」缓存，瞄准时只做旋转。
ui.Picture towerTurretSprite(TowerKind kind, double radius) {
  final key = kind.index * 100000 + radiusKey(radius);
  final cached = _towerTurrets[key];
  if (cached != null) return cached;
  final picture = recordPicture((canvas) {
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
      case TowerKind.poison:
        _paintPoisonTower(canvas, radius);
        break;
    }
  });
  storeSprite(_towerTurrets, key, picture);
  return picture;
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
    Rect.fromCenter(center: Offset(r * 0.12, 0), width: r * 0.9, height: r * 1.35),
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
  canvas.drawCircle(Offset(-r * 0.12, r * 0.18), r * 0.46, fill(const Color(0xFF4C3A2B)));
  canvas.drawCircle(Offset(-r * 0.12, r * 0.18), r * 0.2, fill(const Color(0xFF8C7357)));
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
  canvas.drawCircle(Offset(r * 0.88, 0), r * 0.2, fill(const Color(0xFF1B1F25)));
  canvas.drawCircle(Offset(r * 0.88, 0), r * 0.28, stroke(const Color(0xFF6E7681), r * 0.06));
  canvas.drawCircle(Offset(-r * 0.34, 0), r * 0.22, fill(const Color(0xFF3B414B)));
}

void _paintFrostTower(Canvas canvas, double r) {
  canvas.drawCircle(Offset.zero, r * 0.7, fill(const Color(0xFFBDEBFF).withValues(alpha: 0.28)));
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
      ..shader = const RadialGradient(colors: [Color(0xFFFFF6C2), Color(0xFFF2B21C)])
          .createShader(Rect.fromCircle(center: Offset(r * 0.68, -r * 0.02), radius: r * 0.24)),
  );
  final bolt = Path()
    ..moveTo(r * 0.86, -r * 0.44)
    ..lineTo(r * 0.68, -r * 0.06)
    ..lineTo(r * 0.82, -r * 0.02)
    ..lineTo(r * 0.58, r * 0.42);
  canvas.drawPath(bolt, stroke(const Color(0xFFFFF6DE), r * 0.07));
}

void _paintPoisonTower(Canvas canvas, double r) {
  // 药锅
  canvas.drawCircle(Offset.zero, r * 0.58, fill(const Color(0xFF7FD05A).withValues(alpha: 0.2)));
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-r * 0.52, -r * 0.42, r * 0.92, r * 0.8),
      Radius.circular(r * 0.3),
    ),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4F8C3A), Color(0xFF24421C)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(-r * 0.06, -r * 0.26), width: r * 0.8, height: r * 0.3),
    fill(const Color(0xFFA8E36B)),
  );
  final bubble = fill(const Color(0xFFD9FFAF));
  canvas.drawCircle(Offset(-r * 0.22, -r * 0.28), r * 0.08, bubble);
  canvas.drawCircle(Offset(r * 0.08, -r * 0.3), r * 0.05, bubble);
  // 喷口
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(r * 0.24, -r * 0.14, r * 0.58, r * 0.28),
      Radius.circular(r * 0.12),
    ),
    fill(const Color(0xFF3C5A2E)),
  );
  canvas.drawCircle(Offset(r * 0.84, 0), r * 0.15, fill(const Color(0xFFB7F28A)));
  canvas.drawCircle(Offset(r * 0.84, 0), r * 0.24, stroke(const Color(0xFF6FBF4A), r * 0.05));
}
