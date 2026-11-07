import 'package:flutter/material.dart';

import '../../game/engine/defense_engine.dart';
import '../../models/endless.dart';
import '../../models/level.dart';
import '../../theme/app_theme.dart';
import 'overlay_shell.dart';

/// 关卡结算：胜利用星级与统计收束，失败给出下一步建议。
class GameResultOverlay extends StatelessWidget {
  const GameResultOverlay({
    super.key,
    required this.level,
    required this.engine,
    required this.victory,
    required this.stars,
    required this.hasNext,
    required this.onRetry,
    required this.onNext,
    required this.onExit,
    this.endless = false,
    this.daily = false,
    this.bestWaves = 0,
    this.newRecord = false,
    this.exitLabel = '返回选关',
  });

  final LevelDef level;
  final DefenseEngine engine;
  final bool victory;
  final int stars;
  final bool hasNext;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onExit;

  /// 无尽模式结算：以坚守波数计分，不评星，展示历史最佳与新纪录。
  final bool endless;

  /// 每日挑战结算：与无尽模式同口径，记录当天最佳波数。
  final bool daily;
  final int bestWaves;
  final bool newRecord;
  final String exitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scored = endless || daily;
    final accent = scored || victory ? const Color(0xFF3F7D46) : appOrange;
    final waves = engine.clearedWaves;
    final title = daily
        ? '今日挑战 · 第 $waves 波'
        : endless
        ? '坚守到第 $waves 波'
        : victory
        ? '关卡完成！'
        : '萝卜被抢走了';
    final recordText = daily
        ? (newRecord ? '今日新纪录！守住 $waves 波' : '今日最佳 $bestWaves 波')
        : (newRecord
              ? '新纪录！称号：${endlessRank(waves)}'
              : '历史最佳 $bestWaves 波 · 称号：${endlessRank(waves)}');
    return GameOverlayFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(
              daily
                  ? Icons.today_rounded
                  : endless
                  ? Icons.military_tech_rounded
                  : victory
                  ? Icons.emoji_events_rounded
                  : Icons.heart_broken_rounded,
              size: 32,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 21)),
          const SizedBox(height: 3),
          Text(
            level.name,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (scored) ...[
            const SizedBox(height: 8),
            Text(
              recordText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: newRecord ? const Color(0xFFD99B1D) : colors.onSurfaceVariant,
                fontWeight: newRecord ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
          if (!scored && victory) ...[
            const SizedBox(height: 12),
            _StarRow(stars: stars),
            const SizedBox(height: 4),
            Text(
              stars == 3
                  ? '完美防守，萝卜毫发无伤'
                  : stars == 2
                  ? '防线稳固，再试一次冲击满星'
                  : '守住了萝卜，但还有提升空间',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ] else if (!scored) ...[
            const SizedBox(height: 8),
            Text(
              '冰霜塔减速配合火炮塔群伤，\n在弯道与长直路上布置火力会更稳。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _Stat(
                  label: scored ? '波次' : '击杀',
                  value: scored ? '${engine.clearedWaves}' : '${engine.kills}',
                ),
                _divider(colors),
                _Stat(
                  label: scored ? '击杀' : '漏怪',
                  value: scored ? '${engine.kills}' : '${engine.leaked}',
                ),
                _divider(colors),
                _Stat(label: '金币', value: '${engine.goldEarned}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!scored && victory && hasNext)
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: const Text('下一关'),
            )
          else
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: Text(
                scored
                    ? '再来一局'
                    : victory
                    ? '再玩一次'
                    : '再试一次',
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!scored && victory && hasNext) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                    child: const Text('重玩本关'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: onExit,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: Text(exitLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme colors) =>
      Container(width: 1, height: 22, color: colors.outline.withValues(alpha: 0.6));
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index < stars;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + index * 120),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              active ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: active ? const Color(0xFFF2B21C) : colors.outline,
            ),
          ),
        );
      }),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
