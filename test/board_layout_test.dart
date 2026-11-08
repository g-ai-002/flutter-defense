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
        layout.origin + Offset(kDesignWidth * layout.scale, kDesignHeight * layout.scale),
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
      final layout = BoardLayout.resolve(const Size(100, 320));
      expect(layout.scale, 0.15);
      expect(layout.origin.dx + kDesignWidth * layout.scale / 2, closeTo(50, 1));
    });

    test('网格在任意视口中都位于屏幕正中', () {
      const views = [
        Size(1280, 720),
        Size(1200, 700),
        Size(800, 450),
        Size(360, 640),
        Size(1600, 900),
        Size(1024, 1366),
      ];
      for (final view in views) {
        final layout = BoardLayout.resolve(view);
        final center =
            layout.origin +
            Offset(
              kGridOriginX + kGridCols * kCellSize / 2,
              kGridOriginY + kGridRows * kCellSize / 2,
            ) *
                layout.scale;
        expect(center.dx, closeTo(view.width / 2, 0.001), reason: '$view 横向应居中');
        expect(center.dy, closeTo(view.height / 2, 0.001), reason: '$view 纵向应居中');
      }
    });

    test('战场画布至少有一条边撑满窗口，另一方向居中留出等宽黑边', () {
      const views = [
        Size(1280, 720),
        Size(1200, 700),
        Size(800, 450),
        Size(360, 640),
        Size(1600, 900),
        Size(1024, 1366),
      ];
      for (final view in views) {
        final layout = BoardLayout.resolve(view);
        final board = layout.rect;
        final fillsWidth = (board.width - view.width).abs() < 0.01;
        final fillsHeight = (board.height - view.height).abs() < 0.01;
        expect(
          fillsWidth || fillsHeight,
          isTrue,
          reason: '$view 至少有一条边应撑满窗口，实际 $board',
        );
        expect((view.width - board.width) / 2, closeTo(board.left, 0.001), reason: '$view 横向留白应对称');
        expect((view.height - board.height) / 2, closeTo(board.top, 0.001), reason: '$view 纵向留白应对称');
      }
    });

    test('网格上下留出等高的地貌悬浮带', () {
      const views = [Size(1280, 720), Size(1200, 700), Size(800, 360), Size(360, 640)];
      for (final view in views) {
        final layout = BoardLayout.resolve(view);
        final grid = layout.gridRect;
        expect(grid.top, closeTo(view.height - grid.bottom, 0.001), reason: '$view 上下留白应对称');
        expect(grid.top, greaterThan(0));
        expect(grid.bottom, lessThan(view.height + 0.001));
      }
    });
  });
}
