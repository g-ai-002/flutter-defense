import 'package:flutter/material.dart';

import '../../game/engine/defense_engine.dart';
import '../../game/engine/entities.dart';
import '../../utils/constants.dart';
import 'hud_bottom_dock.dart';
import 'hud_top_bar.dart';

/// 战场悬浮 HUD：四周贴边显示信息、塔栏与开波按钮，不参与战场布局。
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final compact = compactHudFor(size);
        return AnimatedBuilder(
          animation: engine.hud,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned(top: 0, left: 0, right: 0, child: _WaveProgressLine(engine: engine)),
                Positioned(
                  top: compact ? 5 : 8,
                  left: 8,
                  right: 8,
                  child: HudTopBar(
                    engine: engine,
                    compact: compact,
                    width: size.width,
                    speed: speed,
                    onSpeed: onSpeed,
                    onPause: onPause,
                    onBack: onBack,
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: compact ? 6 : 8,
                  child: HudBottomDock(engine: engine, compact: compact),
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
