import 'package:flutter/material.dart';

import '../../game/engine/defense_engine.dart';
import '../../game/engine/entities.dart';
import 'hud_chrome.dart';

/// 顶部信息簇的高度，战场布局据此把信息簇停在网格上方。
double hudInfoHeight(bool compact) => compact ? 34 : 40;

/// 画布左上角的关卡信息：返回、关卡名与状态、萝卜血量。
///
/// 每个元素都是独立的小卡片，不套外框，悬浮在地貌留白带上时不会形成
/// 一个压在战场上的空心矩形。
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
    final hpRatio = engine.carrotMaxHp == 0 ? 0.0 : engine.carrotHp / engine.carrotMaxHp;
    final showTitle = width >= 560;
    return SizedBox(
      height: hudInfoHeight(compact),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudIconChip(
            icon: Icons.arrow_back_rounded,
            tooltip: '返回',
            compact: compact,
            onPressed: onBack,
          ),
          const SizedBox(width: 6),
          if (showTitle) ...[
            HudTitleChip(
              title: engine.level.name,
              subtitle: _statusLabel(),
              compact: compact,
            ),
            const SizedBox(width: 6),
          ],
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

/// 画布右上角的资源信息：金币与波次进度。
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
    return SizedBox(
      height: hudInfoHeight(compact),
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
            const SizedBox(width: 6),
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
