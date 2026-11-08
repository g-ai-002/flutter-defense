import 'package:carrot_defense/utils/constants.dart';
import 'package:carrot_defense/utils/display_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('横屏策略', () {
    test('手机竖屏下网格横向更舒展，自动进入横屏', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(prefersLandscapeGrid(const Size(400, 800)), isTrue);
      expect(shouldImmersiveLandscape(const Size(400, 800)), isTrue);
    });

    test('屏幕接近正方形时网格放大有限，保持当前方向', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(prefersLandscapeGrid(const Size(400, 400)), isFalse);
      expect(shouldImmersiveLandscape(const Size(400, 400)), isFalse);
    });

    test('平板与桌面窗口不改变方向与系统栏', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(shouldImmersiveLandscape(const Size(1000, 1600)), isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(shouldImmersiveLandscape(const Size(400, 800)), isFalse);
    });

    test('横向缩放始终不小于纵向，16:9 网格理论上更适合横屏', () {
      const phone = Size(412, 915);
      final portrait = boardScaleFor(const Size(412, 915));
      final landscape = boardScaleFor(const Size(915, 412));
      expect(landscape, greaterThan(portrait));
      expect(prefersLandscapeGrid(phone), isTrue);
    });
  });
}
