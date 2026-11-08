import 'dart:math' as math;

import '../models/defense_models.dart';
import '../models/level.dart';
import 'levels.dart';

/// 每日挑战的固定波数。
const int kDailyWaves = 15;

int dailySeed(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

String dailyKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// 按日期种子生成当天关卡：路线、分流与出怪节奏都由种子决定，同一天重玩完全一致。
///
/// 同一天的关卡只解析一次，首页与每日挑战入口反复取用时不再重算十五波配置。
LevelDef dailyLevel([DateTime? now]) {
  final date = now ?? DateTime.now();
  final seed = dailySeed(date);
  final cached = _cachedLevel;
  if (cached != null && _cachedSeed == seed) return cached;
  final random = math.Random(seed);
  final base = kLevels[random.nextInt(kLevels.length)];
  final lanes = base.routes.length;
  _cachedSeed = seed;
  return _cachedLevel = LevelDef(
    id: 900,
    name: '每日挑战',
    subtitle: '${dailyKey(date)} · 种子 $seed',
    theme: base.theme,
    path: base.path,
    branch: base.branch,
    portals: base.portals,
    fog: base.fog,
    slots: base.slots,
    startGold: 360,
    carrotHp: 20,
    hpScale: 1.15,
    seed: seed,
    daily: true,
    waves: [for (var index = 0; index < kDailyWaves; index++) _dailyWave(random, index + 1, lanes)],
  );
}

LevelDef? _cachedLevel;
int _cachedSeed = 0;

/// 每日波次：数量随波次线性增长并设上限，分岔关卡按种子把主队分到支路。
WaveDef _dailyWave(math.Random random, int wave, int lanes) {
  final lane = lanes > 1 && random.nextInt(3) == 0 ? 1 : 0;
  return WaveDef(
    [
      SpawnGroup(EnemyKind.slime, math.min(24, 7 + wave), gap: 0.75, lane: lane),
      // 疾风兔固定走主路，保证支路只承接按种子分流的小队。
      if (wave >= 2)
        SpawnGroup(EnemyKind.runner, math.min(20, 2 + wave), gap: 0.6, delay: 1.2, lane: 0),
      if (wave >= 4)
        SpawnGroup(EnemyKind.beetle, math.min(12, 1 + wave ~/ 2), gap: 0.9, delay: 2, lane: lane),
      if (wave >= 6) SpawnGroup(EnemyKind.tank, math.min(6, 1 + wave ~/ 5), gap: 1.5, delay: 3),
      if (wave >= 8) SpawnGroup(EnemyKind.flyer, math.min(6, 1 + wave ~/ 5), gap: 1.3, delay: 4),
      if (wave == kDailyWaves) SpawnGroup(EnemyKind.boss, 1, gap: 1, delay: 6),
    ],
    reward: 35 + wave * 4,
    hpScale: 0.6 + wave * 0.05,
  );
}
