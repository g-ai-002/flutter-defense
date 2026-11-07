import 'package:carrot_defense/game/daily.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/engine/path_track.dart';
import 'package:carrot_defense/game/engine/route_plan.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:carrot_defense/theme/level_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// 主路走上侧、支路走下侧，汇合于萝卜的测试关卡。
LevelDef twoLaneLevel({List<Portal> portals = const [], List<WaveDef>? waves}) => LevelDef(
  id: 88,
  name: '双路测试',
  subtitle: '测试',
  theme: LevelTheme.meadow,
  path: const [GridPos(-1.2, 4), GridPos(4, 4), GridPos(4, 1), GridPos(15, 1)],
  branch: const [GridPos(-1.2, 4), GridPos(4, 4), GridPos(4, 7), GridPos(15, 7)],
  slots: const [GridPos(2, 2), GridPos(8, 2), GridPos(8, 5)],
  startGold: 300,
  carrotHp: 20,
  hpScale: 1,
  seed: 88,
  portals: portals,
  waves:
      waves ??
      [
        const WaveDef([
          SpawnGroup(EnemyKind.slime, 1, gap: 0.4, lane: 0),
          SpawnGroup(EnemyKind.slime, 1, gap: 0.4, delay: 0.4, lane: 1),
        ]),
      ],
);

void main() {
  setUp(initTestEnvironment);

  group('路线规划', () {
    test('传送门跳跃按路线分桶，只作用于落点所在的支路', () {
      final plan = RoutePlan(twoLaneLevel(portals: const [Portal(GridPos(8, 7), GridPos(12, 7))]));
      expect(plan.tracks.length, 2);
      expect(plan.main, same(plan.tracks.first));
      expect(plan.jumpsOn(0), isEmpty);
      expect(plan.jumpsOn(1), hasLength(1));
      final jump = plan.jumpsOn(1).single;
      expect(jump.exit, greaterThan(jump.entry));
      expect(jump.at, GridPos(8, 7).design);
      expect(jump.away, GridPos(12, 7).design);
    });

    test('没有传送门时每条路线的跳跃表都为空', () {
      final plan = RoutePlan(twoLaneLevel());
      expect(plan.jumpsOn(0), isEmpty);
      expect(plan.jumpsOn(1), isEmpty);
    });

    test('支路传送门只瞬移支路敌人，主路敌人匀速前进', () {
      final engine = DefenseEngine(
        level: twoLaneLevel(portals: const [Portal(GridPos(8, 7), GridPos(12, 7))]),
      );
      engine.startNextWave();
      advance(engine, 1);
      final main = engine.enemies.firstWhere((enemy) => enemy.route == 0);
      final branch = engine.enemies.firstWhere((enemy) => enemy.route == 1);
      var mainStep = 0.0;
      var branchStep = 0.0;
      for (var i = 0; i < 60 * 20 && !engine.isFinished; i++) {
        final mainBefore = main.distance;
        final branchBefore = branch.distance;
        engine.update(1 / 60);
        mainStep = mainStep > main.distance - mainBefore ? mainStep : main.distance - mainBefore;
        branchStep = branchStep > branch.distance - branchBefore
            ? branchStep
            : branch.distance - branchBefore;
      }
      expect(branchStep, greaterThan(100), reason: '支路敌人应越过传送门');
      expect(mainStep, lessThan(100), reason: '主路没有传送门，不应瞬移');
      engine.dispose();
    });

    test('分流规则：飞行固定主航线，指定路线取模，未指定按出怪序号交替', () {
      final plan = RoutePlan(twoLaneLevel());
      expect(plan.laneFor(requested: 0, id: 3, flying: false), 0);
      expect(plan.laneFor(requested: 1, id: 4, flying: false), 1);
      expect(plan.laneFor(requested: 5, id: 1, flying: false), 1);
      expect(plan.laneFor(requested: -1, id: 1, flying: false), 1);
      expect(plan.laneFor(requested: -1, id: 2, flying: false), 0);
      expect(plan.laneFor(requested: -1, id: 1, flying: true), 0);

      final single = RoutePlan(
        straightLevel(
          waves: [
            WaveDef([spawn(EnemyKind.slime, 1)], reward: 0),
          ],
        ),
      );
      expect(single.laneFor(requested: 3, id: 1, flying: false), 0);
      expect(single.laneFor(requested: -1, id: 5, flying: false), 0);
    });

    test('路线长度按地面与飞行分别取土路弧长和直线距离', () {
      final plan = RoutePlan(twoLaneLevel());
      for (var route = 0; route < plan.tracks.length; route++) {
        final track = plan.tracks[route];
        expect(plan.routeLength(route, flying: false), track.length);
        expect(plan.routeLength(route, flying: true), track.airLength);
      }
    });

    test('近路判定覆盖每条土路', () {
      final plan = RoutePlan(twoLaneLevel());
      expect(plan.nearRoute(GridPos(8, 7).design, 20), isTrue);
      expect(plan.nearRoute(GridPos(8, 1).design, 20), isTrue);
      expect(plan.nearRoute(GridPos(8, 4).design, 20), isFalse);
    });
  });

  group('折线路径', () {
    test('缓存 Path 覆盖全部顶点且重复访问复用同一实例', () {
      final track = PathTrack([const Offset(0, 0), const Offset(120, 0), const Offset(120, 80)]);
      final path = track.path;
      expect(track.path, same(path));
      final bounds = path.getBounds().inflate(0.01);
      for (final point in track.points) {
        expect(bounds.contains(point), isTrue, reason: '$point 应落在 Path 包围盒内');
      }
    });

    test('polylinePath 首顶点为起点且段数与顶点数一致', () {
      final path = polylinePath(const [Offset(10, 10), Offset(40, 10), Offset(40, 60)]);
      final metrics = path.computeMetrics().toList();
      expect(metrics, hasLength(1), reason: '一条折线只产生一个轮廓');
      expect(metrics.single.length, closeTo(80, 0.001));
    });
  });

  group('每日挑战分流', () {
    test('同一天的分流与出怪完全一致，换日不同', () {
      final a = dailyLevel(DateTime(2026, 11, 8));
      final b = dailyLevel(DateTime(2026, 11, 8));
      final c = dailyLevel(DateTime(2026, 11, 9));
      expect(a.seed, b.seed);
      expect(c.seed, isNot(a.seed));
      for (var i = 0; i < a.waves.length; i++) {
        final left = a.waves[i].groups;
        final right = b.waves[i].groups;
        expect(left.length, right.length);
        for (var g = 0; g < left.length; g++) {
          expect(left[g].kind, right[g].kind);
          expect(left[g].count, right[g].count);
          expect(left[g].lane, right[g].lane);
        }
      }
      // 支路只出现在自身带分岔的母关卡，且小队路线不会超出可行路线数。
      for (final wave in a.waves) {
        for (final group in wave.groups) {
          expect(group.lane, lessThan(a.routes.length));
        }
      }
    });

    test('每日关卡沿用母关卡的路线、传送门与毒雾配置', () {
      for (var day = 1; day <= 28; day++) {
        final level = dailyLevel(DateTime(2026, 2, day));
        final base = kLevels.firstWhere((item) => identical(item.path, level.path));
        expect(identical(level.branch, base.branch), isTrue);
        expect(identical(level.portals, base.portals), isTrue);
        expect(identical(level.fog, base.fog), isTrue);
        expect(level.portalCells.length, level.portals.length * 2);
      }
    });
  });
}
