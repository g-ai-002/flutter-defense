import 'package:flutter/material.dart';

import '../game/balance.dart';
import '../models/defense_models.dart';
import 'widgets/tower_icon.dart';

/// 玩法说明：防御塔定位、敌人特点与操作提示。
Future<void> showRulesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final colors = theme.colorScheme;
      return AlertDialog(
        title: const Text('玩法说明'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '怪物会沿着土路冲向终点萝卜。点击空地建造防御塔，'
                  '点击已建的塔可以升级或出售。撑过全部波次即可通关。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text('防御塔', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final kind in TowerKind.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: TowerIcon(kind: kind, size: 38),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${kind.label} · ${towerStats(kind, 1).cost} 金',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                kind.blurb,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '小提示：提前开波可以获得额外金币；冰霜塔减速后，'
                    '火炮塔的范围伤害能打出更高效率。萝卜剩余血量越多，'
                    '通关星级越高。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.6,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
        ],
      );
    },
  );
}

/// 返回关卡前的确认框。
Future<bool> confirmLeaveGame(BuildContext context, {required bool playing}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('离开关卡？'),
      content: Text(
        playing ? '本局进度不会保留，确定要离开吗？' : '确定要离开当前关卡吗？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('继续游戏'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('离开'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}
