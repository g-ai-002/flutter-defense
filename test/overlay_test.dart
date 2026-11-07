import 'package:carrot_defense/game/daily.dart';
import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:carrot_defense/pages/widgets/game_overlays.dart';
import 'package:carrot_defense/providers/settings_provider.dart';
import 'package:carrot_defense/services/storage_service.dart';
import 'package:carrot_defense/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_utils.dart';

Widget _host(Widget child, StorageService storage) {
  return ChangeNotifierProvider(
    create: (_) => SettingsProvider(storage),
    child: MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(initTestEnvironment);

  testWidgets('暂停面板在手机横屏下可完整滚动', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(
      _host(
        PauseOverlay(
          logicLabel: '60 Hz 均衡',
          speed: 2,
          onResume: () {},
          onRestart: () {},
          onExit: () {},
        ),
        storage,
      ),
    );
    await tester.pump();
    expect(find.text('游戏暂停'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('胜利结算在小屏可滚动并展示星级与统计', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    final engine = DefenseEngine(level: kLevels.first);
    await tester.pumpWidget(
      _host(
        GameResultOverlay(
          level: kLevels.first,
          engine: engine,
          victory: true,
          stars: 3,
          hasNext: true,
          onRetry: () {},
          onNext: () {},
          onExit: () {},
        ),
        storage,
      ),
    );
    await tester.pump();
    expect(find.text('关卡完成！'), findsOneWidget);
    expect(find.text('下一关'), findsOneWidget);
    expect(find.text('击杀'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('每日挑战结算展示当天最佳与再来一局', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    final level = dailyLevel(DateTime(2026, 11, 8));
    final engine = DefenseEngine(level: level)..startNextWave();
    await tester.pumpWidget(
      _host(
        GameResultOverlay(
          level: level,
          engine: engine,
          victory: false,
          stars: 0,
          hasNext: false,
          daily: true,
          bestWaves: 4,
          newRecord: true,
          exitLabel: '返回首页',
          onRetry: () {},
          onNext: () {},
          onExit: () {},
        ),
        storage,
      ),
    );
    await tester.pump();
    expect(find.textContaining('今日挑战'), findsOneWidget);
    expect(find.textContaining('今日新纪录'), findsOneWidget);
    expect(find.text('再来一局'), findsOneWidget);
    expect(find.text('返回首页'), findsOneWidget);
    expect(tester.takeException(), isNull);
    engine.dispose();
  });

  testWidgets('失败结算展示建议与重试入口', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    final engine = DefenseEngine(level: kLevels.first);
    await tester.pumpWidget(
      _host(
        GameResultOverlay(
          level: kLevels.first,
          engine: engine,
          victory: false,
          stars: 0,
          hasNext: false,
          onRetry: () {},
          onNext: () {},
          onExit: () {},
        ),
        storage,
      ),
    );
    await tester.pump();
    expect(find.text('萝卜被抢走了'), findsOneWidget);
    expect(find.text('再试一次'), findsOneWidget);
    expect(find.text('返回选关'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
