import 'package:material_ui/material_ui.dart';

import '../game/engine/defense_engine.dart';
import 'board_ground.dart';
import 'board_layout.dart';

/// 战场静态地貌：独立图层绘制，外层 [RepaintBoundary] 让 Flutter 跨帧复用光栅缓存。
///
/// 地貌、装饰、土路、毒圈与传送门都不随战斗变化。此前它们和敌人、特效一起
/// 在 Flame 画布里逐帧重放，静态图层里数百次绘制调用每帧都要重新执行；
/// 拆到独立图层后，只有窗口尺寸变化时才需要重新光栅化。
class BoardBackdrop extends StatefulWidget {
  const BoardBackdrop({super.key, required this.engine});

  final DefenseEngine engine;

  @override
  State<BoardBackdrop> createState() => _BoardBackdropState();
}

class _BoardBackdropState extends State<BoardBackdrop> {
  late final BoardGround _ground = BoardGround(engine: widget.engine);

  @override
  void dispose() {
    _ground.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // 地貌向画布外延伸，裁到视口后缓存纹理只占一屏，不会按延伸范围申请大图。
      child: ClipRect(
        child: CustomPaint(
          willChange: false,
          painter: BoardGroundPainter(_ground),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// 把设计坐标下的静态地貌铺到当前视口，缩放与点击布局共用 [BoardLayout]。
class BoardGroundPainter extends CustomPainter {
  BoardGroundPainter(this.ground);

  final BoardGround ground;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final layout = BoardLayout.resolve(size);
    canvas.save();
    canvas.translate(layout.origin.dx, layout.origin.dy);
    canvas.scale(layout.scale);
    ground.paintStatic(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BoardGroundPainter oldDelegate) => !identical(oldDelegate.ground, ground);
}
