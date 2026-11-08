import 'package:flutter/material.dart';

import '../../game/engine/defense_engine.dart';
import '../../game/engine/entities.dart';
import 'hud_chrome.dart';

/// 顶部信息条的高度，战场布局据此在网格上方留出悬浮空间。
double hudInfoHeight(bool compact) => compact ? 38 : 46;

/// 网格上方左侧的关卡信息：返回、关卡名与状态、萝卜血量。
class HudStatusPanel extends StatelessWidget {
  const HudStatusPanel({
    super.key,
    required this.engine,
    required this.compact,
    required this.width,
    required this.onBack,
  });

  final DefenseEngine engine;
  final bool compact;
  final double width;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final showTitle = !compact && width >= 780;
    final hpRatio = engine.carrotMaxHp == 0 ? 0.0 : engine.carrotHp / engine.carrotMaxHp;
    return Container(
      height: hudInfoHeight(compact),
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
      decoration: hudPanelDecoration(context, radius: compact ? 13 : 15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: '返回',
            compact: compact,
            onPressed: onBack,
          ),
          if (showTitle) ...[
            const SizedBox(width: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    engine.level.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _statusLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 4),
          HudInfoPill(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFE4572E),
            label: compact ? '${engine.carrotHp}' : '萝卜 ${engine.carrotHp}/${engine.carrotMaxHp}',
            compact: compact,
            trailing: compact ? null : HudMiniBar(ratio: hpRatio, color: const Color(0xFFE4572E)),
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    return switch (engine.status) {
      GameStatus.preparing => '准备阶段',
      GameStatus.battle =>
        engine.endless
            ? '无尽 · 第 ${engine.waveIndex} 波'
            : engine.daily
            ? '每日挑战 · 第 ${engine.waveIndex} 波'
            : '第 ${engine.waveIndex} 波',
      GameStatus.victory => '关卡完成',
      GameStatus.defeat =>
        engine.endless
            ? '无尽挑战结束'
            : engine.daily
            ? '每日挑战结束'
            : '防线失守',
    };
  }
}

/// 网格上方右侧的资源信息：金币与波次进度。
class HudResourcePanel extends StatelessWidget {
  const HudResourcePanel({
    super.key,
    required this.engine,
    required this.compact,
    required this.width,
  });

  final DefenseEngine engine;
  final bool compact;
  final double width;

  @override
  Widget build(BuildContext context) {
    final showWaveText = width >= 700;
    return Container(
      height: hudInfoHeight(compact),
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
      decoration: hudPanelDecoration(context, radius: compact ? 13 : 15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudInfoPill(
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFFD99B1D),
            label: '${engine.gold}',
            compact: compact,
          ),
          if (showWaveText) ...[
            const SizedBox(width: 5),
            HudInfoPill(
              icon: Icons.flag_rounded,
              iconColor: const Color(0xFF3F7D46),
              label: engine.scored
                  ? '第 ${_displayWave()} 波'
                  : '${_displayWave()}/${engine.level.waveCount} 波',
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }

  int _displayWave() =>
      engine.status == GameStatus.preparing ? engine.waveIndex + 1 : engine.waveIndex;
}
