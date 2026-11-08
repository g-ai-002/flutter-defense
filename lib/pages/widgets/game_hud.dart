import 'package:flutter/material.dart';

import '../../flame/board_layout.dart';
import '../../game/engine/defense_engine.dart';
import '../../game/engine/entities.dart';
import '../../utils/constants.dart';
import 'hud_bottom_dock.dart';
import 'hud_info_bars.dart';

/// 战场悬浮 HUD：地面铺满窗口，信息簇贴在窗口左上/右上安全区，控制条贴住屏幕底部。
///
/// HUD 不参与战场缩放：窗口变大时战场能一直放大到窗口容得下的极限，
/// 改变信息密度或窗口比例也不会让战场发生移位。
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

  /// 网格在视口中的矩形，供布局测试确认 HUD 不遮挡网格。
  static Rect gridRectFor(Size view) => BoardLayout.resolve(view).gridRect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final padding = MediaQuery.paddingOf(context);
        final compact = compactHudFor(size);
        final top = padding.top + (compact ? 4 : 6);
        final left = 8 + padding.left;
        final right = 8 + padding.right;
        // 控制条直接贴住屏幕最下方（含手势条等安全区），不再随窗口比例上浮。
        final dockBottom = padding.bottom;
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
