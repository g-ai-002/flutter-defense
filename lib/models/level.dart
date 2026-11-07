import 'dart:ui';

import '../theme/level_theme.dart';
import 'defense_models.dart';

/// 一个敌人小队：从波次开始后 [delay] 秒起，每 [gap] 秒放出一只。
class SpawnGroup {
  const SpawnGroup(this.kind, this.count, {this.gap = 0.9, this.delay = 0, this.lane = -1});

  final EnemyKind kind;
  final int count;
  final double gap;
  final double delay;

  /// 分叉路线序号；-1 表示按出怪顺序在可走路线间交替。
  final int lane;
}

/// 传送门：地面敌人越过入口后瞬移到前方出口，跳过一段土路。
class Portal {
  const Portal(this.entry, this.exit, {this.radius = 54});

  final GridPos entry;
  final GridPos exit;
  final double radius;

  Offset get entryDesign => entry.design;
  Offset get exitDesign => exit.design;
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
    this.branch,
    this.portals = const [],
    this.fog = const [],
    this.endless = false,
    this.daily = false,
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

  /// 分叉支路：与主路共用入口和萝卜终点，地面敌人可分流绕行。
  final List<GridPos>? branch;

  /// 传送门配对，每对入口与出口都落在可行路线上时生效。
  final List<Portal> portals;

  /// 毒雾区，地面敌人穿行时会持续掉血。
  final List<FogZone> fog;

  /// 无尽模式：波次表按上限生成，结算以坚守波数计分。
  final bool endless;

  /// 每日挑战：按日期种子生成，不写入关卡星级与解锁进度。
  final bool daily;

  int get waveCount => waves.length;

  bool get hasFog => fog.isNotEmpty;

  bool get hasBranch => branch != null;

  /// 全部可行路线，第一条恒为主路。
  List<List<GridPos>> get routes => [path, ?branch];

  /// 传送门两端的设计坐标，地面绘制与装饰避让共用。
  Iterable<Offset> get portalEnds =>
      portals.expand((portal) => [portal.entryDesign, portal.exitDesign]);

  /// 传送门两端的网格坐标，关卡缩略图使用。
  Iterable<GridPos> get portalCells => portals.expand((portal) => [portal.entry, portal.exit]);
}
