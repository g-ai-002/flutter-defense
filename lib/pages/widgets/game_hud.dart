import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../flame/board_layout.dart';
import '../../game/engine/defense_engine.dart';
import '../../game/engine/entities.dart';
import '../../utils/constants.dart';
import 'hud_bottom_dock.dart';
import 'hud_info_bars.dart';

/// 战场悬浮 HUD：网格居中，信息簇悬浮在网格上方左右，控制条悬浮在网格下方。
///
/// HUD 只按网格的位置摆放，不参与战场布局，因此改变窗口尺寸或切换信息密度
/// 都不会让战场发生移位。
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.engine,
    required this.speed,
    required this.onSpeed,
    required this.onPause,
    required this.onBack,
  });

  final DefenseEngine engine;
  final double speed;
  final VoidCallback onSpeed;
  final VoidCallback onPause;
  final VoidCallback onBack;

  /// 网格在视口中的矩形，HUD 的上左右下四条边界都贴着它摆放。
  static Rect gridRectFor(Size view) {
    final layout = BoardLayout.resolve(view);
    return Rect.fromLTWH(
      layout.origin.dx + kGridOriginX * layout.scale,
      layout.origin.dy + kGridOriginY * layout.scale,
      kGridCols * kCellSize * layout.scale,
      kGridRows * kCellSize * layout.scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 战场按整屏尺寸摆放，HUD 用同一份尺寸换算网格矩形，刘海与手势条只抬高边距。
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final padding = MediaQuery.paddingOf(context);
        final compact = compactHudFor(size);
        final grid = gridRectFor(size);
        final infoHeight = hudInfoHeight(compact);
        final dockHeight = hudDockHeight(compact);
        // 上方信息簇与下方控制条都紧贴网格，并至少留出安全区与 4 像素边距。
        final topSafe = padding.top + 4;
        final bottomSafe = padding.bottom + 4;
        final top = math.max(topSafe, grid.top - infoHeight - 6);
        final bottom = math.max(bottomSafe, size.height - grid.bottom - dockHeight - 6);
        final sideInset = math.max(8.0, grid.left);
        return AnimatedBuilder(
          animation: engine.hud,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned(top: 0, left: 0, right: 0, child: _WaveProgressLine(engine: engine)),
                Positioned(
                  top: top,
                  left: sideInset,
                  child: HudStatusPanel(
                    engine: engine,
                    compact: compact,
                    width: size.width,
                    onBack: onBack,
                  ),
                ),
                Positioned(
                  top: top,
                  right: sideInset,
                  child: HudResourcePanel(engine: engine, compact: compact, width: size.width),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: bottom,
                  child: HudBottomDock(
                    engine: engine,
                    compact: compact,
                    speed: speed,
                    onSpeed: onSpeed,
                    onPause: onPause,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WaveProgressLine extends StatelessWidget {
  const _WaveProgressLine({required this.engine});

  final DefenseEngine engine;

  @override
  Widget build(BuildContext context) {
    final active = engine.status == GameStatus.battle;
    return SizedBox(
      height: 3,
      child: active
          ? LinearProgressIndicator(
              value: engine.waveProgress,
              minHeight: 3,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE4572E)),
            )
          : const SizedBox.shrink(),
    );
  }
}
