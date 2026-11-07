import 'package:carrot_defense/game/engine/entities.dart';
import 'package:carrot_defense/game/engine/wave_schedule.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('波次时间表', () {
    test('多组敌人按时间展开并稳定排序', () {
      final schedule = WaveSchedule(
        const WaveDef([
          SpawnGroup(EnemyKind.slime, 3, gap: 0.5, delay: 0.2),
          SpawnGroup(EnemyKind.runner, 2, gap: 1, delay: 0),
        ]),
        hpScale: 1.5,
      );

      expect(schedule.total, 5);
      expect(schedule.pending, 5);
      expect(schedule.done, isFalse);

      final events = <SpawnEvent>[];
      for (var i = 0; i < 10; i++) {
        final event = schedule.nextAt(10);
        if (event == null) break;
        events.add(event);
      }

      expect(events.map((e) => e.time), [0, 0.2, 0.7, 1.0, 1.2]);
      expect(events.first.kind, EnemyKind.runner);
      expect(events.last.kind, EnemyKind.slime);
      expect(events.every((e) => e.hpScale == 1.5), isTrue);
      expect(schedule.pending, 0);
      expect(schedule.done, isTrue);
      expect(schedule.nextAt(10), isNull);
    });

    test('未到时间不消费事件，边界时间可取出', () {
      final schedule = WaveSchedule(
        const WaveDef([SpawnGroup(EnemyKind.slime, 1, delay: 2)]),
        hpScale: 1,
      );

      expect(schedule.nextAt(1.99), isNull);
      expect(schedule.pending, 1);
      expect(schedule.nextAt(2), isNotNull);
      expect(schedule.pending, 0);
      expect(schedule.done, isTrue);
    });

    test('空波次立即完成', () {
      final schedule = WaveSchedule(
        const WaveDef([SpawnGroup(EnemyKind.slime, 0)]),
        hpScale: 1,
      );
      expect(schedule.total, 0);
      expect(schedule.done, isTrue);
      expect(schedule.nextAt(0), isNull);
    });
  });

  group('特效与飘字工厂', () {
    test('闪电特效以首段为锚点并保留折线', () {
      const points = [Offset(10, 20), Offset(40, 50)];
      final effect = Effect.lightning(points);
      expect(effect.kind, EffectKind.lightning);
      expect(effect.position, const Offset(10, 20));
      expect(effect.points, points);
      expect(effect.duration, 0.22);
    });

    test('金币与漏怪飘字使用统一文案与颜色', () {
      final gold = Floater.gold(12, Offset.zero);
      expect(gold.text, '+12');
      expect(gold.big, isFalse);

      final damage = Floater.damage(3, Offset.zero);
      expect(damage.text, '-3');
      expect(damage.big, isTrue);
      expect(damage.color, const Color(0xFFFF7A6B));
    });
  });
}
