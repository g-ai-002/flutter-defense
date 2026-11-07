import 'package:flutter/material.dart';

import '../../flame/painters.dart';
import '../../models/defense_models.dart';

/// 界面里的防御塔图标，与战场使用同一套绘制。
class TowerIcon extends StatelessWidget {
  const TowerIcon({super.key, required this.kind, this.size = 40});

  final TowerKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TowerIconPainter(kind)),
    );
  }
}

class _TowerIconPainter extends CustomPainter {
  const _TowerIconPainter(this.kind);

  final TowerKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    paintTowerIcon(canvas, kind, Offset(size.width / 2, size.height / 2), size.width * 0.36);
  }

  @override
  bool shouldRepaint(covariant _TowerIconPainter oldDelegate) => oldDelegate.kind != kind;
}
