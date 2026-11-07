import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/engine/entities.dart';
import '../models/defense_models.dart';
import 'art_utils.dart';

final Map<int, ui.Picture> _projectiles = {};
ui.Picture? _cannonShadow;

/// 弹道形状固定，按塔类型录制一次，发射期间只做平移、旋转与抛物线位移。
ui.Picture _projectileSprite(TowerKind kind) {
  final cached = _projectiles[kind.index];
  if (cached != null) return cached;
  final picture = recordPicture((canvas) {
    switch (kind) {
      case TowerKind.arrow:
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
        break;
      case TowerKind.cannon:
        canvas.drawCircle(Offset.zero, 7, fill(const Color(0xFF2A2A30)));
        canvas.drawCircle(const Offset(-2, -2), 2.5, fill(const Color(0xFF8E8E99)));
        break;
      case TowerKind.frost:
        canvas.drawCircle(
          Offset.zero,
          10,
          Paint()
            ..shader = const RadialGradient(colors: [Color(0x479FE6FF), Color(0x009FE6FF)])
                .createShader(Rect.fromCircle(center: Offset.zero, radius: 10)),
        );
        final shard = Path()
          ..moveTo(8, 0)
          ..lineTo(0, -5)
          ..lineTo(-8, 0)
          ..lineTo(0, 5)
          ..close();
        canvas.drawPath(shard, fill(const Color(0xFFCFF4FF)));
        canvas.drawPath(shard, stroke(const Color(0xFF6EC6EC), 1.5));
        break;
      case TowerKind.poison:
        canvas.drawCircle(Offset.zero, 9, fill(const Color(0xFF6FBF4A).withValues(alpha: 0.9)));
        canvas.drawCircle(const Offset(-3, 2), 7, stroke(const Color(0xFFCBEF9A), 1.4));
        canvas.drawCircle(const Offset(3, -3), 2.4, fill(const Color(0xFFE7FFCB)));
        break;
      case TowerKind.lightning:
        break;
    }
  });
  storeSprite(_projectiles, kind.index, picture);
  return picture;
}

ui.Picture _cannonShadowSprite() {
  final cached = _cannonShadow;
  if (cached != null) return cached;
  final picture = recordPicture((canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 16, height: 6),
      fill(Colors.black.withValues(alpha: 0.22)),
    );
  });
  _cannonShadow = picture;
  return picture;
}

/// 绘制一枚飞行中的弹道。
void paintProjectile(Canvas canvas, Projectile projectile) {
  final position = projectile.position;
  switch (projectile.kind) {
    case TowerKind.arrow:
    case TowerKind.frost:
      final direction = projectile.lastTarget - position;
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(math.atan2(direction.dy, direction.dx));
      canvas.drawPicture(_projectileSprite(projectile.kind));
      canvas.restore();
      break;
    case TowerKind.cannon:
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.drawPicture(_cannonShadowSprite());
      canvas.translate(0, -math.sin(projectile.progress * math.pi) * 26);
      canvas.drawPicture(_projectileSprite(TowerKind.cannon));
      canvas.restore();
      break;
    case TowerKind.poison:
      canvas.save();
      canvas.translate(position.dx, position.dy - math.sin(projectile.progress * math.pi) * 12);
      canvas.drawPicture(_projectileSprite(TowerKind.poison));
      canvas.restore();
      break;
    case TowerKind.lightning:
      break;
  }
}
