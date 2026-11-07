import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../models/defense_models.dart';
import '../../models/level.dart';
import '../balance.dart';
import 'entities.dart';
import 'path_track.dart';

class _Spawn {
  const _Spawn(this.time, this.kind, this.hpScale);

  final double time;
  final EnemyKind kind;
  final double hpScale;
}

/// 塔防核心逻辑：纯数据驱动，不依赖渲染，可在测试中直接快进模拟。
class DefenseEngine {
  DefenseEngine({required this.level})
    : track = PathTrack([for (final point in level.path) point.design]),
      slotPositions = [for (final slot in level.slots) slot.design] {
    gold = level.startGold;
    carrotMaxHp = level.carrotHp;
    carrotHp = level.carrotHp;
    towers = List<Tower?>.filled(level.slots.length, null);
    prepTimer = _firstPrepSeconds;
    _lastHudKey = _hudKey();
  }

  final LevelDef level;
  final PathTrack track;
  final List<Offset> slotPositions;
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

  final List<_Spawn> _schedule = [];
  int _spawnCursor = 0;
  int _waveTotal = 0;
  int _nextEnemyId = 1;
  double _hudTimer = 0;
  double _carrotPulse = 0;
  bool _resultAnnounced = false;
  int _lastHudKey = 0;

  /// 首波准备时间；之后每波固定 10 秒。
  static const double _firstPrepSeconds = 18;
  static const double _nextPrepSeconds = 10;

  Tower? towerAt(int slot) =>
      slot < 0 || slot >= towers.length ? null : towers[slot];

  Tower? get selectedTower {
    final slot = selectedSlot;
    return slot == null ? null : towerAt(slot);
  }

  Offset enemyPosition(Enemy enemy, {double alpha = 1}) {
    if (alpha >= 1) return enemy.position;
    return Offset.lerp(enemy.prevPosition, enemy.position, alpha)!;
  }

  /// 路径上的落点：中心线加横向错位，仅在敌人移动或生成时计算一次。
  Offset _trackPosition(double distance, double lateral) {
    final sample = track.sampleAt(distance);
    return sample.position +
        Offset(-sample.tangent.dy, sample.tangent.dx) * lateral;
  }

  int get remainingEnemies {
    if (status != GameStatus.battle) return 0;
    var pending = 0;
    for (var i = _spawnCursor; i < _schedule.length; i++) {
      pending++;
    }
    return enemies.where((enemy) => enemy.alive).length + pending;
  }

  double get waveProgress {
    if (_waveTotal <= 0) return 0;
    return (1 - remainingEnemies / _waveTotal).clamp(0.0, 1.0);
  }

  int get earlyBonus => status == GameStatus.preparing ? prepTimer.ceil() : 0;

  bool get isFinished =>
      status == GameStatus.victory || status == GameStatus.defeat;

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
    final tower = Tower(
      slotIndex: slot,
      kind: kind,
      position: slotPositions[slot],
    )..totalSpent = cost;
    towers[slot] = tower;
    _activeTowers.add(tower);
    selectedSlot = slot;
    effects.add(
      Effect(
        kind: EffectKind.buildDust,
        position: tower.position,
        radius: 34,
        duration: 0.45,
      ),
    );
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
    effects.add(
      Effect(
        kind: EffectKind.buildDust,
        position: tower.position,
        radius: 40,
        duration: 0.5,
      ),
    );
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
    effects.add(
      Effect(
        kind: EffectKind.buildDust,
        position: tower.position,
        radius: 30,
        duration: 0.4,
      ),
    );
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
      floaters.add(
        Floater(
          text: '提前出击 +$bonus',
          position: track.pointAt(0) + const Offset(30, -20),
          color: const Color(0xFFFFE08A),
        ),
      );
    }
    _beginWave();
    return true;
  }

  void _beginWave() {
    final wave = level.waves[waveIndex];
    _schedule
      ..clear()
      ..addAll(_buildSchedule(wave, level.hpScale * wave.hpScale));
    _spawnCursor = 0;
    _waveTotal = _schedule.length;
    waveElapsed = 0;
    waveIndex++;
    status = GameStatus.battle;
    events.add(GameEvent.waveStart);
    _bump();
  }

  List<_Spawn> _buildSchedule(WaveDef wave, double hpScale) {
    final list = <_Spawn>[];
    for (final group in wave.groups) {
      for (var i = 0; i < group.count; i++) {
        list.add(_Spawn(group.delay + i * group.gap, group.kind, hpScale));
      }
    }
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
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
    while (_spawnCursor < _schedule.length &&
        _schedule[_spawnCursor].time <= waveElapsed) {
      final item = _schedule[_spawnCursor++];
      _spawnEnemy(item);
    }
  }

  void _spawnEnemy(_Spawn item) {
    final base = kEnemyStats[item.kind]!;
    final id = _nextEnemyId++;
    final lateral = item.kind == EnemyKind.boss ? 0.0 : ((id % 5) - 2) * 4.5;
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
    );
    final position = _trackPosition(0, lateral);
    enemy
      ..position = position
      ..prevPosition = position;
    enemies.add(enemy);
    _enemyIndex[id] = enemy;
  }

  void _moveEnemies(double dt) {
    final reach = track.length;
    var dead = false;
    for (final enemy in enemies) {
      if (!enemy.alive) continue;
      enemy.prevPosition = enemy.position;
      if (enemy.slowTimer > 0) {
        enemy.slowTimer = math.max(0, enemy.slowTimer - dt);
      }
      enemy.distance += enemy.currentSpeed * dt;
      enemy.position = _trackPosition(enemy.distance, enemy.lateral);
      if (enemy.flash > 0) enemy.flash = math.max(0, enemy.flash - dt);
      if (enemy.distance >= reach) {
        enemy.alive = false;
        leaked++;
        carrotHp = math.max(0, carrotHp - enemy.damage);
        _carrotPulse = 1;
        effects.add(
          Effect(
            kind: EffectKind.leak,
            position: track.points.last,
            radius: 46,
            duration: 0.5,
          ),
        );
        floaters.add(
          Floater(
            text: '-${enemy.damage}',
            position: track.points.last + const Offset(0, -48),
            color: const Color(0xFFFF7A6B),
            big: true,
          ),
        );
        events.add(GameEvent.leak);
        _bump();
        if (carrotHp <= 0) {
          status = GameStatus.defeat;
          events.add(GameEvent.defeat);
          _announceResult();
          dead = true;
          break;
        }
      }
    }
    if (dead) {
      for (final enemy in enemies) {
        if (enemy.distance >= reach) enemy.alive = false;
      }
    }
    _removeDeadEnemies();
  }

  void _removeDeadEnemies() {
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
    var bestDistance = -1.0;
    for (final enemy in enemies) {
      if (!enemy.alive) continue;
      final position = enemy.position;
      final dx = position.dx - tower.position.dx;
      final dy = position.dy - tower.position.dy;
      final range = tower.stats.range + enemy.radius;
      if (dx * dx + dy * dy > range * range) {
        continue;
      }
      if (enemy.distance > bestDistance) {
        bestDistance = enemy.distance;
        best = enemy;
      }
    }
    return best;
  }

  void _fire(Tower tower, Enemy target) {
    final stats = tower.stats;
    tower.recoil = 1;
    switch (tower.kind) {
      case TowerKind.arrow:
        _launch(tower, target, speed: 940, stats: stats);
        events.add(GameEvent.arrowShot);
        break;
      case TowerKind.cannon:
        _launch(tower, target, speed: 430, stats: stats);
        events.add(GameEvent.cannonShot);
        break;
      case TowerKind.frost:
        _launch(tower, target, speed: 720, stats: stats);
        events.add(GameEvent.frostShot);
        break;
      case TowerKind.lightning:
        _chainLightning(tower, target);
        events.add(GameEvent.lightning);
        break;
    }
  }

  void _launch(
    Tower tower,
    Enemy target, {
    required double speed,
    required TowerStats stats,
  }) {
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
    effects.add(
      Effect(
        kind: EffectKind.lightning,
        position: points.first,
        points: points,
        duration: 0.22,
      ),
    );
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
        }
      }
      effects.add(
        Effect(
          kind: projectile.kind == TowerKind.frost
              ? EffectKind.frostRing
              : EffectKind.explosion,
          position: impact,
          radius: projectile.splash,
          duration: 0.45,
        ),
      );
      return;
    }

    if (target == null || !target.alive) {
      effects.add(
        Effect(
          kind: EffectKind.spark,
          position: impact,
          radius: 16,
          duration: 0.25,
        ),
      );
      return;
    }
    _damageEnemy(target, projectile.damage);
    _applySlow(target, projectile);
    effects.add(
      Effect(
        kind: EffectKind.spark,
        position: impact,
        radius: 14,
        duration: 0.22,
      ),
    );
  }

  void _applySlow(Enemy enemy, Projectile projectile) {
    if (projectile.slowFactor >= 1 || projectile.slowDuration <= 0) return;
    if (projectile.slowFactor < enemy.slowFactor || enemy.slowTimer <= 0) {
      enemy.slowFactor = projectile.slowFactor;
      enemy.slowTimer = projectile.slowDuration;
    } else {
      enemy.slowTimer = math.max(enemy.slowTimer, projectile.slowDuration);
    }
  }

  void _damageEnemy(Enemy enemy, double damage) {
    if (!enemy.alive) return;
    enemy.hp -= damage * enemy.armor;
    enemy.flash = 0.14;
    if (enemy.hp > 0) return;
    enemy.alive = false;
    kills++;
    gold += enemy.bounty;
    goldEarned += enemy.bounty;
    final position = enemy.position;
    floaters.add(
      Floater(
        text: '+${enemy.bounty}',
        position: position + const Offset(0, -24),
        color: const Color(0xFFFFE08A),
      ),
    );
    effects.add(
      Effect(
        kind: EffectKind.spark,
        position: position,
        radius: enemy.radius * 1.6,
        duration: 0.35,
      ),
    );
    events.add(GameEvent.gold);
    if (enemy.isBoss) {
      effects.add(
        Effect(
          kind: EffectKind.explosion,
          position: position,
          radius: 120,
          duration: 0.8,
        ),
      );
    }
    _bump();
  }

  Enemy? _enemyById(int id) => _enemyIndex[id];

  void _checkWaveComplete() {
    if (enemies.isNotEmpty) return;
    if (_spawnCursor < _schedule.length) return;
    final wave = level.waves[waveIndex - 1];
    gold += wave.reward;
    goldEarned += wave.reward;
    events.add(GameEvent.waveClear);
    _schedule.clear();
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
    if (_hudTimer >= 0.1) {
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

  static Offset _direction(double angle) =>
      Offset(math.cos(angle), math.sin(angle));
}
