import 'dart:math' as math;

import '../models/defense_models.dart';
import '../models/level.dart';
import '../theme/level_theme.dart';
import 'levels.dart';

/// 无尽模式最多生成 120 波，血量随波次二次增长，实际很难打满。
const int kEndlessWaveCount = 120;

/// 无尽挑战使用最长的蛇形路线与全部 15 个建造位。
final LevelDef kEndlessLevel = LevelDef(
  id: 100,
  name: '无尽挑战',
  subtitle: '守住萝卜，看看你能撑到第几波',
  theme: LevelTheme.night,
  path: kPathC,
  slots: kSlotsC,
  startGold: 360,
  carrotHp: 25,
  hpScale: 1,
  seed: 4040,
  endless: true,
  waves: [for (var i = 0; i < kEndlessWaveCount; i++) endlessWave(i)],
);

/// 第 [index] 波（从 0 开始）的构成：种类逐波解锁，数量设上限避免后期卡顿。
WaveDef endlessWave(int index) {
  final wave = index + 1;
  final groups = <SpawnGroup>[
    SpawnGroup(EnemyKind.slime, math.min(30, 6 + wave), gap: 0.55),
    if (wave >= 2) SpawnGroup(EnemyKind.runner, math.min(24, 3 + wave ~/ 2), gap: 0.42, delay: 1.2),
    if (wave >= 3) SpawnGroup(EnemyKind.beetle, math.min(14, 1 + wave ~/ 3), gap: 0.9, delay: 2),
    if (wave >= 5) SpawnGroup(EnemyKind.tank, math.min(8, 1 + wave ~/ 8), gap: 1.4, delay: 3),
    if (wave >= 8) SpawnGroup(EnemyKind.flyer, math.min(10, 2 + wave ~/ 4), gap: 0.8, delay: 2.5),
    if (wave % 15 == 0) SpawnGroup(EnemyKind.boss, math.min(3, 1 + wave ~/ 60), gap: 6, delay: 5),
  ];
  return WaveDef(groups, reward: 30 + wave * 4, hpScale: 1 + 0.13 * wave + 0.0045 * wave * wave);
}
