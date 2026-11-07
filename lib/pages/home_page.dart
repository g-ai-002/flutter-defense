import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/endless.dart';
import '../game/levels.dart';
import '../models/endless.dart';
import '../models/level.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'game_dialogs.dart';
import 'game_page.dart';
import 'level_select_page.dart';
import 'settings_page.dart';
import 'widgets/carrot_art.dart';
import 'widgets/entry_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF221E15), Color(0xFF14110B)]
                : const [Color(0xFFFDF9EE), Color(0xFFEFF5DE)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= 980 && constraints.maxHeight >= 600;
              final horizontal = constraints.maxWidth >= 900 ? 36.0 : 18.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TopBar(
                          darkMode: settings.darkMode,
                          onToggleDark: () =>
                              settings.setDarkMode(!settings.darkMode),
                        ),
                        const SizedBox(height: 16),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _Hero(
                                  progress: progress,
                                  compact: false,
                                  narrow: false,
                                ),
                              ),
                              const SizedBox(width: 26),
                              SizedBox(
                                width: 430,
                                child: _Entries(
                                  progress: progress,
                                  compact: false,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _Hero(
                            progress: progress,
                            compact: true,
                            narrow: constraints.maxWidth < 520,
                          ),
                          const SizedBox(height: 18),
                          _Entries(progress: progress, compact: true),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'v${AppConstants.version} · 本地单机 · 无需联网',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.darkMode, required this.onToggleDark});

  final bool darkMode;
  final VoidCallback onToggleDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: appOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.eco_rounded, size: 20, color: appOrange),
        ),
        const SizedBox(width: 9),
        Text(
          AppConstants.appName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: darkMode ? '切换浅色' : '切换深色',
          onPressed: onToggleDark,
          icon: Icon(
            darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
          ),
          color: colors.onSurfaceVariant,
        ),
        IconButton(
          tooltip: '设置',
          onPressed: () => _openSettings(context),
          icon: const Icon(Icons.settings_outlined, size: 20),
          color: colors.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.progress,
    required this.compact,
    required this.narrow,
  });

  final ProgressProvider progress;
  final bool compact;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final ratio = progress.maxStars == 0
        ? 0.0
        : progress.totalStars / progress.maxStars;
    final carrotSize = compact ? (narrow ? 120.0 : 150.0) : 240.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 26,
        compact ? 18 : 26,
        compact ? 18 : 26,
        compact ? 16 : 22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF30291C), Color(0xFF1E2A1C)]
              : const [Color(0xFFFFF2D6), Color(0xFFE9F2D4)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: compact
          ? Column(
              children: [
                if (narrow) ...[
                  CarrotArt(size: carrotSize),
                  const SizedBox(height: 6),
                  _HeroCopy(progress: progress, narrow: narrow),
                ] else
                  Row(
                    children: [
                      CarrotArt(size: carrotSize),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroCopy(progress: progress, narrow: narrow),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _ProgressBar(ratio: ratio, progress: progress),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: CarrotArt(size: carrotSize)),
                const SizedBox(height: 10),
                _HeroCopy(progress: progress, narrow: narrow),
                const SizedBox(height: 16),
                _ProgressBar(ratio: ratio, progress: progress),
              ],
            ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.progress, required this.narrow});

  final ProgressProvider progress;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '守住最后一根萝卜',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: narrow ? 24 : 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: colors.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '建造弓弩、火炮、冰霜与雷电防御塔，\n抵挡一波波怪物，别让它们碰到萝卜。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFF2B21C),
                ),
                const SizedBox(width: 4),
                Text(
                  '${progress.totalStars} / ${progress.maxStars} 星',
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '已解锁 ${math.min(progress.unlockedLevel, kLevels.length)} '
                  '/ ${kLevels.length} 关',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.ratio, required this.progress});

  final double ratio;
  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE4572E)),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              '冒险进度',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              '${(ratio * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries({required this.progress, required this.compact});

  final ProgressProvider progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = (progress.unlockedLevel - 1).clamp(0, kLevels.length - 1);
    final level = kLevels[index];
    final best = progress.bestEndless;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EntryTile(
          primary: true,
          icon: Icons.play_arrow_rounded,
          title: progress.unlockedLevel > kLevels.length ? '再战终章' : '开始冒险',
          subtitle: '第 ${level.id} 关 · ${level.name} · ${level.waveCount} 波敌人',
          onTap: () => _openLevel(context, level),
        ),
        const SizedBox(height: 10),
        EntryTile(
          icon: Icons.all_inclusive_rounded,
          title: '无尽挑战',
          subtitle: best == null
              ? '波次无尽，看看你能守住几波'
              : '最佳第 ${best.waves} 波 · ${endlessRank(best.waves)} · '
                    '${best.kills} 击杀',
          accent: const Color(0xFF4F8C3A),
          trailing: IconButton(
            tooltip: '无尽排行榜',
            onPressed: () =>
                showEndlessRecordsDialog(context, progress.endlessRecords),
            icon: Icon(
              Icons.leaderboard_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            visualDensity: VisualDensity.compact,
          ),
          onTap: () => _openLevel(context, kEndlessLevel),
        ),
        const SizedBox(height: 10),
        EntryTile(
          icon: Icons.map_outlined,
          title: '关卡选择',
          subtitle: '${kLevels.length} 个关卡 · 挑战满星通关',
          accent: const Color(0xFF3F7D46),
          onTap: () => _openLevels(context),
        ),
        const SizedBox(height: 10),
        EntryTile(
          icon: Icons.menu_book_outlined,
          title: '玩法说明',
          subtitle: '防御塔、怪物与波次机制速览',
          accent: const Color(0xFF3E7FA6),
          onTap: () => showRulesDialog(context),
        ),
        const SizedBox(height: 10),
        EntryTile(
          icon: Icons.settings_outlined,
          title: '设置',
          subtitle: '音效、音乐、逻辑刷新率与日志',
          accent: const Color(0xFF8B6239),
          onTap: () => _openSettings(context),
        ),
      ],
    );
  }
}

void _openLevel(BuildContext context, LevelDef level) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => GamePage(level: level)));
}

void _openLevels(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const LevelSelectPage()));
}

void _openSettings(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
}
