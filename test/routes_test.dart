import 'dart:ui' as ui;

import 'package:carrot_defense/flame/board_component.dart';
import 'package:carrot_defense/game/daily.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/engine/entities.dart';
import 'package:carrot_defense/game/engine/path_track.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:carrot_defense/game/logic_rate.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/endless.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:carrot_defense/services/storage_service.dart';
import 'package:carrot_defense/theme/level_theme.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

LevelDef branchedLevel({List<WaveDef>? waves}) => LevelDef(
  id: 77,
  name: '分岔测试',
  subtitle: '测试',
  theme: LevelTheme.meadow,
  path: const [
    GridPos(-1.2, 4),
    GridPos(4, 4),
    GridPos(4, 2),
    GridPos(12, 2),
    GridPos(12, 4),
    GridPos(15, 4),
  ],
  branch: const [
    GridPos(-1.2, 4),
    GridPos(4, 4),
    GridPos(4, 7),
    GridPos(12, 7),
    GridPos(12, 4),
    GridPos(15, 4),
  ],
  slots: const [GridPos(2, 0), GridPos(8, 0), GridPos(6, 5), GridPos(14, 6)],
  startGold: 300,
  carrotHp: 20,
  hpScale: 1,
  seed: 7,
  waves:
      waves ??
      [
        const WaveDef([
          SpawnGroup(EnemyKind.slime, 3, gap: 0.2, lane: 0),
          SpawnGroup(EnemyKind.runner, 3, gap: 0.2, lane: 1),
        ]),
      ],
);

void main() {
  setUp(initTestEnvironment);

  test('分岔关卡按小队分流，敌人绑定各自路线', () {
    final engine = DefenseEngine(level: branchedLevel());
    expect(engine.tracks.length, 2);
    engine.startNextWave();
    advance(engine, 1);

    final routes = engine.enemies.map((enemy) => enemy.route).toSet();
    expect(routes, containsAll(<int>[0, 1]));
    for (final enemy in engine.enemies) {
      expect(enemy.track, same(engine.tracks[enemy.route]));
      expect(enemy.routeLength, engine.tracks[enemy.route].length);
      expect(enemy.track.distanceTo(enemy.position), lessThan(12));
    }
    engine.dispose();
  });

  test('未指定路线的敌人会在可行路线间交替', () {
    final level = branchedLevel(
      waves: const [
        WaveDef([SpawnGroup(EnemyKind.slime, 4, gap: 0.2)]),
      ],
    );
    final engine = DefenseEngine(level: level);
    engine.startNextWave();
    advance(engine, 1);

    final routes = engine.enemies.map((enemy) => enemy.route).toSet();
    expect(routes, containsAll(<int>[0, 1]));
    engine.dispose();
  });

  test('地面敌人越过传送门入口后瞬移到前方出口', () {
    final level = LevelDef(
      id: 78,
      name: '传送门测试',
      subtitle: '测试',
      theme: LevelTheme.night,
      path: const [GridPos(-1.2, 4), GridPos(5, 4), GridPos(10, 4), GridPos(15, 4)],
      slots: const [GridPos(2, 2), GridPos(8, 2)],
      startGold: 300,
      carrotHp: 20,
      hpScale: 1,
      seed: 8,
      portals: const [Portal(GridPos(5, 4), GridPos(10, 4))],
      waves: const [
        WaveDef([SpawnGroup(EnemyKind.slime, 1, gap: 1)]),
      ],
    );
    final engine = DefenseEngine(level: level);
    engine.startNextWave();
    // 先推进到入口前，再逐帧记录最大位移，确认发生了瞬移。
    advance(engine, 2);
    final enemy = engine.enemies.single;
    var maxStep = 0.0;
    var sawPortalEffect = false;
    for (var i = 0; i < 600 && !engine.isFinished; i++) {
      final before = enemy.distance;
      engine.update(1 / 60);
      maxStep = maxStep > enemy.distance - before ? maxStep : enemy.distance - before;
      sawPortalEffect |= engine.effects.any((effect) => effect.kind == EffectKind.portal);
    }
    expect(maxStep, greaterThan(100));
    expect(sawPortalEffect, isTrue);
    expect(enemy.distance, greaterThan(engine.track.length * 0.6));
    engine.dispose();
  });

  test('飞行敌人不经过传送门', () {
    final level = LevelDef(
      id: 79,
      name: '蝠妖传送测试',
      subtitle: '测试',
      theme: LevelTheme.night,
      path: const [GridPos(-1.2, 4), GridPos(5, 4), GridPos(10, 4), GridPos(15, 4)],
      slots: const [GridPos(2, 2)],
      startGold: 300,
      carrotHp: 20,
      hpScale: 1,
      seed: 9,
      portals: const [Portal(GridPos(5, 4), GridPos(10, 4))],
      waves: const [
        WaveDef([SpawnGroup(EnemyKind.flyer, 1, gap: 1)]),
      ],
    );
    final engine = DefenseEngine(level: level);
    engine.startNextWave();
    advance(engine, 6);
    expect(engine.effects.any((effect) => effect.kind == EffectKind.portal), isFalse);
    engine.dispose();
  });

  test('第 12 关包含分岔与传送门，建造点避开两条路线', () {
    final level = kLevels.last;
    expect(level.name, '双径幻阵');
    expect(level.hasBranch, isTrue);
    expect(level.portals, isNotEmpty);
    for (final route in level.routes) {
      final track = PathTrack([for (final point in route) point.design]);
      expect(track.length, greaterThan(900));
      for (final slot in level.slots) {
        expect(
          track.distanceTo(slot.design),
          greaterThanOrEqualTo(55),
          reason: '建造点 ${slot.col},${slot.row} 与路线过近',
        );
      }
    }
    expect(level.routes[1].first.col, level.path.first.col);
    expect(level.routes[1].last.col, level.path.last.col);
    expect(level.routes[1].last.row, level.path.last.row);
    final engine = DefenseEngine(level: level);
    expect(engine.tracks.length, 2);
    engine.dispose();
  });

  test('分岔与传送门关卡可正常渲染', () {
    final engine = DefenseEngine(level: kLevels.last);
    engine.startNextWave();
    advance(engine, 2);
    final paused = ValueNotifier<bool>(false);
    final speed = ValueNotifier<double>(1);
    final board = BoardComponent(
      engine: engine,
      logicRate: LogicRate.hz60,
      pausedNotifier: paused,
      speed: speed,
    )..size = Vector2(1280, 720);

    final recorder = ui.PictureRecorder();
    board.render(Canvas(recorder));
    recorder.endRecording().dispose();
    expect(engine.enemies.any((enemy) => enemy.route == 0), isTrue);
    expect(engine.tracks.length, 2);

    board.onRemove();
    engine.dispose();
    paused.dispose();
    speed.dispose();
  });

  test('每日挑战同一天种子与波次一致，换日则不同', () {
    final a = dailyLevel(DateTime(2026, 11, 8));
    final b = dailyLevel(DateTime(2026, 11, 8));
    final c = dailyLevel(DateTime(2026, 11, 9));

    expect(a.seed, dailySeed(DateTime(2026, 11, 8)));
    expect(a.daily, isTrue);
    expect(a.seed, b.seed);
    expect(a.waves.length, kDailyWaves);
    expect(c.seed, isNot(a.seed));
    for (final wave in a.waves) {
      expect(wave.totalEnemies, greaterThan(0));
      for (final group in wave.groups) {
        expect(group.gap, greaterThan(0));
        expect(group.delay, greaterThanOrEqualTo(0));
      }
    }
    expect(dailyKey(DateTime(2026, 1, 2)), '2026-01-02');
  });

  test('每日成绩只保留最佳纪录并限制天数', () async {
    final storage = await StorageService.instance;
    await storage.recordDaily(
      '2026-11-08',
      const EndlessRecord(waves: 5, kills: 20, gold: 300, date: '2026-11-08'),
    );
    await storage.recordDaily(
      '2026-11-08',
      const EndlessRecord(waves: 3, kills: 99, gold: 999, date: '2026-11-08'),
    );
    expect(storage.dailyRecords['2026-11-08']!.waves, 5);
    await storage.recordDaily(
      '2026-11-08',
      const EndlessRecord(waves: 9, kills: 40, gold: 700, date: '2026-11-08'),
    );
    expect(storage.dailyRecords['2026-11-08']!.waves, 9);

    for (var day = 1; day <= 16; day++) {
      final key = dailyKey(DateTime(2026, 10, day));
      await storage.recordDaily(key, EndlessRecord(waves: day, kills: day, gold: day, date: key));
    }
    expect(storage.dailyRecords.length, lessThanOrEqualTo(14));
    expect(storage.dailyRecords.containsKey('2026-11-08'), isTrue);
  });
}
