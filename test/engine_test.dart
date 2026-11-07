import 'package:carrot_defense/game/balance.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/engine/entities.dart';
import 'package:carrot_defense/game/logic_rate.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  setUpAll(initTestEnvironment);

  group('经济与建造', () {
    test('建塔扣金币，升级提升等级，出售按比例返还', () {
      final engine = DefenseEngine(level: kLevels.first);
      final startGold = engine.gold;
      expect(engine.canBuild(TowerKind.arrow, 0), isTrue);
      expect(engine.build(0, TowerKind.arrow), isTrue);
      expect(engine.gold, startGold - towerStats(TowerKind.arrow, 1).cost);
      final tower = engine.towerAt(0)!;
      expect(tower.level, 1);
      expect(tower.totalSpent, towerStats(TowerKind.arrow, 1).cost);

      final goldBeforeUpgrade = engine.gold;
      expect(engine.upgrade(0), isTrue);
      expect(engine.gold, goldBeforeUpgrade - towerStats(TowerKind.arrow, 2).cost);
      expect(tower.level, 2);

      final refund = tower.sellValue;
      expect(engine.sell(0), isTrue);
      expect(engine.towerAt(0), isNull);
      expect(engine.gold, greaterThan(0));
      expect(refund, (tower.totalSpent * kSellRefundRatio).floor());
    });

    test('金币不足时无法建造，已占用位置不能重复建造', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 70,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1)]),
          ],
        ),
      );
      expect(engine.build(0, TowerKind.arrow), isTrue);
      expect(engine.gold, 0);
      expect(engine.canBuild(TowerKind.cannon, 1), isFalse);
      expect(engine.build(1, TowerKind.cannon), isFalse);
      expect(engine.canBuild(TowerKind.arrow, 0), isFalse);
      expect(engine.build(0, TowerKind.arrow), isFalse);
    });
  });

  group('路径与漏怪', () {
    test('敌人走到终点扣血，全部波次结束后仍可胜利', () {
      final engine = DefenseEngine(
        level: straightLevel(
          carrotHp: 5,
          startGold: 0,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      advance(engine, 30);
      expect(engine.leaked, 1);
      expect(engine.carrotHp, 4);
      expect(engine.status, GameStatus.victory);
    });

    test('萝卜血量归零立即失败', () {
      final engine = DefenseEngine(
        level: straightLevel(
          carrotHp: 1,
          startGold: 0,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1)], reward: 0),
            WaveDef([spawn(EnemyKind.slime, 1)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      advance(engine, 30);
      expect(engine.status, GameStatus.defeat);
      expect(engine.carrotHp, 0);
    });

    test('击杀敌人获得赏金并清理波次', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 400,
          waves: [
            WaveDef([spawn(EnemyKind.slime, 3, gap: 0.4)], reward: 25),
          ],
        ),
      );
      engine.build(0, TowerKind.arrow);
      engine.build(1, TowerKind.arrow);
      engine.build(2, TowerKind.arrow);
      final afterBuild = engine.gold;
      engine.startNextWave();
      advance(engine, 40);
      expect(engine.status, GameStatus.victory);
      expect(engine.kills, 3);
      expect(engine.leaked, 0);
      expect(engine.gold, greaterThan(afterBuild));
    });
  });

  group('防御塔特性', () {
    test('冰霜塔命中后敌人进入减速状态', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 300,
          hpScale: 3,
          slots: const [GridPos(6, 3)],
          waves: [
            WaveDef([spawn(EnemyKind.tank, 1)], reward: 0),
          ],
        ),
      );
      expect(engine.build(0, TowerKind.frost), isTrue);
      engine.startNextWave();
      var sawSlow = false;
      for (var i = 0; i < 60 * 40; i++) {
        engine.update(1 / 60);
        if (engine.enemies.any((enemy) => enemy.slowed)) {
          sawSlow = true;
          break;
        }
        if (engine.isFinished) break;
      }
      expect(sawSlow, isTrue);
    });

    test('雷电塔可以连锁命中多个目标', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 300,
          hpScale: 5,
          slots: const [GridPos(7, 3)],
          waves: [
            WaveDef([spawn(EnemyKind.tank, 4, gap: 0.35)], reward: 0),
          ],
        ),
      );
      expect(engine.build(0, TowerKind.lightning), isTrue);
      engine.startNextWave();
      var damagedMultiple = false;
      for (var i = 0; i < 60 * 20; i++) {
        engine.update(1 / 60);
        final damaged = engine.enemies.where((e) => e.hp < e.maxHp).length;
        if (damaged >= 2) {
          damagedMultiple = true;
          break;
        }
      }
      expect(damagedMultiple, isTrue);
    });

    test('火炮塔的范围伤害能同时打伤多个目标', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 300,
          hpScale: 6,
          slots: const [GridPos(7, 3)],
          waves: [
            WaveDef([spawn(EnemyKind.tank, 4, gap: 0.25)], reward: 0),
          ],
        ),
      );
      expect(engine.build(0, TowerKind.cannon), isTrue);
      engine.startNextWave();
      var damagedMultiple = false;
      for (var i = 0; i < 60 * 25; i++) {
        engine.update(1 / 60);
        final damaged = engine.enemies.where((e) => e.hp < e.maxHp).length;
        if (damaged >= 2) {
          damagedMultiple = true;
          break;
        }
      }
      expect(damagedMultiple, isTrue);
    });
  });

  group('逻辑刷新率与星级', () {
    test('固定步长按 30 / 60 / 120Hz 推进', () {
      for (final rate in LogicRate.values) {
        final clock = FixedStepClock(rate.step);
        var total = 0.0;
        var steps = 0;
        for (var i = 0; i < 60; i++) {
          steps += clock.advance(1 / 60, (span) => total += span);
        }
        expect(steps, closeTo(rate.hz, 2));
        expect(total, closeTo(1.0, 0.05));
      }
    });

    test('星级按剩余血量比例计算', () {
      expect(starRating(carrotHp: 20, carrotMaxHp: 20), 3);
      expect(starRating(carrotHp: 12, carrotMaxHp: 20), 2);
      expect(starRating(carrotHp: 10, carrotMaxHp: 20), 2);
      expect(starRating(carrotHp: 9, carrotMaxHp: 20), 1);
    });
  });
}
