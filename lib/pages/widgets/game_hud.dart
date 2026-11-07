import 'package:flutter/material.dart';

import '../../game/balance.dart';
import '../../game/engine/defense_engine.dart';
import '../../game/engine/entities.dart';
import '../../models/defense_models.dart';
import '../../utils/constants.dart';
import 'tower_icon.dart';

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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _WaveProgressLine(engine: engine),
                ),
                Positioned(
                  top: compact ? 5 : 8,
                  left: 8,
                  right: 8,
                  child: _TopBar(
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
                  child: _BottomDock(engine: engine, compact: compact),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.engine,
    required this.compact,
    required this.width,
    required this.speed,
    required this.onSpeed,
    required this.onPause,
    required this.onBack,
  });

  final DefenseEngine engine;
  final bool compact;
  final double width;
  final double speed;
  final VoidCallback onSpeed;
  final VoidCallback onPause;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final showTitle = !compact && width >= 780;
    final showWaveText = width >= 700;
    final hpRatio = engine.carrotMaxHp == 0
        ? 0.0
        : engine.carrotHp / engine.carrotMaxHp;
    return Container(
      height: compact ? 38 : 46,
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
      decoration: _panelDecoration(context, radius: compact ? 13 : 15),
      child: Row(
        children: [
          _HudIconButton(
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
                    engine.status == GameStatus.preparing
                        ? '准备阶段'
                        : engine.status == GameStatus.battle
                        ? '第 ${engine.waveIndex} 波'
                        : engine.status == GameStatus.victory
                        ? '关卡完成'
                        : '防线失守',
                    maxLines: 1,
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
          _InfoPill(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFE4572E),
            label: compact
                ? '${engine.carrotHp}'
                : '萝卜 ${engine.carrotHp}/${engine.carrotMaxHp}',
            compact: compact,
            trailing: compact
                ? null
                : _MiniBar(ratio: hpRatio, color: const Color(0xFFE4572E)),
          ),
          const SizedBox(width: 5),
          _InfoPill(
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFFD99B1D),
            label: '${engine.gold}',
            compact: compact,
          ),
          if (showWaveText) ...[
            const SizedBox(width: 5),
            _InfoPill(
              icon: Icons.flag_rounded,
              iconColor: const Color(0xFF3F7D46),
              label:
                  '${engine.status == GameStatus.preparing ? engine.waveIndex + 1 : engine.waveIndex}'
                  '/${engine.level.waveCount} 波',
              compact: compact,
            ),
          ],
          const Spacer(),
          _SpeedButton(speed: speed, compact: compact, onPressed: onSpeed),
          const SizedBox(width: 2),
          _HudIconButton(
            icon: Icons.pause_rounded,
            tooltip: '暂停',
            compact: compact,
            onPressed: onPause,
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: ratio.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.compact,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: compact ? 26 : 30,
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: iconColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.speed,
    required this.compact,
    required this.onPressed,
  });

  final double speed;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: '切换战斗速度',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: compact ? 34 : 40,
          height: compact ? 28 : 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${speed % 1 == 0 ? speed.toInt() : speed}x',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.compact,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 17 : 19),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(
        width: compact ? 28 : 32,
        height: compact ? 28 : 32,
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({required this.engine, required this.compact});

  final DefenseEngine engine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = engine.selectedTower;
    final selectedSlot = engine.selectedSlot;
    return Container(
      height: compact ? 56 : 84,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, compact ? 6 : 8, 8, 6),
      decoration: _panelDecoration(context, radius: compact ? 14 : 18),
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
        for (final kind in TowerKind.values)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: _TowerCard(
              kind: kind,
              cost: towerStats(kind, 1).cost,
              enabled: engine.gold >= towerStats(kind, 1).cost,
              selected: engine.armedKind == kind,
              compact: compact,
              onTap: () => engine.toggleArmed(kind),
            ),
          ),
        if (!compact)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                engine.armedKind == null
                    ? '选择塔后点击空地建造'
                    : '点击高亮空地放下${engine.armedKind!.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
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
        for (final kind in TowerKind.values)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: _TowerCard(
              kind: kind,
              cost: towerStats(kind, 1).cost,
              enabled: engine.canBuild(kind, slot),
              selected: false,
              compact: compact,
              onTap: () => engine.build(slot, kind),
            ),
          ),
        if (!compact) const Spacer(),
        _HudIconButton(
          icon: Icons.close_rounded,
          tooltip: '取消',
          compact: compact,
          onPressed: engine.clearSelection,
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
                  '伤害 ${stats.damage.round()} · 范围 ${stats.range.round()} · '
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
        _PanelButton(
          label: tower.canUpgrade ? '升级 ${tower.upgradeCost}' : '已满级',
          icon: Icons.arrow_upward_rounded,
          enabled: canUpgrade,
          compact: compact,
          onTap: () {
            if (engine.upgrade(tower.slotIndex)) {}
          },
        ),
        const SizedBox(width: 5),
        _PanelButton(
          label: '出售 +${tower.sellValue}',
          icon: Icons.sell_outlined,
          enabled: true,
          compact: compact,
          outlined: true,
          onTap: () => engine.sell(tower.slotIndex),
        ),
        _HudIconButton(
          icon: Icons.close_rounded,
          tooltip: '取消选择',
          compact: compact,
          onPressed: engine.clearSelection,
        ),
      ],
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.compact,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 13 : 15),
        if (!compact) ...[
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 12)),
        ] else if (label.contains('升级'))
          Text(
            label.replaceAll('升级 ', ''),
            style: const TextStyle(fontSize: 11),
          ),
      ],
    );
    return Material(
      color: outlined
          ? colors.surface
          : enabled
          ? colors.primary
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: compact ? 30 : 38,
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: outlined ? Border.all(color: colors.outline) : null,
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(
              color: outlined
                  ? colors.onSurface
                  : enabled
                  ? colors.onPrimary
                  : colors.onSurfaceVariant,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: outlined
                    ? colors.onSurface
                    : enabled
                    ? colors.onPrimary
                    : colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              child: child,
            ),
          ),
        ),
      ),
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

BoxDecoration _panelDecoration(BuildContext context, {required double radius}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surface.withValues(alpha: dark ? 0.9 : 0.92),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: colors.outline.withValues(alpha: 0.75)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.3 : 0.12),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
