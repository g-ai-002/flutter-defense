import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/levels.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import 'game_page.dart';
import 'widgets/level_card.dart';

class LevelSelectPage extends StatelessWidget {
  const LevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择关卡'),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF2B21C)),
                    const SizedBox(width: 3),
                    Text(
                      '${progress.totalStars}/${progress.maxStars}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: appGreen.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flag_rounded, color: appGreen, size: 21),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('萝卜村的防线', style: theme.textTheme.titleMedium),
                              Text(
                                '通关后解锁下一关，剩余血量越多星级越高',
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
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisExtent: 152,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final level = kLevels[index];
                  return LevelCard(
                    level: level,
                    stars: progress.starsFor(level.id),
                    unlocked: progress.isUnlocked(level.id),
                    boss: level.id >= 8,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GamePage(level: level, fromLevelSelect: true),
                        ),
                      );
                    },
                  );
                }, childCount: kLevels.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
