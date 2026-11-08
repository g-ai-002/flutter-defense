import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/engine/defense_engine.dart';
import '../game/logic_rate.dart';
import 'board_component.dart';

/// Flame 游戏入口：只挂一个战场组件，战斗逻辑由其按固定步长推进。
class DefenseGame extends FlameGame {
  DefenseGame({required this.engine, required this.logicRate}) {
    _activeGames++;
  }

  final DefenseEngine engine;
  final LogicRate logicRate;
  final ValueNotifier<bool> pausedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> speed = ValueNotifier<double>(1);
  BoardComponent? _board;

  static int _activeGames = 0;
  bool _disposed = false;
  bool _notifiersDisposed = false;

  /// 仍在运行的战场实例数：对局页全部关闭后应回到 0，供回归测试确认无残留任务。
  @visibleForTesting
  static int get activeGames => _activeGames;

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

  /// 页面销毁时停掉渲染循环并释放战场组件，避免返回首页后仍有逐帧回调。
  @override
  void onDispose() {
    if (_disposed) return;
    _disposed = true;
    if (isMounted) pauseEngine();
    _board = null;
    if (_activeGames > 0) _activeGames--;
    super.onDispose();
  }

  /// 值通知器归对局页所有，页面销毁时释放；重复调用不再二次释放。
  void disposeNotifiers() {
    if (_notifiersDisposed) return;
    _notifiersDisposed = true;
    pausedNotifier.dispose();
    speed.dispose();
  }
}
