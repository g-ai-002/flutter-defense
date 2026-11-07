import 'dart:ui';

import '../theme/level_theme.dart';
import 'defense_models.dart';

/// 一个敌人小队：从波次开始后 [delay] 秒起，每 [gap] 秒放出一只。
class SpawnGroup {
  const SpawnGroup(this.kind, this.count, {this.gap = 0.9, this.delay = 0});

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

  int get totalEnemies => groups.fold(0, (sum, group) => sum + group.count);

  bool get hasBoss => groups.any((group) => group.kind == EnemyKind.boss);
}

/// 毒雾区：圆形范围，地面敌人经过时持续掉血（无视护甲），飞行敌人不受影响。
class FogZone {
  const FogZone(this.center, {this.radius = 112});

  final GridPos center;
  final double radius;

  Offset get design => center.design;
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
    this.fog = const [],
    this.endless = false,
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

  /// 毒雾区，地面敌人穿行时会持续掉血。
  final List<FogZone> fog;

  /// 无尽模式：波次表按上限生成，结算以坚守波数计分。
  final bool endless;

  int get waveCount => waves.length;

  bool get hasFog => fog.isNotEmpty;
}
