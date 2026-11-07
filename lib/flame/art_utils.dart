import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 程序化美术共用的画笔与精灵缓存工具。

Paint fill(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.fill;

Paint stroke(Color color, double width) => Paint()
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

ui.Picture recordPicture(void Function(Canvas canvas) draw) {
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
