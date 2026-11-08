import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../flame/board_layout.dart';
import '../../game/engine/defense_engine.dart';
import '../../game/engine/entities.dart';
import '../../utils/constants.dart';
import 'hud_bottom_dock.dart';
import 'hud_info_bars.dart';

/// 战场悬浮 HUD：战场画布撑满窗口，信息簇悬浮在画布左上/右上角，控制条悬浮在下方。
///
/// HUD 只按画布与网格的位置摆放，不参与战场缩放，因此窗口变大时战场能一直放大到
/// 窗口容得下的极限，改变信息密度也不会让战场发生移位。
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

  /// 网格在视口中的矩形，信息簇与控制条都贴在它上下。
  static Rect gridRectFor(Size view) => BoardLayout.resolve(view).gridRect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final padding = MediaQuery.paddingOf(context);
        final compact = compactHudFor(size);
        final layout = BoardLayout.resolve(size);
        final board = layout.rect;
        final grid = layout.gridRect;
        final infoHeight = hudInfoHeight(compact);
        final dockHeight = hudDockHeight(compact);
        final topSafe = padding.top + 4;
        final bottomSafe = padding.bottom + 4;
        // 信息簇贴住画布上边缘与左右边缘，形成一个明确的 HUD 角标，
        // 不会像贴在战场中央的小方框；空间不够时退回安全区并停在网格上方。
        final top = math.max(topSafe, math.min(board.top + 8, grid.top - infoHeight - 6));
        final left = math.max(8 + padding.left, board.left + 10);
        final right = math.max(8 + padding.right, size.width - board.right + 10);
        // 控制条优先落在网格下方的地貌留白带里，窗口过矮时贴住窗口底部，
        // 但始终排在信息簇下方，避免两者叠在一起。
        final dockTop = math.max(
          top + infoHeight + 4,
          math.min(grid.bottom + 6, size.height - bottomSafe - dockHeight),
        );
        final dockBottom = math.max(bottomSafe, size.height - dockTop - dockHeight);
        return AnimatedBuilder(
          animation: engine.hud,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned(top: 0, left: 0, right: 0, child: _WaveProgressLine(engine: engine)),
                Positioned(
                  top: top,
                  left: left,
                  child: HudStatusPanel(
                    engine: engine,
                    compact: compact,
                    width: size.width,
                    onBack: onBack,
                  ),
                ),
                Positioned(
                  top: top,
                  right: right,
                  child: HudResourcePanel(engine: engine, compact: compact, width: size.width),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: dockBottom,
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
