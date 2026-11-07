import 'dart:math' as math;
import 'dart:ui';

import '../utils/constants.dart';

/// 可点击建造位的最大命中距离（设计像素）。
const double kSlotTapRadius = 34;

/// 设计画布在屏幕上的位置与缩放，负责本地坐标与设计坐标互转。
class BoardLayout {
  const BoardLayout({required this.origin, required this.scale});

  final Offset origin;
  final double scale;

  /// 按可用屏幕空间等比缩放，并让出 HUD 占用的上下区域。
  factory BoardLayout.resolve(Size view) {
    final top = hudTopInset(view);
    final bottom = hudBottomInset(view);
    final availableHeight = math.max(1.0, view.height - top - bottom);
    var scale = math.min(
      (view.width - 24) / kDesignWidth,
      availableHeight / kDesignHeight,
    );
    scale = scale.clamp(0.15, 1.6);
    return BoardLayout(
      origin: Offset(
        (view.width - kDesignWidth * scale) / 2,
        top + (availableHeight - kDesignHeight * scale) / 2,
      ),
      scale: scale,
    );
  }

  Offset toDesign(Offset local) => (local - origin) / scale;

  bool contains(Offset design) =>
      design.dx >= 0 &&
      design.dy >= 0 &&
      design.dx <= kDesignWidth &&
      design.dy <= kDesignHeight;

  /// 返回离 [point] 最近且在 [radius] 内的建造位序号。
  int? slotAt(
    List<Offset> slots,
    Offset point, {
    double radius = kSlotTapRadius,
  }) {
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
