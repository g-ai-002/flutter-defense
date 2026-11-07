import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/engine/defense_engine.dart';
import '../../models/level.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

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
  });

  final LevelDef level;
  final DefenseEngine engine;
  final bool victory;
  final int stars;
  final bool hasNext;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.52),
      alignment: Alignment.center,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.86, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (victory ? const Color(0xFF3F7D46) : appOrange)
                            .withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        victory
                            ? Icons.emoji_events_rounded
                            : Icons.heart_broken_rounded,
                        size: 32,
                        color: victory ? const Color(0xFF3F7D46) : appOrange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      victory ? '关卡完成！' : '萝卜被抢走了',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 21),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      level.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (victory) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final active = index < stars;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 260 + index * 120),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) =>
                                Transform.scale(scale: value, child: child),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                active
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 36,
                                color: active
                                    ? const Color(0xFFF2B21C)
                                    : colors.outline,
                              ),
                            ),
                          );
                        }),
                      ),
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
                    ] else ...[
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _Stat(label: '击杀', value: '${engine.kills}'),
                          _divider(colors),
                          _Stat(label: '漏怪', value: '${engine.leaked}'),
                          _divider(colors),
                          _Stat(label: '金币', value: '${engine.goldEarned}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (victory && hasNext)
                      FilledButton(
                        onPressed: onNext,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('下一关'),
                      )
                    else
                      FilledButton(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: Text(victory ? '再玩一次' : '再试一次'),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (victory && hasNext) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onRetry,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                              ),
                              child: const Text('重玩本关'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onExit,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            child: const Text('返回选关'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(ColorScheme colors) => Container(
    width: 1,
    height: 22,
    color: colors.outline.withValues(alpha: 0.6),
  );
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
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
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

/// 暂停面板：继续、重开、离开，并可快速切换音频。
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.logicLabel,
    required this.speed,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final String logicLabel;
  final double speed;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: 340,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pause_circle_outline, color: colors.primary),
                      const SizedBox(width: 8),
                      Text('游戏暂停', style: theme.textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '逻辑 $logicLabel · 战斗速度 ${speed.toInt()}x',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ToggleRow(
                    title: '游戏音效',
                    value: settings.soundEnabled,
                    onChanged: settings.setSoundEnabled,
                  ),
                  _ToggleRow(
                    title: '背景音乐',
                    value: settings.musicEnabled,
                    onChanged: settings.setMusicEnabled,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: onResume,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('继续游戏'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRestart,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text('重新开始'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onExit,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text('返回选关'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
