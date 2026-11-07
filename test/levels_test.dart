import 'package:carrot_defense/game/engine/path_track.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  setUpAll(initTestEnvironment);

  test('关卡编号连续、波次完整、建造点不压路', () {
    expect(kLevels.length, 10);
    for (var index = 0; index < kLevels.length; index++) {
      final level = kLevels[index];
      expect(level.id, index + 1, reason: '关卡编号必须连续');
      expect(level.path.length, greaterThanOrEqualTo(2));
      expect(level.path.first.col, lessThan(0), reason: '入口应在屏幕外');
      expect(level.slots, isNotEmpty);
      expect(level.slots.toSet().length, level.slots.length);
      expect(level.waves, isNotEmpty);
      expect(level.startGold, greaterThan(0));
      expect(level.carrotHp, greaterThan(0));

      final track = PathTrack([for (final point in level.path) point.design]);
      expect(track.length, greaterThan(900));
      for (final slot in level.slots) {
        final distance = track.distanceTo(slot.design);
        expect(
          distance,
          greaterThanOrEqualTo(55),
          reason: '第 ${level.id} 关的建造点与路径过近: ${slot.col},${slot.row}',
        );
        expect(slot.design.dx, inInclusiveRange(0, 1280));
        expect(slot.design.dy, inInclusiveRange(0, 720));
      }

      for (final wave in level.waves) {
        expect(wave.totalEnemies, greaterThan(0));
        for (final group in wave.groups) {
          expect(group.count, greaterThan(0));
          expect(group.gap, greaterThan(0));
          expect(group.delay, greaterThanOrEqualTo(0));
        }
      }
    }
  });

  test('地图名称与地貌不重复堆叠', () {
    final names = kLevels.map((level) => level.name).toSet();
    expect(names.length, kLevels.length);
    final themes = kLevels.map((level) => level.theme).toSet();
    expect(themes.length, greaterThanOrEqualTo(4));
  });

  test('后期关卡强度递增', () {
    for (var i = 1; i < kLevels.length; i++) {
      expect(kLevels[i].hpScale, greaterThan(kLevels[i - 1].hpScale));
      expect(
        kLevels[i].waves.last.totalEnemies,
        greaterThanOrEqualTo(1),
      );
    }
  });
}

