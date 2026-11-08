import 'dart:ui';

import '../utils/constants.dart';

/// 可点击建造位的最大命中距离（设计像素）。
const double kSlotTapRadius = 34;

/// 设计画布在屏幕上的位置与缩放，负责本地坐标与设计坐标互转。
class BoardLayout {
  const BoardLayout({required this.origin, required this.scale, required this.view});

  final Offset origin;
  final double scale;
  final Size view;

  /// 按窗口尺寸等比缩放：画布至少有一条边正好撑满窗口，另一方向居中，
  /// 战场网格因此始终位于屏幕正中，且尽量放大到窗口能容纳的极限。
  ///
  /// 画布外的区域由延伸到窗口边缘的地貌填满，不会再出现黑边；
  /// HUD 直接贴住窗口边缘，不参与缩放计算。
  factory BoardLayout.resolve(Size view) {
    final scale = boardScaleFor(view);
    return BoardLayout(
      origin: Offset(
        (view.width - kDesignWidth * scale) / 2,
        (view.height - kDesignHeight * scale) / 2,
      ),
      scale: scale,
      view: view,
    );
  }

  /// 视口在设计坐标中的可见范围，用于确认地面是否铺满整个窗口。
  Rect get visibleDesign => Rect.fromLTRB(
    -origin.dx / scale,
    -origin.dy / scale,
    (view.width - origin.dx) / scale,
    (view.height - origin.dy) / scale,
  );

  /// 设计画布在屏幕上的矩形，HUD 依此把信息簇贴到画布的边角。
  Rect get rect => Rect.fromLTWH(origin.dx, origin.dy, kDesignWidth * scale, kDesignHeight * scale);

  /// 网格在屏幕上的矩形：信息簇贴在网格上方，控制条贴在网格下方。
  Rect get gridRect => Rect.fromLTWH(
    origin.dx + kGridOriginX * scale,
    origin.dy + kGridOriginY * scale,
    kGridCols * kCellSize * scale,
    kGridRows * kCellSize * scale,
  );

  Offset toDesign(Offset local) => (local - origin) / scale;

  bool contains(Offset design) =>
      design.dx >= 0 && design.dy >= 0 && design.dx <= kDesignWidth && design.dy <= kDesignHeight;

  /// 返回离 [point] 最近且在 [radius] 内的建造位序号。
  int? slotAt(List<Offset> slots, Offset point, {double radius = kSlotTapRadius}) {
    var best = -1;
    var bestDistance = radius;
    for (var i = 0; i < slots.length; i++) {
      final distance = (slots[i] - point).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best < 0 ? null : best;
  }
}
