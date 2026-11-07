import 'dart:ui' as ui;

import 'package:carrot_defense/flame/art_utils.dart';
import 'package:carrot_defense/flame/board_component.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/engine/entities.dart';
import 'package:carrot_defense/game/engine/path_track.dart';
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
      final track = PathTrack([
        for (final point in kLevels.first.path) point.design,
      ]);
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
      final track = PathTrack([
        for (final point in kLevels.first.path) point.design,
      ]);
      expect(track.pointAt(-50), track.points.first);
      expect(track.pointAt(track.length + 50), track.points.last);
    });

    test('起点、终点与飞行航线长度由路径统一提供', () {
      final track = PathTrack([
        for (final point in kLevels.first.path) point.design,
      ]);
      expect(track.start, track.points.first);
      expect(track.end, track.points.last);
      expect(
        track.airLength,
        closeTo((track.points.last - track.points.first).distance, 0.001),
      );
    });

    test('单调游标与二分采样一致，距离回退后重新定位', () {
      final track = PathTrack([
        for (final point in kLevels.first.path) point.design,
      ]);
      final cursor = PathCursor();
      for (var i = 0; i <= 200; i++) {
        final distance = track.length * i / 200;
        final lateral = (i % 7 - 3) * 2.5;
        final sample = track.sampleAt(distance);
        final expected =
            sample.position +
            Offset(-sample.tangent.dy, sample.tangent.dx) * lateral;
        expect(
          (cursor.sample(track, distance, lateral) - expected).distance,
          lessThan(0.001),
          reason: '游标在 $distance 处与二分采样不一致',
        );
      }
      final sample = track.sampleAt(12);
      final expected =
          sample.position + Offset(-sample.tangent.dy, sample.tangent.dx) * 3;
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
          sample.position +
          Offset(-sample.tangent.dy, sample.tangent.dx) * enemy.lateral;
      expect(
        (engine.enemyPosition(enemy) - expected).distance,
        lessThan(0.001),
      );
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
  });

  group('渲染缓存', () {
    test('静态图层与背景只录制一次，尺寸变化才重建背景', () {
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
      expect(board.backdropBuilds, 1);

      _renderOnce(board);
      expect(board.staticLayerBuilds, 1);
      expect(board.backdropBuilds, 1);

      board.size = Vector2(1024, 600);
      _renderOnce(board);
      expect(board.staticLayerBuilds, 1, reason: '静态图层与尺寸无关');
      expect(board.backdropBuilds, 2, reason: '尺寸变化后背景需要重录');

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
