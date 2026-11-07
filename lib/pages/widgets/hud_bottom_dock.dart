import 'package:flutter/material.dart';

import '../../game/balance.dart';
import '../../game/engine/defense_engine.dart';
import '../../game/engine/entities.dart';
import '../../models/defense_models.dart';
import 'hud_chrome.dart';
import 'tower_icon.dart';

/// HUD 底栏：建造/升级/出售面板与开波按钮。
class HudBottomDock extends StatelessWidget {
  const HudBottomDock({super.key, required this.engine, required this.compact});

  final DefenseEngine engine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = engine.selectedTower;
    final selectedSlot = engine.selectedSlot;
    return Container(
      height: compact ? 56 : 84,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, compact ? 6 : 8, 8, 6),
      decoration: hudPanelDecoration(context, radius: compact ? 14 : 18),
      child: Row(
        children: [
          Expanded(
            child: selected != null
                ? _TowerPanel(engine: engine, tower: selected, compact: compact)
                : selectedSlot != null
                ? _BuildPanel(
                    engine: engine,
                    slot: selectedSlot,
                    compact: compact,
                  )
                : _ShopPanel(engine: engine, compact: compact),
          ),
          SizedBox(width: compact ? 5 : 8),
          _WaveButton(engine: engine, compact: compact),
        ],
      ),
    );
  }
}

class _ShopPanel extends StatelessWidget {
  const _ShopPanel({required this.engine, required this.compact});

  final DefenseEngine engine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '建造',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _TowerCardStrip(engine: engine, compact: compact),
          ),
        ),
      ],
    );
  }
}

class _BuildPanel extends StatelessWidget {
  const _BuildPanel({
    required this.engine,
    required this.slot,
    required this.compact,
  });

  final DefenseEngine engine;
  final int slot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (!compact) ...[
          Icon(
            Icons.add_location_alt_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            '空地建造',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _TowerCardStrip(
              engine: engine,
              compact: compact,
              slot: slot,
            ),
          ),
        ),
        HudIconButton(
          icon: Icons.close_rounded,
          tooltip: '取消',
          compact: compact,
          onPressed: engine.clearSelection,
        ),
      ],
    );
  }
}

/// 塔栏卡片条：默认点击进入布塔模式，指定空地时直接建造。
class _TowerCardStrip extends StatelessWidget {
  const _TowerCardStrip({
    required this.engine,
    required this.compact,
    this.slot,
  });

  final DefenseEngine engine;
  final bool compact;
  final int? slot;

  @override
  Widget build(BuildContext context) {
    final buildSlot = slot;
    return Row(
      children: [
        for (final kind in TowerKind.values)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: _TowerCard(
              kind: kind,
              cost: towerStats(kind, 1).cost,
              enabled: buildSlot != null
                  ? engine.canBuild(kind, buildSlot)
                  : engine.gold >= towerStats(kind, 1).cost,
              selected: buildSlot == null && engine.armedKind == kind,
              compact: compact,
              onTap: () => buildSlot != null
                  ? engine.build(buildSlot, kind)
                  : engine.toggleArmed(kind),
            ),
          ),
      ],
    );
  }
}

class _TowerPanel extends StatelessWidget {
  const _TowerPanel({
    required this.engine,
    required this.tower,
    required this.compact,
  });

  final DefenseEngine engine;
  final Tower tower;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stats = tower.stats;
    final canUpgrade = tower.canUpgrade && engine.gold >= tower.upgradeCost;
    return Row(
      children: [
        TowerIcon(kind: tower.kind, size: compact ? 34 : 42),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tower.kind.label} · Lv.${tower.level}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 13,
                ),
              ),
              if (!compact)
                Text(
                  '伤害 ${stats.damage.round()}'
                  '${stats.poisonDps > 0 ? ' +毒${stats.poisonDps.round()}/s' : ''} · '
                  '范围 ${stats.range.round()} · '
                  '${stats.interval.toStringAsFixed(2)}s',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: compact ? 4 : 8),
        HudPanelButton(
          label: tower.canUpgrade ? '升级 ${tower.upgradeCost}' : '已满级',
          icon: Icons.arrow_upward_rounded,
          enabled: canUpgrade,
          compact: compact,
          onTap: () => engine.upgrade(tower.slotIndex),
        ),
        const SizedBox(width: 5),
        HudPanelButton(
          label: '出售 +${tower.sellValue}',
          icon: Icons.sell_outlined,
          enabled: true,
          compact: compact,
          outlined: true,
          onTap: () => engine.sell(tower.slotIndex),
        ),
        HudIconButton(
          icon: Icons.close_rounded,
          tooltip: '取消选择',
          compact: compact,
          onPressed: engine.clearSelection,
        ),
      ],
    );
  }
}

class _TowerCard extends StatelessWidget {
  const _TowerCard({
    required this.kind,
    required this.cost,
    required this.enabled,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final TowerKind kind;
  final int cost;
  final bool enabled;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tone = switch (kind) {
      TowerKind.arrow => const Color(0xFF8A5A32),
      TowerKind.cannon => const Color(0xFF4C5560),
      TowerKind.frost => const Color(0xFF3E7FA6),
      TowerKind.lightning => const Color(0xFFA66A1E),
      TowerKind.poison => const Color(0xFF4F8C3A),
    };
    final muted = !enabled && !selected;
    return Opacity(
      opacity: muted ? 0.48 : 1,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.14)
            : colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled || selected ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: compact ? 58 : 88,
            height: compact ? 44 : 62,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 7,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.outline.withValues(alpha: 0.5),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: compact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TowerIcon(kind: kind, size: 22),
                      Text(
                        '$cost',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      TowerIcon(kind: kind, size: 36),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kind.label.replaceAll('塔', ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tone,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on_rounded,
                                    size: 10,
                                    color: Color(0xFFD99B1D),
                                  ),
                                  const SizedBox(width: 1),
                                  Text(
                                    '$cost',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _WaveButton extends StatelessWidget {
  const _WaveButton({required this.engine, required this.compact});

  final DefenseEngine engine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final preparing = engine.status == GameStatus.preparing;
    final nextWave = (engine.waveIndex + 1).clamp(1, engine.level.waveCount);

    if (preparing) {
      return SizedBox(
        width: compact ? 108 : 154,
        height: double.infinity,
        child: FilledButton(
          onPressed: engine.startNextWave,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '开始第 $nextWave 波',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                compact
                    ? '${engine.prepTimer.ceil()}s +${engine.earlyBonus}'
                    : '${engine.prepTimer.ceil()}s · 提前 +${engine.earlyBonus} 金',
                maxLines: 1,
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final battle = engine.status == GameStatus.battle;
    return Container(
      width: compact ? 108 : 154,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            battle
                ? '第 ${engine.waveIndex}/${engine.level.waveCount} 波'
                : engine.status == GameStatus.victory
                ? '全部清理'
                : '防线失守',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (battle) ...[
            const SizedBox(height: 3),
            Text(
              '剩余 ${engine.remainingEnemies}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: engine.waveProgress,
                minHeight: 3,
                backgroundColor: colors.surface,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE4572E)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
