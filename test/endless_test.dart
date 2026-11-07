import 'package:carrot_defense/game/endless.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/engine/entities.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/endless.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:carrot_defense/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  setUpAll(initTestEnvironment);

  group('毒液塔', () {
    test('命中后持续掉血，中毒伤害无视护甲', () {
      final engine = DefenseEngine(
        level: straightLevel(
          startGold: 1000,
          waves: [
            WaveDef([spawn(EnemyKind.beetle, 1)], reward: 0),
          ],
        ),
      );
      engine.startNextWave();
      engine.update(0.05);
      final enemy = engine.enemies.single;
      enemy.distance = 320;
      engine.update(0.02);

      expect(engine.build(0, TowerKind.poison), isTrue);
      engine.update(0.02);
      expect(engine.projectiles, isNotEmpty);
      engine.update(0.6);
      expect(enemy.poisonTimer, greaterThan(0));
      expect(enemy.poisoned, isTrue);

      // 卖掉塔，排除后续弹道干扰，只观察中毒持续伤害。
      engine.sell(0);
      final before = enemy.hp;
      for (var i = 0; i < 30; i++) {
        engine.update(1 / 60);
      }
      final tickDamage = before - enemy.hp;
      expect(tickDamage, closeTo(9 * 0.5, 0.3));
      expect(tickDamage, greaterThan(9 * 0.5 * 0.62));
    });
  });

  group('无尽模式', () {
    test('波次随进度增强，每 15 波出现首领', () {
      expect(kEndlessLevel.endless, isTrue);
      expect(kEndlessLevel.waveCount, kEndlessWaveCount);
      final early = endlessWave(0);
      final late = endlessWave(59);
      expect(late.hpScale, greaterThan(early.hpScale));
      expect(late.totalEnemies, greaterThan(early.totalEnemies));
      expect(endlessWave(14).hasBoss, isTrue);
      expect(endlessWave(13).hasBoss, isFalse);
      expect(late.groups.length, greaterThanOrEqualTo(early.groups.length));
    });

    test('无尽关卡不会在波次表结束前胜利，已清理波次可统计', () {
      final engine = DefenseEngine(level: kEndlessLevel);
      expect(engine.endless, isTrue);
      expect(engine.clearedWaves, 0);
      engine.startNextWave();
      expect(engine.waveIndex, 1);
      expect(engine.status, GameStatus.battle);
      advance(engine, 2);
      expect(engine.status, GameStatus.battle);
      expect(engine.clearedWaves, 0);
    });
  });

  group('无尽排行榜', () {
    test('记录按波次排序并只保留前 10 条', () async {
      final storage = await StorageService.instance;
      for (var i = 1; i <= 12; i++) {
        await storage.addEndlessRecord(
          EndlessRecord(waves: i, kills: i * 2, gold: i * 10, date: '2026-11-08'),
        );
      }
      final records = storage.endlessRecords;
      expect(records.length, 10);
      expect(records.first.waves, 12);
      expect(records.last.waves, 3);
      expect(records.first.kills, 24);
    });

    test('称号随波数提升', () {
      expect(endlessRank(0), '见习守卫');
      expect(endlessRank(8), '可靠守卫');
      expect(endlessRank(60), '神话守卫');
    });
  });
}
