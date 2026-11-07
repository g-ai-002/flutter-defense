import 'dart:ui';

import '../../models/defense_models.dart';
import '../balance.dart';

enum GameStatus { preparing, battle, victory, defeat }

/// 玩法事件，渲染层据此播放音效，不参与逻辑。
enum GameEvent {
  build,
  upgrade,
  sell,
  arrowShot,
  cannonShot,
  frostShot,
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

  double hp;
  double distance = 0;

  /// 每逻辑帧缓存的位置，渲染插值与索敌直接复用，避免重复扫描路径。
  Offset position = Offset.zero;
  Offset prevPosition = Offset.zero;

  double slowTimer = 0;
  double slowFactor = 1;
  double flash = 0;
  bool alive = true;

  bool get isBoss => kind == EnemyKind.boss;
  double get hpRatio => (hp / maxHp).clamp(0.0, 1.0);
  bool get slowed => slowTimer > 0;

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
  final double flightTime;

  double elapsed = 0;
  bool done = false;
  Offset? impact;

  double get progress => (elapsed / flightTime).clamp(0.0, 1.0);
}

enum EffectKind { explosion, spark, lightning, frostRing, buildDust, leak }

class Effect {
  Effect({
    required this.kind,
    required this.position,
    this.end,
    this.points = const [],
    this.radius = 20,
    this.duration = 0.4,
  });

  final EffectKind kind;
  final Offset position;
  final Offset? end;
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

  final String text;
  final Offset position;
  final Color color;
  final bool big;
  final double duration;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);
  bool get finished => elapsed >= duration;
}
