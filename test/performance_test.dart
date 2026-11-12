import 'dart:ui' as ui;

import 'package:carrot_defense/flame/art_utils.dart';
import 'package:carrot_defense/flame/board_component.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/engine/entities.dart';
import 'package:carrot_defense/game/engine/path_track.dart';
import 'package:carrot_defense/game/engine/route_plan.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:carrot_defense/game/logic_rate.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  setUpAll(initTestEnvironment);

  group('路径采样', () {
    test('二分采样与线性参考实现一致', () {
      final track = PathTrack([for (final point in kLevels.first.path) point.design]);
      for (var i = 0; i <= 200; i++) {
        final distance = track.length * i / 200;
        final sample = track.sampleAt(distance);
        final expected = _referenceSample(track.points, distance);
        expect(
          (sample.position - expected.position).distance,
          lessThan(0.001),
          reason: '位置在 $distance 处不一致',
        );
        expect(
          (sample.tangent - expected.tangent).distance,
          lessThan(0.001),
          reason: '切线在 $distance 处不一致',
        );
        expect(sample.tangent.distance, closeTo(1, 0.001));
      }
    });

    test('越界距离收敛到端点', () {
      final track = PathTrack([for (final point in kLevels.first.path) point.design]);
      expect(track.pointAt(-50), track.points.first);
      expect(track.pointAt(track.length + 50), track.points.last);
    });

    test('起点、终点与飞行航线长度由路径统一提供', () {
      final track = PathTrack([for (final point in kLevels.first.path) point.design]);
      expect(track.start, track.points.first);
      expect(track.end, track.points.last);
      expect(track.airLength, closeTo((track.points.last - track.points.first).distance, 0.001));
    });

    test('单调游标与二分采样一致，距离回退后重新定位', () {
      final track = PathTrack([for (final point in kLevels.first.path) point.design]);
      final cursor = PathCursor();
      for (var i = 0; i <= 200; i++) {
        final distance = track.length * i / 200;
        final lateral = (i % 7 - 3) * 2.5;
        final sample = track.sampleAt(distance);
        final expected = sample.position + Offset(-sample.tangent.dy, sample.tangent.dx) * lateral;
        expect(
          (cursor.sample(track, distance, lateral) - expected).distance,
          lessThan(0.001),
          reason: '游标在 $distance 处与二分采样不一致',
        );
      }
      final sample = track.sampleAt(12);
      final expected = sample.position + Offset(-sample.tangent.dy, sample.tangent.dx) * 3;
      expect(
        (cursor.sample(track, 12, 3) - expected).distance,
        lessThan(0.001),
        reason: '距离回退后应从头重新定位',
      );
    });
  });

  group('引擎热点缓存', () {
    test('敌人位置在移动时缓存，插值结果落在前后位置之间', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 0,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1)]),
          ],
        ),
      );
      engine.startNextWave();
      for (var i = 0; i < 30; i++) {
        engine.update(1 / 60);
      }
      final enemy = engine.enemies.single;
      expect(enemy.position, isNot(Offset.zero));
      final mid = engine.enemyPosition(enemy, alpha: 0.5);
      final lerped = Offset.lerp(enemy.prevPosition, enemy.position, 0.5)!;
      expect((mid - lerped).distance, lessThan(0.0001));

      final sample = engine.track.sampleAt(enemy.distance);
      final expected =
          sample.position + Offset(-sample.tangent.dy, sample.tangent.dx) * enemy.lateral;
      expect((engine.enemyPosition(enemy) - expected).distance, lessThan(0.001));
    });

    test('已建塔列表增量维护且可原地复用', () {
      final engine = DefenseEngine(level: kLevels.first);
      final list = engine.activeTowers;
      expect(list, isEmpty);
      expect(engine.build(0, TowerKind.arrow), isTrue);
      expect(engine.activeTowers, same(list));
      expect(engine.activeTowers.length, 1);
      expect(engine.sell(0), isTrue);
      expect(engine.activeTowers, isEmpty);
    });

    test('HUD 只在显示数据变化时通知', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 500,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1, delay: 60)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      var notifications = 0;
      engine.hud.addListener(() => notifications++);

      for (var i = 0; i < 10; i++) {
        engine.update(0.1);
      }
      expect(notifications, 0, reason: '画面数值未变化时不应重建 HUD');

      expect(engine.build(0, TowerKind.arrow), isTrue);
      expect(notifications, 1, reason: '金币变化应触发一次 HUD 刷新');
    });

    test('状态变化仍会通知 HUD', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 0,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1)], reward: 0),
          ],
        ),
      );
      var notifications = 0;
      engine.hud.addListener(() => notifications++);
      engine.startNextWave();
      advance(engine, 30);
      expect(engine.status, GameStatus.victory);
      expect(notifications, greaterThan(0));
    });

    test('最后一只敌人被击杀的同一逻辑步即结算波次', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 500,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1)], reward: 0),
          ],
        ),
      );
      expect(engine.build(0, TowerKind.arrow), isTrue);
      engine.startNextWave();
      var killedAt = -1;
      for (var i = 0; i < 60 * 30 && !engine.isFinished; i++) {
        engine.update(1 / 60);
        if (killedAt < 0 && engine.kills == 1) {
          killedAt = i;
          expect(engine.status, GameStatus.victory, reason: '存活计数归零后应立刻结算，不再等待下一帧压缩列表');
        }
      }
      expect(killedAt, greaterThanOrEqualTo(0));
      expect(engine.status, GameStatus.victory);
    });

    test('帧内敌人顺序按进度升序复用同一份列表', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 0,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 4, gap: 0.3)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      advance(engine, 6);
      final order = engine.frameOrder;
      expect(order, isNotEmpty);
      expect(identical(engine.frameOrder, order), isTrue, reason: '同帧多次查询不应重建列表');
      expect(order.length, engine.enemies.where((enemy) => enemy.alive).length);
      for (var i = 1; i < order.length; i++) {
        expect(order[i - 1].progress, lessThanOrEqualTo(order[i].progress), reason: '索敌倒序扫描依赖进度升序');
      }
    });

    test('无传送门的路线共用空跳跃表，传送门关卡按路线缓存', () {
      final plain = DefenseEngine(level: kLevels.first);
      plain.startNextWave();
      advance(plain, 1);
      expect(plain.enemies, isNotEmpty);
      expect(plain.enemies.every((enemy) => identical(enemy.jumps, RoutePlan.noJumps)), isTrue);

      final portalLevel = kLevels.firstWhere((level) => level.portals.isNotEmpty);
      final engine = DefenseEngine(level: portalLevel);
      engine.startNextWave();
      advance(engine, 2);
      expect(
        engine.enemies.any((enemy) => identical(enemy.jumps, engine.plan.jumpsOn(enemy.route))),
        isTrue,
        reason: '敌人直接持有本路线的跳跃表，逐帧判定不再查表',
      );
    });

    test('敌人进度随距离赋值即时刷新，越界时收敛到 0 或 1', () {
      final engine = DefenseEngine(
        level: straightLevel(
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      engine.update(0.05);
      final enemy = engine.enemies.single;
      enemy.distance = enemy.routeLength * 0.5;
      expect(enemy.progress, closeTo(0.5, 0.0001));
      enemy.distance = enemy.routeLength * 2;
      expect(enemy.progress, 1);
      enemy.distance = -20;
      expect(enemy.progress, 0);
    });

    test('插入排序在敌人超车后仍复用同一份升序列表', () {
      final engine = DefenseEngine(
        level: straightLevel(
          waves: [
            WaveDef([spawn(EnemyKind.slime, 2, gap: 0.3)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      advance(engine, 3);
      final first = engine.enemies.first;
      final second = engine.enemies.last;
      final order = engine.frameOrder;
      expect(order.first, second, reason: '后出发的敌人进度更小');
      expect(order.last, first, reason: '先出发的敌人应排在进度更大的位置');

      first.distance = first.routeLength * 0.1;
      second.distance = second.routeLength * 0.9;
      engine.update(1 / 60);

      final reordered = engine.frameOrder;
      expect(identical(reordered, order), isTrue, reason: '排序应原地复用列表');
      expect(reordered.last, second, reason: '超车后应按新进度重排');
      for (var i = 1; i < reordered.length; i++) {
        expect(reordered[i - 1].progress, lessThanOrEqualTo(reordered[i].progress));
      }
    });

    test('过期特效、飘字与已命中弹道在一次遍历中原地压缩', () {
      final engine = DefenseEngine(
        level: straightLevel(
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1, delay: 10)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      engine.floaters.clear();
      engine.effects.addAll([
        Effect.spark(const Offset(100, 100), duration: 0.1),
        Effect.explosion(const Offset(120, 100), radius: 30, duration: 1),
      ]);
      engine.floaters.addAll([
        Floater(text: '旧', position: const Offset(100, 100), duration: 0.1),
        Floater(text: '新', position: const Offset(120, 100), duration: 1),
      ]);
      engine.projectiles.addAll([
        Projectile(
          kind: TowerKind.arrow,
          targetId: 999,
          position: const Offset(100, 100),
          targetPosition: const Offset(100, 100),
          speed: 100,
          damage: 1,
          splash: 0,
          slowFactor: 1,
          slowDuration: 0,
          flightTime: 0.05,
        ),
        Projectile(
          kind: TowerKind.arrow,
          targetId: 999,
          position: const Offset(100, 100),
          targetPosition: const Offset(400, 100),
          speed: 10,
          damage: 1,
          splash: 0,
          slowFactor: 1,
          slowDuration: 0,
          flightTime: 10,
        ),
      ]);

      engine.update(0.2);

      expect(engine.effects.first.kind, EffectKind.explosion);
      expect(engine.effects, hasLength(2), reason: '命中会补一个火花特效');
      expect(engine.floaters.single.text, '新');
      expect(engine.projectiles.single.flightTime, 10);
    });
  });

  group('渲染缓存', () {
    test('静态图层只录制一次，尺寸变化不重建', () {
      final engine = DefenseEngine(level: kLevels.first);
      final paused = ValueNotifier<bool>(false);
      final speed = ValueNotifier<double>(1);
      final board = BoardComponent(
        engine: engine,
        logicRate: LogicRate.hz60,
        pausedNotifier: paused,
        speed: speed,
      )..size = Vector2(900, 540);

      // 覆盖建造台、塔、敌人与弹道的绘制路径。
      engine.build(0, TowerKind.arrow);
      engine.build(1, TowerKind.frost);
      engine.startNextWave();
      advance(engine, 3);

      _renderOnce(board);
      expect(board.staticLayerBuilds, 1);

      _renderOnce(board);
      expect(board.staticLayerBuilds, 1);

      board.size = Vector2(1024, 600);
      _renderOnce(board);
      expect(board.staticLayerBuilds, 1, reason: '延伸地貌与尺寸无关，换窗口尺寸无需重录');

      board.onRemove();
      engine.dispose();
      paused.dispose();
      speed.dispose();
    });

    test('重复渲染命中塔、建造台、萝卜与弹道精灵缓存', () {
      final engine = DefenseEngine(level: kLevels.first);
      final paused = ValueNotifier<bool>(false);
      final speed = ValueNotifier<double>(1);
      final board = BoardComponent(
        engine: engine,
        logicRate: LogicRate.hz120,
        pausedNotifier: paused,
        speed: speed,
      )..size = Vector2(900, 540);

      expect(engine.build(0, TowerKind.arrow), isTrue);
      expect(engine.upgrade(0), isTrue);
      expect(engine.build(1, TowerKind.frost), isTrue);
      engine.selectSlot(0);
      engine.projectiles.add(
        Projectile(
          kind: TowerKind.arrow,
          targetId: 0,
          position: engine.slotPositions[0],
          targetPosition: engine.slotPositions[1],
          speed: 900,
          damage: 10,
          splash: 0,
          slowFactor: 1,
          slowDuration: 0,
          flightTime: 1,
        ),
      );
      engine.startNextWave();
      advance(engine, 2);

      _renderOnce(board);
      final builds = debugSpriteBuilds;
      expect(builds, greaterThan(0), reason: '首次渲染应录制战场精灵');

      _renderOnce(board);
      expect(debugSpriteBuilds, builds, reason: '状态未变时不应重新录制精灵');

      board.onRemove();
      engine.dispose();
      paused.dispose();
      speed.dispose();
    });

    test('动态层复用画笔，重复渲染不再新建 Paint', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 900,
          fog: [const FogZone(GridPos(7, 4), radius: 90)],
          waves: [
            WaveDef([spawn(EnemyKind.slime, 3, gap: 0.4)], reward: 0),
          ],
        ),
      );
      expect(engine.build(0, TowerKind.arrow), isTrue);
      expect(engine.build(1, TowerKind.frost), isTrue);
      expect(engine.build(2, TowerKind.poison), isTrue);
      engine.selectSlot(0);
      engine.startNextWave();
      advance(engine, 3);

      final enemy = engine.enemies.firstWhere((enemy) => enemy.alive);
      enemy
        ..hp = enemy.maxHp * 0.4
        ..slowTimer = 1
        ..poisonTimer = 1
        ..flash = 0.1;
      engine.carrotHp = 0;
      engine.armedKind = TowerKind.cannon;
      engine.effects.addAll([
        Effect.explosion(const Offset(300, 300), radius: 40),
        Effect.spark(const Offset(320, 300)),
        Effect.frostRing(const Offset(340, 300), radius: 50),
        Effect.poisonCloud(const Offset(360, 300), radius: 44),
        Effect.buildDust(const Offset(380, 300)),
        Effect.leak(const Offset(400, 300)),
        Effect.lightning(const [Offset(420, 300), Offset(460, 320)]),
      ]);
      engine.floaters.add(Floater.gold(8, const Offset(440, 300)));
      engine.projectiles.add(
        Projectile(
          kind: TowerKind.arrow,
          targetId: enemy.id,
          position: const Offset(300, 300),
          targetPosition: const Offset(500, 300),
          speed: 900,
          damage: 1,
          splash: 0,
          slowFactor: 1,
          slowDuration: 0,
          flightTime: 1,
        ),
      );

      final paused = ValueNotifier<bool>(false);
      final speed = ValueNotifier<double>(1);
      final board = BoardComponent(
        engine: engine,
        logicRate: LogicRate.hz60,
        pausedNotifier: paused,
        speed: speed,
      )..size = Vector2(900, 540);

      _renderOnce(board);
      final builds = debugPaintBuilds;
      expect(builds, greaterThan(0), reason: '首次渲染应录制静态与单位精灵');

      _renderOnce(board);
      expect(debugPaintBuilds, builds, reason: '动态层应复用画笔，不再新建 Paint');

      board.onRemove();
      engine.dispose();
      paused.dispose();
      speed.dispose();
    });
  });
}

void _renderOnce(BoardComponent board) {
  final recorder = ui.PictureRecorder();
  board.render(Canvas(recorder));
  recorder.endRecording().dispose();
}

PathSample _referenceSample(List<Offset> points, double distance) {
  var walked = 0.0;
  for (var i = 1; i < points.length; i++) {
    final delta = points[i] - points[i - 1];
    final span = delta.distance;
    if (distance <= walked + span || i == points.length - 1) {
      final t = span <= 0 ? 0.0 : ((distance - walked) / span).clamp(0.0, 1.0);
      return PathSample(
        Offset.lerp(points[i - 1], points[i], t)!,
        span <= 0 ? const Offset(1, 0) : delta / span,
      );
    }
    walked += span;
  }
  return PathSample(points.first, const Offset(1, 0));
}
