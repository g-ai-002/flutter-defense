import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../flame/defense_game.dart';
import '../game/daily.dart';
import '../game/engine/defense_engine.dart';
import '../game/engine/entities.dart';
import '../game/levels.dart';
import '../models/endless.dart';
import '../models/level.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';
import '../utils/display_mode.dart';
import 'level_select_page.dart';
import 'widgets/game_hud.dart';
import 'widgets/game_overlays.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.level, this.fromLevelSelect = false});

  final LevelDef level;

  /// 从选关页进入时，退出直接返回上一页，避免叠出两层选关页。
  final bool fromLevelSelect;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final DefenseEngine _engine;
  late final DefenseGame _game;
  Timer? _resultTimer;
  double _speed = 1;
  bool _paused = false;
  bool _resultShown = false;
  bool _recorded = false;
  int _stars = 0;
  int _bestWaves = 0;
  bool _newRecord = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _engine = DefenseEngine(level: widget.level);
    _game = DefenseGame(engine: _engine, logicRate: settings.logicRate);
    _engine.hud.addListener(_onEngineTick);
    WidgetsBinding.instance.addObserver(this);
    LogService.info(
      '开始关卡 ${widget.level.id} ${widget.level.name}, '
      '逻辑 ${settings.logicRate.label}',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resultTimer?.cancel();
    _engine.hud.removeListener(_onEngineTick);
    // 先停渲染循环再释放引擎与通知器，返回首页后不残留逐帧回调与监听。
    _game.pauseEngine();
    _engine.dispose();
    _game.disposeNotifiers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (!_resultShown && !_engine.isFinished) _setPaused(true);
    }
  }

  void _onEngineTick() {
    if (_resultShown || !_engine.isFinished) return;
    _resultShown = true;
    _stars = _engine.stars;
    if (_engine.scored) {
      _finishScoredRun();
    } else if (_engine.status == GameStatus.victory && !_recorded) {
      _recorded = true;
      unawaited(context.read<ProgressProvider>().record(widget.level.id, _stars));
      LogService.info(
        '通关 ${widget.level.name}, 星级 $_stars, 剩余萝卜 '
        '${_engine.carrotHp}/${_engine.carrotMaxHp}',
      );
    } else {
      LogService.warning(
        '关卡失败 ${widget.level.name}, 击杀 ${_engine.kills}, '
        '漏怪 ${_engine.leaked}',
      );
    }
    // 先让胜利特效播完，再停住战场并弹出结算。
    _resultTimer = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      _setPaused(true);
    });
  }

  /// 无尽挑战与每日挑战都以坚守波数计分，只有记录位置不同。
  void _finishScoredRun() {
    if (_recorded) return;
    _recorded = true;
    final progress = context.read<ProgressProvider>();
    final waves = _engine.clearedWaves;
    final key = _engine.daily ? dailyKey(DateTime.now()) : null;
    final record = EndlessRecord.now(waves: waves, kills: _engine.kills, gold: _engine.goldEarned);
    _bestWaves = key == null
        ? progress.bestEndless?.waves ?? 0
        : progress.dailyBest(key)?.waves ?? 0;
    _newRecord = waves > _bestWaves;
    unawaited(key == null ? progress.recordEndless(record) : progress.recordDaily(key, record));
    LogService.info(
      '${key == null ? '无尽挑战' : '每日挑战 $key'}结束: 第 $waves 波, '
      '击杀 ${_engine.kills}, 金币 ${_engine.goldEarned}, 新纪录 $_newRecord',
    );
  }

  void _setPaused(bool value) {
    if (_paused == value || !mounted) return;
    setState(() => _paused = value);
    final paused = value || _resultShown;
    _game.pausedNotifier.value = paused;
    // 暂停时停掉 Flame 的渲染循环，避免后台或暂停面板下继续逐帧绘制。
    if (paused) {
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
  }

  void _cycleSpeed() {
    final values = AppConstants.battleSpeeds;
    final index = values.indexOf(_speed);
    final next = values[(index + 1) % values.length];
    setState(() => _speed = next);
    _game.speed.value = next;
    SoundService.play(SoundFx.tap);
  }

  void _handleBack() {
    if (_resultShown) {
      Navigator.of(context).pop();
      return;
    }
    _setPaused(true);
  }

  void _restart() {
    _resultTimer?.cancel();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => GamePage(level: widget.level)));
  }

  void _nextLevel() {
    final index = kLevels.indexWhere((item) => item.id == widget.level.id);
    if (index < 0 || index + 1 >= kLevels.length) return;
    _resultTimer?.cancel();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => GamePage(level: kLevels[index + 1])));
  }

  void _openLevelSelect() {
    _resultTimer?.cancel();
    if (widget.level.endless || widget.level.daily) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.fromLevelSelect) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => const LevelSelectPage()));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final daily = widget.level.daily;
    final hasNext = !daily && kLevels.any((item) => item.id == widget.level.id + 1);
    final exitLabel = widget.level.endless || daily ? '返回首页' : '返回选关';
    return ImmersiveDisplayMode(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF1B1811),
          body: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: GameWidget<DefenseGame>(key: ValueKey(_engine.hashCode), game: _game),
                ),
              ),
              Positioned.fill(
                child: GameHud(
                  engine: _engine,
                  speed: _speed,
                  onSpeed: _cycleSpeed,
                  onPause: () => _setPaused(true),
                  onBack: _handleBack,
                ),
              ),
              if (_paused && !_resultShown)
                Positioned.fill(
                  child: PauseOverlay(
                    logicLabel: settings.logicRate.label,
                    speed: _speed,
                    exitLabel: exitLabel,
                    onResume: () => _setPaused(false),
                    onRestart: _restart,
                    onExit: _openLevelSelect,
                  ),
                ),
              if (_resultShown)
                Positioned.fill(
                  child: GameResultOverlay(
                    level: widget.level,
                    engine: _engine,
                    victory: _engine.status == GameStatus.victory,
                    stars: _stars,
                    hasNext: hasNext,
                    endless: widget.level.endless,
                    daily: daily,
                    bestWaves: _bestWaves,
                    newRecord: _newRecord,
                    exitLabel: exitLabel,
                    onRetry: _restart,
                    onNext: _nextLevel,
                    onExit: _openLevelSelect,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
