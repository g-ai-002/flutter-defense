import 'package:flutter/material.dart';

import '../../models/level.dart';
import '../../theme/level_theme.dart';
import 'level_thumb.dart';

/// 关卡卡片：缩略图 + 名称 + 星级，未解锁时蒙尘并显示锁标。
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.onTap,
    this.boss = false,
  });

  final LevelDef level;
  final int stars;
  final bool unlocked;
  final VoidCallback onTap;
  final bool boss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = paletteOf(level.theme);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unlocked
                  ? colors.outline.withValues(alpha: 0.8)
                  : colors.outline.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 136,
                    height: double.infinity,
                    child: LevelThumb(level: level, locked: !unlocked),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: palette.accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${level.id}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: palette.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  level.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              if (boss)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 17,
                                    color: colors.primary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            level.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Row(
                                children: [
                                  for (var i = 0; i < 3; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 17,
                                        color: i < stars ? const Color(0xFFF2B21C) : colors.outline,
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                '${level.waveCount} 波',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!unlocked)
                Positioned.fill(
                  child: Container(
                    color: colors.surface.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.outline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '通关上一关解锁',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
