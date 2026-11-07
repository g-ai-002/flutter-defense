import 'package:carrot_defense/flame/board_layout.dart';
import 'package:carrot_defense/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('战场布局', () {
    test('设计画布原点与右下角可精确往返', () {
      final layout = BoardLayout.resolve(const Size(1280, 720));
      expect(layout.scale, greaterThan(0.15));
      expect(layout.toDesign(layout.origin), Offset.zero);

      final bottomRight = layout.toDesign(
        layout.origin +
            Offset(kDesignWidth * layout.scale, kDesignHeight * layout.scale),
      );
      expect(bottomRight.dx, closeTo(kDesignWidth, 0.001));
      expect(bottomRight.dy, closeTo(kDesignHeight, 0.001));
      expect(layout.contains(bottomRight), isTrue);
    });

    test('画布外坐标不参与点击判定', () {
      final layout = BoardLayout.resolve(const Size(900, 540));
      expect(layout.contains(const Offset(-1, 0)), isFalse);
      expect(layout.contains(const Offset(0, -1)), isFalse);
      expect(layout.contains(const Offset(kDesignWidth + 1, 0)), isFalse);
      expect(layout.contains(const Offset(0, kDesignHeight + 1)), isFalse);
      expect(layout.contains(const Offset(kDesignWidth, kDesignHeight)), isTrue);
    });

    test('建造位按最近距离命中，超出半径返回 null', () {
      final layout = BoardLayout.resolve(const Size(1280, 720));
      const slots = [Offset(100, 100), Offset(300, 300)];

      expect(layout.slotAt(slots, const Offset(104, 100)), 0);
      expect(layout.slotAt(slots, const Offset(295, 305)), 1);
      expect(layout.slotAt(slots, const Offset(200, 200)), isNull);
      expect(layout.slotAt(const [], Offset.zero), isNull);
    });

    test('超小窗口下缩放收敛到下限且仍居中', () {
      final layout = BoardLayout.resolve(const Size(200, 320));
      expect(layout.scale, 0.15);
      expect(
        layout.origin.dx + kDesignWidth * layout.scale / 2,
        closeTo(100, 1),
      );
    });
  });
}
