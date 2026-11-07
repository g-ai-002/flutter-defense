import 'dart:ui' as ui;

import 'package:carrot_defense/flame/board_component.dart';
import 'package:carrot_defense/game/balance.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:carrot_defense/game/logic_rate.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:carrot_defense/theme/level_theme.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// 一条折线土路：蝠妖的直线航线会明显偏离路面。
LevelDef bentLevel({List<WaveDef>? waves}) => LevelDef(
  id: 98,
  name: '折线测试',
  subtitle: '测试',
  theme: LevelTheme.meadow,
  path: const [
    GridPos(-1.2, 2),
    GridPos(4, 2),
    GridPos(4, 6),
    GridPos(8, 6),
    GridPos(8, 2),
    GridPos(14, 2),
  ],
  slots: const [GridPos(2, 4), GridPos(6, 4)],
  startGold: 1000,
  carrotHp: 10,
  hpScale: 1,
  waves:
      waves ??
      [
        WaveDef([spawn(EnemyKind.flyer, 1)], reward: 0),
      ],
  seed: 7,
);

void main() {
  setUpAll(initTestEnvironment);

  group('蝠妖', () {
    test('沿入口到萝卜的直线飞行，不跟随土路', () {
      final engine = DefenseEngine(level: bentLevel());
      engine.startNextWave();
      engine.update(1 / 60);
      final enemy = engine.enemies.single;

      expect(enemy.flying, isTrue);
      expect(enemy.routeLength, lessThan(engine.track.length));
      expect(
        (engine.track.points.last - engine.track.points.first).distance,
        closeTo(enemy.routeLength, 0.001),
      );

      advance(engine, 9);
      final expected = Offset.lerp(
        engine.track.points.first,
        engine.track.points.last,
        enemy.progress,
      )!;
      expect((enemy.position - expected).distance, lessThan(0.01));
      expect(
        engine.track.distanceTo(enemy.position),
        greaterThan(80),
        reason: '航线中段应离开土路',
      );
    });

    test('免疫减速与中毒，但仍会被正常命中', () {
      final engine = DefenseEngine(
        level: straightLevel(
          waves: [
            WaveDef([spawn(EnemyKind.flyer, 1)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      engine.update(0.02);
      final enemy = engine.enemies.single;
      enemy.distance = 300;
      engine.update(0.02);

      expect(engine.build(0, TowerKind.frost), isTrue);
      expect(engine.build(1, TowerKind.poison), isTrue);
      advance(engine, 2.5);

      expect(enemy.slowed, isFalse);
      expect(enemy.poisoned, isFalse);
      expect(enemy.hp, lessThan(enemy.maxHp));
    });
  });

  group('毒雾地形', () {
    test('地面敌人持续掉血，且伤害无视护甲', () {
      final engine = DefenseEngine(
        level: straightLevel(
          fog: const [FogZone(GridPos(6, 4), radius: 120)],
          waves: [
            WaveDef([spawn(EnemyKind.beetle, 1)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      engine.update(0.02);
      final enemy = engine.enemies.single;
      expect(enemy.armor, lessThan(1));
      enemy.distance = 420;
      engine.update(0.02);

      final before = enemy.hp;
      advance(engine, 1, step: 0.05);
      final loss = before - enemy.hp;
      expect(
        loss,
        closeTo(enemy.maxHp * kFogDpsRatio, enemy.maxHp * kFogDpsRatio * 0.2),
        reason: '毒雾伤害不应被护甲削减',
      );
    });

    test('飞行敌人不受毒雾影响', () {
      final engine = DefenseEngine(
        level: straightLevel(
          fog: const [FogZone(GridPos(6, 4), radius: 120)],
          waves: [
            WaveDef([spawn(EnemyKind.flyer, 1)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      engine.update(0.02);
      final enemy = engine.enemies.single;
      enemy.distance = 420;
      engine.update(0.02);
      final before = enemy.hp;
      advance(engine, 1, step: 0.05);
      expect(enemy.hp, before);
    });
  });

  test('毒雾与蝠妖可以正常渲染', () {
    final engine = DefenseEngine(
      level: straightLevel(
        fog: const [FogZone(GridPos(6, 4), radius: 120)],
        waves: [
          WaveDef([
            spawn(EnemyKind.flyer, 3, gap: 0.6),
            spawn(EnemyKind.slime, 4, gap: 0.6),
          ], reward: 0),
        ],
      ),
    );
    final paused = ValueNotifier<bool>(false);
    final speed = ValueNotifier<double>(1);
    final board = BoardComponent(
      engine: engine,
      logicRate: LogicRate.hz60,
      pausedNotifier: paused,
      speed: speed,
    )..size = Vector2(1280, 720);
    engine.startNextWave();
    advance(engine, 3);

    final recorder = ui.PictureRecorder();
    board.render(Canvas(recorder));
    recorder.endRecording().dispose();
    expect(engine.enemies.any((enemy) => enemy.flying), isTrue);

    board.onRemove();
    engine.dispose();
    paused.dispose();
    speed.dispose();
  });

  group('毒沼秘境', () {
    test('包含毒雾区与蝠妖波次，强度高于魔王城塞', () {
      final level = kLevels.last;
      expect(level.name, '毒沼秘境');
      expect(level.hasFog, isTrue);
      expect(level.fog.every((zone) => zone.radius > 0), isTrue);
      expect(
        level.waves.any(
          (wave) => wave.groups.any((group) => group.kind == EnemyKind.flyer),
        ),
        isTrue,
      );
      expect(level.hpScale, greaterThan(kLevels[kLevels.length - 2].hpScale));
    });
  });
}
