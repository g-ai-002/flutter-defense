import '../models/defense_models.dart';

/// 防御塔单个等级的数值。cost 为建造/升级花费，range 为攻击半径（设计像素）。
class TowerStats {
  const TowerStats({
    required this.cost,
    required this.range,
    required this.interval,
    required this.damage,
    this.splash = 0,
    this.slowFactor = 1,
    this.slowDuration = 0,
    this.chains = 1,
  });

  final int cost;
  final double range;
  final double interval;
  final double damage;
  final double splash;
  final double slowFactor;
  final double slowDuration;
  final int chains;

  double get dps => damage / interval;
}

/// 每座塔三个等级，索引 0 对应 Lv.1。
const Map<TowerKind, List<TowerStats>> kTowerStats = {
  TowerKind.arrow: [
    TowerStats(cost: 70, range: 152, interval: 0.60, damage: 15),
    TowerStats(cost: 100, range: 172, interval: 0.52, damage: 26),
    TowerStats(cost: 160, range: 196, interval: 0.44, damage: 44),
  ],
  TowerKind.cannon: [
    TowerStats(cost: 110, range: 166, interval: 1.45, damage: 42, splash: 62),
    TowerStats(cost: 150, range: 184, interval: 1.30, damage: 70, splash: 70),
    TowerStats(cost: 220, range: 202, interval: 1.15, damage: 112, splash: 78),
  ],
  TowerKind.frost: [
    TowerStats(
      cost: 80,
      range: 136,
      interval: 0.95,
      damage: 8,
      splash: 46,
      slowFactor: 0.58,
      slowDuration: 1.5,
    ),
    TowerStats(
      cost: 105,
      range: 152,
      interval: 0.85,
      damage: 13,
      splash: 50,
      slowFactor: 0.48,
      slowDuration: 1.9,
    ),
    TowerStats(
      cost: 155,
      range: 170,
      interval: 0.75,
      damage: 21,
      splash: 56,
      slowFactor: 0.38,
      slowDuration: 2.3,
    ),
  ],
  TowerKind.lightning: [
    TowerStats(cost: 130, range: 172, interval: 1.25, damage: 30, chains: 2),
    TowerStats(cost: 180, range: 190, interval: 1.10, damage: 50, chains: 3),
    TowerStats(cost: 260, range: 212, interval: 0.95, damage: 78, chains: 4),
  ],
};

TowerStats towerStats(TowerKind kind, int level) =>
    kTowerStats[kind]![level.clamp(1, 3) - 1];

/// 连锁闪电每跳一次的伤害衰减。
const double kChainFalloff = 0.75;

/// 连锁闪电寻找下一目标的半径。
const double kChainRadius = 112;

/// 出售返还已投入金币的比例。
const double kSellRefundRatio = 0.7;

/// 敌人基础数值（Lv.1 倍率下）。
class EnemyStats {
  const EnemyStats({
    required this.hp,
    required this.speed,
    required this.bounty,
    required this.damage,
    required this.radius,
    required this.armor,
  });

  final double hp;
  final double speed;
  final int bounty;
  final int damage;
  final double radius;

  /// 承伤系数：铁甲虫只吃 62% 伤害。
  final double armor;
}

const Map<EnemyKind, EnemyStats> kEnemyStats = {
  EnemyKind.slime: EnemyStats(
    hp: 95,
    speed: 44,
    bounty: 8,
    damage: 1,
    radius: 15,
    armor: 1,
  ),
  EnemyKind.runner: EnemyStats(
    hp: 62,
    speed: 86,
    bounty: 8,
    damage: 1,
    radius: 13,
    armor: 1,
  ),
  EnemyKind.beetle: EnemyStats(
    hp: 300,
    speed: 36,
    bounty: 16,
    damage: 2,
    radius: 19,
    armor: 0.62,
  ),
  EnemyKind.tank: EnemyStats(
    hp: 780,
    speed: 27,
    bounty: 26,
    damage: 3,
    radius: 24,
    armor: 0.78,
  ),
  EnemyKind.boss: EnemyStats(
    hp: 6500,
    speed: 22,
    bounty: 120,
    damage: 10,
    radius: 33,
    armor: 0.7,
  ),
};

/// 赏金随关卡强度提升，保证后期经济跟得上塔价。
int bountyFor(EnemyKind kind, double hpScale) =>
    (kEnemyStats[kind]!.bounty * (0.65 + 0.4 * hpScale)).round();

/// 星级：满血三星，剩余 ≥50% 两星，其余一星。
int starRating({required int carrotHp, required int carrotMaxHp}) {
  if (carrotHp >= carrotMaxHp) return 3;
  if (carrotHp >= carrotMaxHp * 0.5) return 2;
  return 1;
}
