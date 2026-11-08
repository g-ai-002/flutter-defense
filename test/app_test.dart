import 'package:carrot_defense/app.dart';
import 'package:carrot_defense/flame/board_layout.dart';
import 'package:carrot_defense/flame/defense_game.dart';
import 'package:carrot_defense/models/endless.dart';
import 'package:carrot_defense/pages/widgets/game_hud.dart';
import 'package:carrot_defense/pages/widgets/hud_bottom_dock.dart';
import 'package:carrot_defense/pages/widgets/hud_chrome.dart';
import 'package:carrot_defense/pages/widgets/hud_info_bars.dart';
import 'package:carrot_defense/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  setUp(initTestEnvironment);

  testWidgets('首页在桌面尺寸下展示主视觉与入口', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();

    expect(find.text('萝卜保卫战'), findsOneWidget);
    expect(find.text('守住最后一根萝卜'), findsOneWidget);
    expect(find.text('开始冒险'), findsOneWidget);
    expect(find.text('关卡选择'), findsOneWidget);
    expect(find.text('玩法说明'), findsOneWidget);
    expect(find.text('无尽挑战'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('无尽挑战入口可直接进入对局', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();

    await tester.tap(find.text('无尽挑战'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('开始第 1 波'), findsOneWidget);
    expect(find.text('第 1 波'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('每日挑战入口使用日期种子进入对局', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();

    await tester.tap(find.text('每日挑战'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('开始第 1 波'), findsOneWidget);
    expect(find.text('第 1 波'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('首页可查看无尽排行榜', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await storage.addEndlessRecord(
      const EndlessRecord(waves: 9, kills: 120, gold: 900, date: '2026-11-08'),
    );
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    expect(find.textContaining('最佳第 9 波'), findsOneWidget);

    await tester.tap(find.byTooltip('无尽排行榜'));
    await tester.pumpAndSettle();
    expect(find.text('无尽排行榜'), findsOneWidget);
    expect(find.textContaining('第 9 波'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('手机横屏尺寸下首页不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 450));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('开始冒险'), findsOneWidget);
  });

  testWidgets('窄屏竖屏首页与对局均不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    expect(tester.takeException(), isNull, reason: '首页竖屏');
    await tester.tap(find.text('开始冒险'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull, reason: '对局竖屏');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('关卡选择页展示全部关卡与解锁状态', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    await tester.tap(find.text('关卡选择'));
    await tester.pumpAndSettle();

    expect(find.text('选择关卡'), findsWidgets);
    expect(find.text('青草平原'), findsOneWidget);
    expect(find.text('魔王城塞'), findsOneWidget);
    expect(find.text('毒沼秘境'), findsOneWidget);
    expect(find.text('通关上一关解锁'), findsNWidgets(11));
    expect(tester.takeException(), isNull);
  });

  testWidgets('小屏横屏对局页不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    await tester.tap(find.text('开始冒险'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('开始第 1 波'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('点击空地可建造并升级防御塔', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    await tester.tap(find.text('开始冒险'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 第 1 关 1 号空地位于设计坐标 (288, 232)，按战场布局换算到 1200×700 视口。
    final layout = BoardLayout.resolve(const Size(1200, 700));
    await tester.tapAt(layout.origin + const Offset(288, 232) * layout.scale);
    await tester.pump();
    expect(find.text('空地建造'), findsOneWidget);
    await tester.tap(find.text('弓弩'));
    await tester.pump();
    expect(find.text('弓弩塔 · Lv.1'), findsOneWidget);
    expect(find.text('190'), findsOneWidget);

    await tester.tap(find.text('升级 100'));
    await tester.pump();
    expect(find.text('弓弩塔 · Lv.2'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('对局页展示悬浮 HUD 并可暂停', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    await tester.tap(find.text('开始冒险'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('1/6 波'), findsOneWidget);
    expect(find.text('开始第 1 波'), findsOneWidget);
    expect(find.text('弓弩塔'), findsNothing);

    await tester.tap(find.byTooltip('暂停'));
    await tester.pump();
    expect(find.text('游戏暂停'), findsOneWidget);
    await tester.tap(find.text('继续游戏'));
    await tester.pump();
    expect(find.text('游戏暂停'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('信息簇贴窗口上角，控制条贴住屏幕最下方', (tester) async {
    const view = Size(1200, 700);
    await tester.binding.setSurfaceSize(view);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    await tester.tap(find.text('开始冒险'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final grid = GameHud.gridRectFor(view);
    final status = tester.getRect(find.byType(HudStatusPanel));
    final resource = tester.getRect(find.byType(HudResourcePanel));
    final dock = tester.getRect(find.byType(HudBottomDock));

    expect(status.bottom, lessThanOrEqualTo(grid.top), reason: '关卡信息应在网格上方');
    expect(resource.bottom, lessThanOrEqualTo(grid.top), reason: '资源信息应在网格上方');
    expect(status.left, closeTo(8, 1), reason: '左侧信息贴在窗口左上角');
    expect(status.top, closeTo(6, 1), reason: '信息簇应贴住窗口上边缘');
    expect(resource.right, closeTo(view.width - 8, 1), reason: '右侧信息贴在窗口右上角');
    expect(resource.left, greaterThan(status.right), reason: '左右两组信息不应重叠');
    expect(dock.top, greaterThanOrEqualTo(grid.bottom - 8), reason: '控制条应在网格下方');
    expect(dock.left, lessThan(grid.left), reason: '控制条横向铺满，不被网格宽度限制');
    expect(dock.bottom, closeTo(view.height, 0.5), reason: '控制条应贴住屏幕最下方');
    expect(dock.left, closeTo(8, 0.5), reason: '控制条与窗口左右边缘保持间距');

    // 信息簇由彼此分离的小卡片组成，不再套一层压在战场上的大外框。
    final back = tester.getRect(find.byType(HudIconChip));
    final title = tester.getRect(find.byType(HudTitleChip));
    final hp = tester.getRect(find.byType(HudInfoPill).first);
    expect(title.left, greaterThan(back.right), reason: '返回按钮与关卡卡片应分离');
    expect(hp.left, greaterThan(title.right), reason: '关卡卡片与血量卡片应分离');
    expect(status.height, lessThanOrEqualTo(40), reason: '信息簇不应再有大外框撑高');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('退出对局后不残留游戏实例与后台任务', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await StorageService.instance;
    await tester.pumpWidget(CarrotDefenseApp(storage: storage));
    await tester.pump();
    await tester.tap(find.text('无尽挑战'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(DefenseGame.activeGames, 1);

    await tester.tap(find.byTooltip('返回'));
    await tester.pump();
    await tester.tap(find.text('返回首页'));
    await tester.pumpAndSettle();

    expect(find.text('开始冒险'), findsOneWidget);
    expect(DefenseGame.activeGames, 0, reason: '对局页关闭后不应残留战场实例');
    expect(tester.takeException(), isNull);
  });
}
