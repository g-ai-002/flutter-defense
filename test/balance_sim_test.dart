import 'package:carrot_defense/game/balance.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/engine/entities.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// 自动建造顺序：先廉价箭塔铺场，再补群伤、减速与连锁。
const List<TowerKind> _buildOrder = [
  TowerKind.arrow,
  TowerKind.arrow,
  TowerKind.cannon,
  TowerKind.frost,
  TowerKind.arrow,
  TowerKind.cannon,
  TowerKind.lightning,
  TowerKind.arrow,
  TowerKind.frost,
  TowerKind.lightning,
  TowerKind.cannon,
  TowerKind.arrow,
  TowerKind.lightning,
  TowerKind.cannon,
];

class GreedyBot {
  GreedyBot(this.engine) {
    _slots = List.generate(engine.slotPositions.length, (index) => index)
      ..sort(
        (a, b) => _coverage(engine.slotPositions[b]).compareTo(_coverage(engine.slotPositions[a])),
      );
  }

  final DefenseEngine engine;
  late final List<int> _slots;
  int _built = 0;

  int _coverage(Offset position) {
    var count = 0;
    for (var distance = 0.0; distance < engine.track.length; distance += 16) {
      if ((engine.track.pointAt(distance) - position).distance <= 160) {
        count++;
      }
    }
    return count;
  }

  int? _bestEmptySlot() {
    for (final slot in _slots) {
      if (engine.towerAt(slot) == null) return slot;
    }
    return null;
  }

  void spend() {
    while (_built < _buildOrder.length) {
      final kind = _buildOrder[_built];
      final slot = _bestEmptySlot();
      if (slot == null) break;
      if (engine.gold < towerStats(kind, 1).cost) break;
      if (!engine.build(slot, kind)) break;
      _built++;
    }
    var upgraded = true;
    while (upgraded) {
      upgraded = false;
      final candidates =
          engine.activeTowers
              .where((tower) => tower.canUpgrade && engine.gold >= tower.upgradeCost)
              .toList()
            ..sort(
              (a, b) =>
                  _coverage(engine.slotPositions[b.slotIndex])
                      .compareTo(_coverage(engine.slotPositions[a.slotIndex])),
            );
      if (candidates.isEmpty) break;
      if (engine.upgrade(candidates.first.slotIndex)) upgraded = true;
    }
  }
}

class SimResult {
  SimResult(this.level, this.engine, this.seconds);

  final LevelDef level;
  final DefenseEngine engine;
  final double seconds;

  bool get won => engine.status == GameStatus.victory;

  @override
  String toString() =>
      '${level.id}.${level.name}: '
      '${won ? '胜利' : '失败'} ${engine.stars}星, '
      '萝卜 ${engine.carrotHp}/${engine.carrotMaxHp}, '
      '击杀 ${engine.kills}, 漏怪 ${engine.leaked}, '
      '金币 ${engine.goldEarned}, 塔 ${engine.activeTowers.length}, '
      '耗时 ${seconds.round()}s';
}

SimResult simulate(LevelDef level, {double limit = 2400}) {
  final engine = DefenseEngine(level: level);
  final bot = GreedyBot(engine);
  var seconds = 0.0;
  const step = 1 / 30;
  while (!engine.isFinished && seconds < limit) {
    if (engine.status == GameStatus.preparing) {
      bot.spend();
      engine.startNextWave();
    }
    engine.update(step);
    seconds += step;
  }
  return SimResult(level, engine, seconds);
}

void main() {
  setUpAll(initTestEnvironment);

  test('每关都能用常规建造策略通关', () {
    final results = <SimResult>[];
    for (final level in kLevels) {
      results.add(simulate(level));
    }
    for (final result in results) {
      // ignore: avoid_print
      print(result);
    }
    final failed = results.where((result) => !result.won).toList();
    expect(failed, isEmpty, reason: failed.map((result) => result.toString()).join('\n'));
  });

  test('自动策略下的星级应保持在合理区间', () {
    final results = [for (final level in kLevels) simulate(level)];
    final stars = results.fold(0, (sum, result) => sum + result.engine.stars);
    expect(stars, greaterThanOrEqualTo(15));
    expect(stars, lessThanOrEqualTo(kLevels.length * 3));
    // 首关必须容易满星，作为新手引导。
    expect(results.first.engine.stars, 3);
  });
}
