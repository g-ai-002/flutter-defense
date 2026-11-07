import 'dart:ui';

import '../../models/defense_models.dart';
import '../balance.dart';
import 'path_track.dart';

enum GameStatus { preparing, battle, victory, defeat }

/// 玩法事件，渲染层据此播放音效，不参与逻辑。
enum GameEvent {
  build,
  upgrade,
  sell,
  arrowShot,
  cannonShot,
  frostShot,
  poisonShot,
  lightning,
  hit,
  leak,
  waveStart,
  waveClear,
  victory,
  defeat,
  gold,
}

class Tower {
  Tower({required this.slotIndex, required this.kind, required this.position})
    : stats = towerStats(kind, 1);

  final int slotIndex;
  final TowerKind kind;
  final Offset position;
  int level = 1;
  TowerStats stats;
  double cooldown = 0;
  double angle = -1.57;
  double recoil = 0;
  int totalSpent = 0;

  int get upgradeCost => level >= 3 ? 0 : towerStats(kind, level + 1).cost;
  bool get canUpgrade => level < 3;
  int get sellValue => (totalSpent * kSellRefundRatio).floor();

  void applyUpgrade() {
    level++;
    stats = towerStats(kind, level);
    cooldown = 0;
  }
}

class Enemy {
  Enemy({
    required this.id,
    required this.kind,
    required this.maxHp,
    required this.speed,
    required this.bounty,
    required this.damage,
    required this.radius,
    required this.armor,
    required this.lateral,
    required this.routeLength,
    this.flying = false,
  }) : hp = maxHp;

  final int id;
  final EnemyKind kind;
  final double maxHp;
  final double speed;
  final int bounty;
  final int damage;
  final double radius;
  final double armor;

  /// 同一路径上的横向错位，避免所有敌人重叠成一条线。
  final double lateral;

  /// 飞行敌人沿入口到萝卜的直线前进，不走土路。
  final bool flying;

  /// 本局行进路线的总长度，用于统一进度比较。
  final double routeLength;

  double hp;
  double distance = 0;

  /// 每逻辑帧缓存的位置，渲染插值与索敌直接复用，避免重复扫描路径。
  Offset position = Offset.zero;
  Offset prevPosition = Offset.zero;

  /// 单调前进的路径游标，避免每帧二分查找分段。
  final PathCursor cursor = PathCursor();

  double slowTimer = 0;
  double slowFactor = 1;
  double poisonTimer = 0;
  double poisonDps = 0;
  double flash = 0;
  bool alive = true;

  bool get isBoss => kind == EnemyKind.boss;
  double get hpRatio => (hp / maxHp).clamp(0.0, 1.0);
  bool get slowed => slowTimer > 0;
  bool get poisoned => poisonTimer > 0;

  /// 归一化行进进度，地面与飞行敌人可以放在同一尺度上比较。
  double get progress =>
      routeLength <= 0 ? 1 : (distance / routeLength).clamp(0.0, 1.0);

  double get currentSpeed => speed * (slowTimer > 0 ? slowFactor : 1);
}

class Projectile {
  Projectile({
    required this.kind,
    required this.targetId,
    required this.position,
    required Offset targetPosition,
    required this.speed,
    required this.damage,
    required this.splash,
    required this.slowFactor,
    required this.slowDuration,
    required this.flightTime,
    this.poisonDps = 0,
    this.poisonDuration = 0,
  }) : lastTarget = targetPosition;

  final TowerKind kind;
  final int targetId;
  Offset position;
  Offset lastTarget;
  final double speed;
  final double damage;
  final double splash;
  final double slowFactor;
  final double slowDuration;
  final double poisonDps;
  final double poisonDuration;
  final double flightTime;

  double elapsed = 0;
  bool done = false;
  Offset? impact;

  double get progress => (elapsed / flightTime).clamp(0.0, 1.0);
}

enum EffectKind {
  explosion,
  spark,
  lightning,
  frostRing,
  poison,
  buildDust,
  leak,
}

class Effect {
  Effect({
    required this.kind,
    required this.position,
    this.points = const [],
    this.radius = 20,
    this.duration = 0.4,
  });

  /// 所有特效工厂共用的构造路径。
  factory Effect._of(
    EffectKind kind,
    Offset position,
    double radius,
    double duration, [
    List<Offset> points = const [],
  ]) => Effect(
    kind: kind,
    position: position,
    points: points,
    radius: radius,
    duration: duration,
  );

  factory Effect.buildDust(
    Offset position, {
    double radius = 34,
    double duration = 0.45,
  }) => Effect._of(EffectKind.buildDust, position, radius, duration);

  factory Effect.spark(
    Offset position, {
    double radius = 14,
    double duration = 0.22,
  }) => Effect._of(EffectKind.spark, position, radius, duration);

  factory Effect.explosion(
    Offset position, {
    required double radius,
    double duration = 0.45,
  }) => Effect._of(EffectKind.explosion, position, radius, duration);

  factory Effect.frostRing(
    Offset position, {
    required double radius,
    double duration = 0.45,
  }) => Effect._of(EffectKind.frostRing, position, radius, duration);

  factory Effect.poisonCloud(
    Offset position, {
    required double radius,
    double duration = 0.45,
  }) => Effect._of(EffectKind.poison, position, radius, duration);

  factory Effect.leak(
    Offset position, {
    double radius = 46,
    double duration = 0.5,
  }) => Effect._of(EffectKind.leak, position, radius, duration);

  factory Effect.lightning(List<Offset> points, {double duration = 0.22}) =>
      Effect._of(EffectKind.lightning, points.first, 20, duration, points);

  final EffectKind kind;
  final Offset position;
  final List<Offset> points;
  final double radius;
  final double duration;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);
  bool get finished => elapsed >= duration;
}

class Floater {
  Floater({
    required this.text,
    required this.position,
    this.color = const Color(0xFFFFF3C4),
    this.big = false,
    this.duration = 1.1,
  });

  factory Floater.gold(int amount, Offset position) => Floater(
    text: '+$amount',
    position: position,
    color: const Color(0xFFFFE08A),
  );

  factory Floater.damage(int amount, Offset position) => Floater(
    text: '-$amount',
    position: position,
    color: const Color(0xFFFF7A6B),
    big: true,
  );

  factory Floater.notice(String text, Offset position) =>
      Floater(text: text, position: position, color: const Color(0xFFFFE08A));

  final String text;
  final Offset position;
  final Color color;
  final bool big;
  final double duration;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);
  bool get finished => elapsed >= duration;
}
