import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../models/defense_models.dart';
import '../../models/level.dart';
import '../balance.dart';
import 'entities.dart';
import 'path_track.dart';
import 'wave_schedule.dart';

/// 塔防核心逻辑：纯数据驱动，不依赖渲染，可在测试中直接快进模拟。
class DefenseEngine {
  DefenseEngine({required this.level})
    : tracks = [
        for (final route in level.routes) PathTrack([for (final point in route) point.design]),
      ],
      slotPositions = [for (final slot in level.slots) slot.design],
      fogZones = [for (final zone in level.fog) (zone.design, zone.radius * zone.radius)] {
    track = tracks.first;
    gold = level.startGold;
    carrotMaxHp = level.carrotHp;
    carrotHp = level.carrotHp;
    towers = List<Tower?>.filled(level.slots.length, null);
    prepTimer = _firstPrepSeconds;
    _resolvePortals();
    _lastHudKey = _hudKey();
  }

  final LevelDef level;

  /// 全部可行路线，主路固定在第 0 条。
  final List<PathTrack> tracks;
  late final PathTrack track;

  /// 每对传送门在每条路线上的入口/出口弧长；出口不在本路线上时跳过。
  final List<({int route, double entry, double exit, Offset at, Offset away})> _portalJumps = [];
  final List<Offset> slotPositions;

  /// 毒雾区中心与半径平方，逐帧判定避免开方。
  final List<(Offset, double)> fogZones;

  late final List<Tower?> towers;

  final List<Enemy> enemies = [];
  final List<Projectile> projectiles = [];
  final List<Effect> effects = [];
  final List<Floater> floaters = [];

  /// 已建造的塔，建造/出售时增量维护，渲染与索敌不再逐帧过滤。
  final List<Tower> _activeTowers = [];
  late final List<Tower> _activeTowersView = UnmodifiableListView(_activeTowers);

  /// 敌人 id 索引，弹道命中查询从 O(n) 降为 O(1)。
  final Map<int, Enemy> _enemyIndex = {};

  /// 待渲染层消费的玩法事件（播放音效）。
  final List<GameEvent> events = [];

  /// HUD 以 10Hz 刷新，避免每帧重建 Flutter 组件。
  final ValueNotifier<int> hud = ValueNotifier<int>(0);

  GameStatus status = GameStatus.preparing;
  int gold = 0;
  int carrotHp = 0;
  int carrotMaxHp = 10;
  int waveIndex = 0;
  double prepTimer = 0;
  double waveElapsed = 0;
  double battleTime = 0;
  int kills = 0;
  int leaked = 0;
  int goldEarned = 0;
  int stars = 0;

  int? selectedSlot;
  TowerKind? armedKind;
  int _aliveCount = 0;

  WaveSchedule? _schedule;
  int _nextEnemyId = 1;
  double _hudTimer = 0;
  double _carrotPulse = 0;
  bool _resultAnnounced = false;
  int _lastHudKey = 0;

  /// 首波准备时间；之后每波固定 10 秒。
  static const double _firstPrepSeconds = 18;
  static const double _nextPrepSeconds = 10;
  static const double _hudRefreshSeconds = 0.1;

  Tower? towerAt(int slot) => slot < 0 || slot >= towers.length ? null : towers[slot];

  Tower? get selectedTower {
    final slot = selectedSlot;
    return slot == null ? null : towerAt(slot);
  }

  Offset enemyPosition(Enemy enemy, {double alpha = 1}) {
    if (alpha >= 1) return enemy.position;
    return Offset.lerp(enemy.prevPosition, enemy.position, alpha)!;
  }

  int get remainingEnemies {
    if (status != GameStatus.battle) return 0;
    return _aliveCount + (_schedule?.pending ?? 0);
  }

  double get waveProgress {
    final total = _schedule?.total ?? 0;
    if (total <= 0) return 0;
    return (1 - remainingEnemies / total).clamp(0.0, 1.0);
  }

  int get earlyBonus => status == GameStatus.preparing ? prepTimer.ceil() : 0;

  bool get isFinished => status == GameStatus.victory || status == GameStatus.defeat;

  bool get endless => level.endless;

  bool get daily => level.daily;

  /// 完整清理的波次数，失败时用于无尽模式结算。
  int get clearedWaves => status == GameStatus.battle ? math.max(0, waveIndex - 1) : waveIndex;

  List<Tower> get activeTowers => _activeTowersView;

  void selectSlot(int? slot) {
    if (slot != null && (slot < 0 || slot >= towers.length)) return;
    selectedSlot = slot;
    armedKind = null;
    _bump();
  }

  void toggleArmed(TowerKind kind) {
    armedKind = armedKind == kind ? null : kind;
    selectedSlot = null;
    _bump();
  }

  void clearSelection() {
    selectedSlot = null;
    armedKind = null;
    _bump();
  }

  bool canBuild(TowerKind kind, int slot) =>
      slot >= 0 &&
      slot < towers.length &&
      towers[slot] == null &&
      !isFinished &&
      gold >= towerStats(kind, 1).cost;

  bool build(int slot, TowerKind kind) {
    if (!canBuild(kind, slot)) return false;
    final cost = towerStats(kind, 1).cost;
    gold -= cost;
    final tower = Tower(slotIndex: slot, kind: kind, position: slotPositions[slot])
      ..totalSpent = cost;
    towers[slot] = tower;
    _activeTowers.add(tower);
    selectedSlot = slot;
    effects.add(Effect.buildDust(tower.position));
    events.add(GameEvent.build);
    _bump();
    return true;
  }

  bool upgrade(int slot) {
    final tower = towerAt(slot);
    if (tower == null || !tower.canUpgrade || isFinished) return false;
    final cost = tower.upgradeCost;
    if (gold < cost) return false;
    gold -= cost;
    tower.totalSpent += cost;
    tower.applyUpgrade();
    effects.add(Effect.buildDust(tower.position, radius: 40, duration: 0.5));
    events.add(GameEvent.upgrade);
    _bump();
    return true;
  }

  bool sell(int slot) {
    final tower = towerAt(slot);
    if (tower == null || isFinished) return false;
    gold += tower.sellValue;
    towers[slot] = null;
    _activeTowers.remove(tower);
    selectedSlot = null;
    effects.add(Effect.buildDust(tower.position, radius: 30, duration: 0.4));
    events.add(GameEvent.sell);
    _bump();
    return true;
  }

  /// 手动开波，准备阶段剩余时间折算为额外金币。
  bool startNextWave() {
    if (status != GameStatus.preparing || waveIndex >= level.waveCount) {
      return false;
    }
    final bonus = earlyBonus;
    if (bonus > 0) {
      gold += bonus;
      goldEarned += bonus;
      floaters.add(Floater.notice('提前出击 +$bonus', track.start + const Offset(30, -20)));
    }
    _beginWave();
    return true;
  }

  void _beginWave() {
    final wave = level.waves[waveIndex];
    _schedule = WaveSchedule(wave, hpScale: level.hpScale * wave.hpScale);
    waveElapsed = 0;
    waveIndex++;
    status = GameStatus.battle;
    events.add(GameEvent.waveStart);
    _bump();
  }

  void update(double dt) {
    if (dt <= 0) return;
    _updateVisuals(dt);
    if (isFinished) {
      _tickHud(dt);
      return;
    }

    if (status == GameStatus.preparing) {
      prepTimer -= dt;
      if (prepTimer <= 0) {
        prepTimer = 0;
        _beginWave();
      }
    }

    if (status == GameStatus.battle) {
      battleTime += dt;
      waveElapsed += dt;
      _spawnDue();
      _tickPoison(dt);
      _moveEnemies(dt);
      if (status != GameStatus.defeat) {
        _updateTowers(dt);
        _updateProjectiles(dt);
        _checkWaveComplete();
      }
    }

    _tickHud(dt);
  }

  void _spawnDue() {
    final schedule = _schedule;
    if (schedule == null) return;
    while (true) {
      final item = schedule.nextAt(waveElapsed);
      if (item == null) break;
      _spawnEnemy(item);
    }
  }

  void _spawnEnemy(SpawnEvent item) {
    final base = kEnemyStats[item.kind]!;
    final id = _nextEnemyId++;
    final lateral = item.kind == EnemyKind.boss ? 0.0 : ((id % 5) - 2) * 4.5;
    final laneCount = base.flying ? 1 : tracks.length;
    final lane = item.lane >= 0 ? item.lane % laneCount : (laneCount > 1 ? id % laneCount : 0);
    final route = tracks[lane];
    final enemy = Enemy(
      id: id,
      kind: item.kind,
      maxHp: base.hp * item.hpScale,
      speed: base.speed,
      bounty: bountyFor(item.kind, item.hpScale),
      damage: base.damage,
      radius: base.radius,
      armor: base.armor,
      lateral: lateral,
      track: route,
      route: lane,
      flying: base.flying,
      routeLength: base.flying ? route.airLength : route.length,
    );
    final position = _routePosition(enemy);
    enemy
      ..position = position
      ..prevPosition = position;
    enemies.add(enemy);
    _aliveCount++;
    _enemyIndex[id] = enemy;
  }

  /// 预计算传送门在每条路线上的弧长，出口不在路线上或没有前进时忽略。
  void _resolvePortals() {
    for (final portal in level.portals) {
      for (var route = 0; route < tracks.length; route++) {
        final entry = tracks[route].nearest(portal.entryDesign);
        final exit = tracks[route].nearest(portal.exitDesign);
        if (entry.gap > portal.radius || exit.gap > portal.radius) continue;
        if (exit.along <= entry.along + 2) continue;
        _portalJumps.add((
          route: route,
          entry: entry.along,
          exit: exit.along,
          at: portal.entryDesign,
          away: portal.exitDesign,
        ));
      }
    }
  }

  /// 地面敌人沿土路前进，飞行敌人走入口到萝卜的直线。
  Offset _routePosition(Enemy enemy) => enemy.flying
      ? Offset.lerp(enemy.track.start, enemy.track.end, enemy.progress)!
      : enemy.cursor.sample(enemy.track, enemy.distance, enemy.lateral);

  void _moveEnemies(double dt) {
    var defeated = false;
    for (final enemy in enemies) {
      if (!enemy.alive) continue;
      _advanceEnemy(enemy, dt);
      if (enemy.alive && enemy.distance >= enemy.routeLength) {
        defeated = _leak(enemy);
      }
      if (defeated) break;
    }
    if (defeated) {
      for (final enemy in enemies) {
        if (enemy.alive && enemy.distance >= enemy.routeLength) {
          enemy.alive = false;
          _aliveCount--;
        }
      }
    }
    _removeDeadEnemies();
  }

  /// 推进单个敌人：先结算移动与状态倒计时，再判定毒雾伤害。
  void _advanceEnemy(Enemy enemy, double dt) {
    enemy.prevPosition = enemy.position;
    if (enemy.slowTimer > 0) {
      enemy.slowTimer = math.max(0, enemy.slowTimer - dt);
    }
    final before = enemy.distance;
    enemy.distance += enemy.currentSpeed * dt;
    final portaled = _usePortal(enemy, before);
    enemy.position = _routePosition(enemy);
    // 瞬移不参与插值，避免渲染层把敌人从入口拖出一条长线。
    if (portaled) enemy.prevPosition = enemy.position;
    if (enemy.flash > 0) enemy.flash = math.max(0, enemy.flash - dt);
    _applyFog(enemy, dt);
  }

  /// 越过入口弧长时瞬移到前方出口，同一敌人每道门只结算一次。
  bool _usePortal(Enemy enemy, double before) {
    if (enemy.flying || _portalJumps.isEmpty) return false;
    for (final jump in _portalJumps) {
      if (jump.route != enemy.route) continue;
      if (before >= jump.entry || enemy.distance < jump.entry) continue;
      if (jump.exit <= enemy.distance) continue;
      enemy.distance = jump.exit;
      effects.add(Effect.portal(jump.at, jump.away));
      events.add(GameEvent.portal);
      return true;
    }
    return false;
  }

  /// 毒雾只腐蚀地面敌人，伤害按最大生命值比例结算且无视护甲。
  void _applyFog(Enemy enemy, double dt) {
    if (enemy.flying || fogZones.isEmpty || !_insideFog(enemy.position)) return;
    _damageEnemy(enemy, enemy.maxHp * kFogDpsRatio * dt, quiet: true, ignoreArmor: true);
  }

  /// 敌人走到终点扣减萝卜血量；血量归零时返回 true。
  bool _leak(Enemy enemy) {
    final goal = enemy.track.end;
    enemy.alive = false;
    _aliveCount--;
    leaked++;
    carrotHp = math.max(0, carrotHp - enemy.damage);
    _carrotPulse = 1;
    effects.add(Effect.leak(goal));
    floaters.add(Floater.damage(enemy.damage, goal + const Offset(0, -48)));
    events.add(GameEvent.leak);
    _bump();
    if (carrotHp > 0) return false;
    status = GameStatus.defeat;
    events.add(GameEvent.defeat);
    _announceResult();
    return true;
  }

  bool _insideFog(Offset position) {
    for (final (center, radiusSquared) in fogZones) {
      final dx = position.dx - center.dx;
      final dy = position.dy - center.dy;
      if (dx * dx + dy * dy <= radiusSquared) return true;
    }
    return false;
  }

  void _removeDeadEnemies() {
    if (enemies.length == _aliveCount) return;
    var write = 0;
    for (var read = 0; read < enemies.length; read++) {
      final enemy = enemies[read];
      if (enemy.alive) {
        enemies[write++] = enemy;
      } else {
        _enemyIndex.remove(enemy.id);
      }
    }
    if (write != enemies.length) enemies.length = write;
  }

  void _updateTowers(double dt) {
    for (final tower in _activeTowers) {
      if (tower.cooldown > 0) tower.cooldown -= dt;
      if (tower.recoil > 0) tower.recoil = math.max(0, tower.recoil - dt * 4);
      if (tower.cooldown > 0) continue;
      if (status != GameStatus.battle) continue;
      final target = _findTarget(tower);
      if (target == null) {
        tower.cooldown = 0;
        continue;
      }
      final targetPosition = enemyPosition(target);
      tower.angle = math.atan2(
        targetPosition.dy - tower.position.dy,
        targetPosition.dx - tower.position.dx,
      );
      _fire(tower, target);
      tower.cooldown = tower.stats.interval;
    }
  }

  Enemy? _findTarget(Tower tower) {
    Enemy? best;
    var bestProgress = -1.0;
    for (final enemy in enemies) {
      if (!enemy.alive) continue;
      final position = enemy.position;
      final dx = position.dx - tower.position.dx;
      final dy = position.dy - tower.position.dy;
      final range = tower.stats.range + enemy.radius;
      if (dx * dx + dy * dy > range * range) {
        continue;
      }
      if (enemy.progress > bestProgress) {
        bestProgress = enemy.progress;
        best = enemy;
      }
    }
    return best;
  }

  void _fire(Tower tower, Enemy target) {
    tower.recoil = 1;
    if (tower.kind == TowerKind.lightning) {
      _chainLightning(tower, target);
      events.add(GameEvent.lightning);
      return;
    }
    final (speed, shot) = _shotProfiles[tower.kind]!;
    _launch(tower, target, speed: speed, stats: tower.stats);
    events.add(shot);
  }

  /// 各类弹道塔的飞行速度与开火音效。
  static const Map<TowerKind, (double, GameEvent)> _shotProfiles = {
    TowerKind.arrow: (940, GameEvent.arrowShot),
    TowerKind.cannon: (430, GameEvent.cannonShot),
    TowerKind.frost: (720, GameEvent.frostShot),
    TowerKind.poison: (640, GameEvent.poisonShot),
  };

  void _launch(Tower tower, Enemy target, {required double speed, required TowerStats stats}) {
    final targetPosition = enemyPosition(target);
    final distance = (targetPosition - tower.position).distance;
    projectiles.add(
      Projectile(
        kind: tower.kind,
        targetId: target.id,
        position: tower.position + _direction(tower.angle) * 16,
        targetPosition: targetPosition,
        speed: speed,
        damage: stats.damage,
        splash: stats.splash,
        slowFactor: stats.slowFactor,
        slowDuration: stats.slowDuration,
        poisonDps: stats.poisonDps,
        poisonDuration: stats.poisonDuration,
        flightTime: math.max(0.08, distance / speed),
      ),
    );
  }

  void _chainLightning(Tower tower, Enemy first) {
    final points = <Offset>[tower.position + _direction(tower.angle) * 12];
    final hit = <int>{};
    var current = first;
    var damage = tower.stats.damage;
    for (var jump = 0; jump < tower.stats.chains; jump++) {
      points.add(enemyPosition(current));
      hit.add(current.id);
      _damageEnemy(current, damage);
      damage *= kChainFalloff;
      Enemy? next;
      var best = kChainRadius * kChainRadius;
      final origin = current.position;
      for (final enemy in enemies) {
        if (!enemy.alive || hit.contains(enemy.id)) continue;
        final dx = enemy.position.dx - origin.dx;
        final dy = enemy.position.dy - origin.dy;
        final squared = dx * dx + dy * dy;
        if (squared < best) {
          best = squared;
          next = enemy;
        }
      }
      if (next == null) break;
      current = next;
    }
    effects.add(Effect.lightning(points));
  }

  void _updateProjectiles(double dt) {
    for (final projectile in projectiles) {
      projectile.elapsed += dt;
      final target = _enemyById(projectile.targetId);
      if (target != null && target.alive) {
        projectile.lastTarget = enemyPosition(target);
      }
      final delta = projectile.lastTarget - projectile.position;
      final distance = delta.distance;
      final step = projectile.speed * dt;
      if (distance <= step || projectile.elapsed >= projectile.flightTime) {
        projectile.position = projectile.lastTarget;
        projectile.impact = projectile.lastTarget;
        projectile.done = true;
        _impact(projectile);
      } else {
        projectile.position += delta / distance * step;
      }
    }
    projectiles.removeWhere((projectile) => projectile.done);
  }

  void _impact(Projectile projectile) {
    final impact = projectile.impact ?? projectile.position;
    final target = _enemyById(projectile.targetId);
    events.add(GameEvent.hit);

    if (projectile.splash > 0) {
      final radius = projectile.splash;
      for (final enemy in enemies) {
        if (!enemy.alive) continue;
        final dx = enemy.position.dx - impact.dx;
        final dy = enemy.position.dy - impact.dy;
        final reach = radius + enemy.radius;
        if (dx * dx + dy * dy <= reach * reach) {
          _damageEnemy(enemy, projectile.damage);
          _applySlow(enemy, projectile);
          _applyPoison(enemy, projectile);
        }
      }
      effects.add(switch (projectile.kind) {
        TowerKind.frost => Effect.frostRing(impact, radius: projectile.splash),
        TowerKind.poison => Effect.poisonCloud(impact, radius: projectile.splash),
        _ => Effect.explosion(impact, radius: projectile.splash),
      });
      return;
    }

    if (target == null || !target.alive) {
      effects.add(Effect.spark(impact, radius: 16, duration: 0.25));
      return;
    }
    _damageEnemy(target, projectile.damage);
    _applySlow(target, projectile);
    _applyPoison(target, projectile);
    effects.add(Effect.spark(impact));
  }

  void _applyPoison(Enemy enemy, Projectile projectile) {
    if (enemy.flying) return;
    if (projectile.poisonDps <= 0 || projectile.poisonDuration <= 0) return;
    enemy.poisonDps = math.max(enemy.poisonDps, projectile.poisonDps);
    enemy.poisonTimer = math.max(enemy.poisonTimer, projectile.poisonDuration);
  }

  /// 中毒伤害无视护甲，按逻辑帧持续结算，击杀仍然结算赏金。
  void _tickPoison(double dt) {
    for (final enemy in enemies) {
      if (!enemy.alive || enemy.poisonTimer <= 0) continue;
      enemy.poisonTimer = math.max(0, enemy.poisonTimer - dt);
      _damageEnemy(enemy, enemy.poisonDps * dt, quiet: true, ignoreArmor: true);
      if (enemy.poisonTimer <= 0) enemy.poisonDps = 0;
    }
  }

  void _applySlow(Enemy enemy, Projectile projectile) {
    if (enemy.flying) return;
    if (projectile.slowFactor >= 1 || projectile.slowDuration <= 0) return;
    if (projectile.slowFactor < enemy.slowFactor || enemy.slowTimer <= 0) {
      enemy.slowFactor = projectile.slowFactor;
      enemy.slowTimer = projectile.slowDuration;
    } else {
      enemy.slowTimer = math.max(enemy.slowTimer, projectile.slowDuration);
    }
  }

  void _damageEnemy(Enemy enemy, double damage, {bool quiet = false, bool ignoreArmor = false}) {
    if (!enemy.alive) return;
    enemy.hp -= damage * (ignoreArmor ? 1 : enemy.armor);
    if (!quiet) enemy.flash = 0.14;
    if (enemy.hp > 0) return;
    enemy.alive = false;
    _aliveCount--;
    kills++;
    gold += enemy.bounty;
    goldEarned += enemy.bounty;
    final position = enemy.position;
    floaters.add(Floater.gold(enemy.bounty, position + const Offset(0, -24)));
    effects.add(Effect.spark(position, radius: enemy.radius * 1.6, duration: 0.35));
    events.add(GameEvent.gold);
    if (enemy.isBoss) {
      effects.add(Effect.explosion(position, radius: 120, duration: 0.8));
    }
    _bump();
  }

  Enemy? _enemyById(int id) => _enemyIndex[id];

  void _checkWaveComplete() {
    if (_aliveCount > 0) return;
    final schedule = _schedule;
    if (schedule != null && !schedule.done) return;
    final wave = level.waves[waveIndex - 1];
    gold += wave.reward;
    goldEarned += wave.reward;
    events.add(GameEvent.waveClear);
    _schedule = null;
    if (waveIndex >= level.waveCount) {
      status = GameStatus.victory;
      stars = starRating(carrotHp: carrotHp, carrotMaxHp: carrotMaxHp);
      events.add(GameEvent.victory);
      _announceResult();
    } else {
      status = GameStatus.preparing;
      prepTimer = _nextPrepSeconds;
    }
    _bump();
  }

  void _announceResult() {
    if (_resultAnnounced) return;
    _resultAnnounced = true;
    _bump();
  }

  void _updateVisuals(double dt) {
    for (final effect in effects) {
      effect.elapsed += dt;
    }
    effects.removeWhere((effect) => effect.finished);
    for (final floater in floaters) {
      floater.elapsed += dt;
    }
    floaters.removeWhere((floater) => floater.finished);
    if (_carrotPulse > 0) _carrotPulse = math.max(0, _carrotPulse - dt * 2.4);
  }

  void _tickHud(double dt) {
    _hudTimer += dt;
    if (_hudTimer >= _hudRefreshSeconds) {
      _hudTimer = 0;
      _bump();
    }
  }

  /// HUD 只关心显示内容的整数变化，值没变时不触发组件树重建。
  void _bump() {
    final key = _hudKey();
    if (key == _lastHudKey) return;
    _lastHudKey = key;
    hud.value++;
  }

  int _hudKey() {
    final slot = selectedSlot ?? -1;
    final tower = selectedTower;
    var key = status.index;
    key = (key * 31 + carrotHp) & 0x7FFFFFFF;
    key = (key * 31 + carrotMaxHp) & 0x7FFFFFFF;
    key = (key * 31 + gold) & 0x7FFFFFFF;
    key = (key * 31 + waveIndex) & 0x7FFFFFFF;
    key = (key * 31 + prepTimer.ceil()) & 0x7FFFFFFF;
    key = (key * 31 + remainingEnemies) & 0x7FFFFFFF;
    key = (key * 31 + slot) & 0x7FFFFFFF;
    key = (key * 31 + (armedKind?.index ?? -1)) & 0x7FFFFFFF;
    key = (key * 31 + (tower?.level ?? 0)) & 0x7FFFFFFF;
    return key;
  }

  double get carrotPulse => _carrotPulse;

  void dispose() => hud.dispose();

  static Offset _direction(double angle) => Offset(math.cos(angle), math.sin(angle));
}
