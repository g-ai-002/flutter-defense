import 'dart:ui';

import '../utils/constants.dart';

/// 可点击建造位的最大命中距离（设计像素）。
const double kSlotTapRadius = 34;

/// 设计画布在屏幕上的位置与缩放，负责本地坐标与设计坐标互转。
class BoardLayout {
  const BoardLayout({required this.origin, required this.scale});

  final Offset origin;
  final double scale;

  /// 按可用屏幕空间等比缩放，设计画布在视口中水平与垂直都精确居中。
  ///
  /// 上下预留带由 [hudReserveFor] 给出且两侧一致，HUD 悬浮在带内，
  /// 因此战场网格始终位于屏幕正中，不会被顶部信息或底部控制条挤偏。
  factory BoardLayout.resolve(Size view) {
    final scale = boardScaleFor(view);
    return BoardLayout(
      origin: Offset(
        (view.width - kDesignWidth * scale) / 2,
        (view.height - kDesignHeight * scale) / 2,
      ),
      scale: scale,
    );
  }

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
