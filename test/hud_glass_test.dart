import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/game/levels.dart';
import 'package:carrot_defense/pages/widgets/game_hud.dart';
import 'package:carrot_defense/pages/widgets/hud_bottom_dock.dart';
import 'package:carrot_defense/pages/widgets/hud_chrome.dart';
import 'package:carrot_defense/pages/widgets/hud_info_bars.dart';
import 'package:carrot_defense/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// 取任意主题下的悬浮层装饰，供透明度断言使用。
Future<BoxDecoration> _decoration(
  WidgetTester tester,
  ThemeData theme,
  BoxDecoration Function(BuildContext context) build,
) async {
  late BoxDecoration decoration;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          decoration = build(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return decoration;
}

void main() {
  setUp(initTestEnvironment);

  testWidgets('浅色与深色主题的悬浮层都是 50% 透明度', (tester) async {
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      final panel = await _decoration(tester, theme, (c) => hudPanelDecoration(c, radius: 16));
      final chip = await _decoration(tester, theme, (c) => hudChipDecoration(c));
      expect(panel.color!.a, closeTo(kHudGlassAlpha, 0.001));
      expect(chip.color!.a, closeTo(kHudGlassAlpha, 0.001));
    }
  });

  testWidgets('对局 HUD 的信息卡片与控制条以半透明表面悬浮', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final engine = DefenseEngine(level: kLevels.first);
    addTearDown(engine.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: GameHud(
            engine: engine,
            speed: 1,
            onSpeed: () {},
            onPause: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final dock = tester.widget<Container>(
      find.descendant(of: find.byType(HudBottomDock), matching: find.byType(Container)).first,
    );
    final pill = tester.widget<Container>(
      find.descendant(of: find.byType(HudInfoPill).first, matching: find.byType(Container)).first,
    );
    expect((dock.decoration! as BoxDecoration).color!.a, closeTo(kHudGlassAlpha, 0.001));
    expect((pill.decoration! as BoxDecoration).color!.a, closeTo(kHudGlassAlpha, 0.001));
    expect(find.byType(HudStatusPanel), findsOneWidget);
    expect(find.byType(HudResourcePanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
