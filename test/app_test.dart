import 'package:carrot_defense/app.dart';
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

  testWidgets('关卡选择页展示十个关卡与解锁状态', (tester) async {
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
    expect(find.text('通关上一关解锁'), findsNWidgets(9));
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

    // 第 1 关 1 号空地位于设计坐标 (288, 232)，换算到 1200×700 视口。
    await tester.tapAt(const Offset(343, 232));
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
}
