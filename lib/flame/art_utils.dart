import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 程序化美术共用的画笔与精灵缓存工具。

/// 新建 Paint 的次数，供性能回归测试确认动态层复用画笔。
int debugPaintBuilds = 0;

Paint fill(Color color) => _newPaint()..color = color;

Paint stroke(Color color, double width) => _newPaint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint _newPaint() {
  debugPaintBuilds++;
  return Paint();
}

/// 动态层复用画笔：逐帧的特效、状态叠加与血条只改颜色线宽，不再新建 Paint。
final Paint _dynPaint = Paint();

Paint dynFill(Color color) => _dynPaint
  ..color = color
  ..style = PaintingStyle.fill;

Paint dynStroke(Color color, double width) => _dynPaint
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void paintShadow(Canvas canvas, Offset center, double radius, double opacity) {
  canvas.drawOval(
    Rect.fromCenter(
      center: center + Offset(0, radius * 0.92),
      width: radius * 2.1,
      height: radius * 0.7,
    ),
    fill(Colors.black.withValues(alpha: opacity)),
  );
}

/// 精灵缓存按半径缩放 10 倍取整，避免浮点误差产生重复图层。
int radiusKey(double radius) => (radius * 10).round();

/// 精灵录制总次数，供性能回归测试确认重复绘制全部命中缓存。
int debugSpriteBuilds = 0;

ui.Picture recordPicture(void Function(Canvas canvas) draw) {
  debugSpriteBuilds++;
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  return recorder.endRecording();
}

/// 缓存超过上限时整体释放，防止长时间运行累积旧尺寸的图层。
const int kSpriteCacheLimit = 48;

void storeSprite(Map<int, ui.Picture> cache, int key, ui.Picture picture) {
  if (cache.length >= kSpriteCacheLimit) {
    for (final item in cache.values) {
      item.dispose();
    }
    cache.clear();
  }
  cache[key] = picture;
}
