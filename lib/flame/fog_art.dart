import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/level.dart';
import 'art_utils.dart';

/// 毒雾主题色集中管理，静态毒圈、动态雾气与缩略图保持同一套配色。
const Color kFogDeep = Color(0xFF3F7A34);
const Color kFogCore = Color(0xFF6FBF4A);
const Color kFogRim = Color(0xFFB7E88A);
const Color kFogBubble = Color(0xFFD9FFAF);

/// 静态毒圈与气泡，录制进战场静态层，每帧只重放一次 Picture。
void paintFogGround(Canvas canvas, LevelDef level) {
  for (final zone in level.fog) {
    final center = zone.design;
    final radius = zone.radius;
    final random = math.Random(level.seed + zone.center.col.round() * 31);
    canvas.drawCircle(center, radius, fill(kFogDeep.withValues(alpha: 0.2)));
    canvas.drawCircle(
      center,
      radius * 0.72,
      fill(kFogCore.withValues(alpha: 0.18)),
    );
    canvas.drawCircle(
      center,
      radius,
      stroke(kFogRim.withValues(alpha: 0.3), 2.5),
    );
    for (var i = 0; i < 10; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = random.nextDouble() * radius * 0.8;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        2 + random.nextDouble() * 5,
        fill(kFogBubble.withValues(alpha: 0.22)),
      );
    }
  }
}

/// 毒圈上缓慢漂移的雾气，让静态毒圈有呼吸感。
void paintFogMist(Canvas canvas, LevelDef level, double visualTime) {
  for (final zone in level.fog) {
    final center = zone.design;
    final radius = zone.radius;
    for (var i = 0; i < 3; i++) {
      final angle = visualTime * (0.28 + i * 0.09) + i * 2.1;
      final drift = radius * (0.34 + i * 0.16);
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * drift,
        radius * (0.3 + 0.05 * math.sin(visualTime + i)),
        dynFill(kFogRim.withValues(alpha: 0.09)),
      );
    }
  }
}

/// 关卡缩略图中的毒雾预览，与战场使用同一种主色。
void paintFogThumb(Canvas canvas, LevelDef level, Offset origin, double scale) {
  for (final zone in level.fog) {
    canvas.drawCircle(
      origin + zone.design * scale,
      zone.radius * scale,
      fill(kFogCore.withValues(alpha: 0.4)),
    );
  }
}
