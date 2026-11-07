import '../theme/level_theme.dart';
import 'defense_models.dart';

/// 一个敌人小队：从波次开始后 [delay] 秒起，每 [gap] 秒放出一只。
class SpawnGroup {
  const SpawnGroup(
    this.kind,
    this.count, {
    this.gap = 0.9,
    this.delay = 0,
  });

  final EnemyKind kind;
  final int count;
  final double gap;
  final double delay;
}

/// 一波敌人的组成、清理奖励与血量倍率。
class WaveDef {
  const WaveDef(this.groups, {this.reward = 30, this.hpScale = 1});

  final List<SpawnGroup> groups;
  final int reward;
  final double hpScale;

  int get totalEnemies =>
      groups.fold(0, (sum, group) => sum + group.count);

  bool get hasBoss => groups.any((group) => group.kind == EnemyKind.boss);
}

/// 关卡定义：路径、可建造点、经济与波次。
class LevelDef {
  const LevelDef({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.theme,
    required this.path,
    required this.slots,
    required this.startGold,
    required this.carrotHp,
    required this.hpScale,
    required this.waves,
    required this.seed,
  });

  final int id;
  final String name;
  final String subtitle;
  final LevelTheme theme;
  final List<GridPos> path;
  final List<GridPos> slots;
  final int startGold;
  final int carrotHp;
  final double hpScale;
  final List<WaveDef> waves;
  final int seed;

  int get waveCount => waves.length;
}
