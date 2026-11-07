import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/engine/defense_engine.dart';
import '../game/logic_rate.dart';
import 'board_component.dart';

/// Flame 游戏入口：只挂一个战场组件，战斗逻辑由其按固定步长推进。
class DefenseGame extends FlameGame {
  DefenseGame({required this.engine, required this.logicRate});

  final DefenseEngine engine;
  final LogicRate logicRate;
  final ValueNotifier<bool> pausedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> speed = ValueNotifier<double>(1);
  BoardComponent? _board;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    final board = BoardComponent(
      engine: engine,
      logicRate: logicRate,
      pausedNotifier: pausedNotifier,
      speed: speed,
    )..size = size.clone();
    _board = board;
    await add(board);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _board?.size = size.clone();
  }

  void disposeNotifiers() {
    pausedNotifier.dispose();
    speed.dispose();
  }
}
