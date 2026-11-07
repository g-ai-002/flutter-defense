import '../game/engine/defense_engine.dart';
import '../game/engine/entities.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';

/// 把引擎事件翻译成音效与日志，渲染层不再关心事件细节。
class BoardEventFeedback {
  bool _resultLogged = false;

  void consume(DefenseEngine engine) {
    final events = engine.events;
    if (events.isEmpty) return;
    for (var i = 0; i < events.length; i++) {
      switch (events[i]) {
        case GameEvent.build:
          SoundService.play(SoundFx.build);
          final slot = engine.selectedSlot;
          if (slot != null) LogService.info('建造防御塔: 第${slot + 1}号位');
          break;
        case GameEvent.upgrade:
          SoundService.play(SoundFx.upgrade);
          break;
        case GameEvent.sell:
          SoundService.play(SoundFx.sell);
          break;
        case GameEvent.arrowShot:
          SoundService.play(SoundFx.arrow);
          break;
        case GameEvent.cannonShot:
          SoundService.play(SoundFx.cannon);
          break;
        case GameEvent.frostShot:
          SoundService.play(SoundFx.frost);
          break;
        case GameEvent.poisonShot:
          SoundService.play(SoundFx.poison);
          break;
        case GameEvent.lightning:
          SoundService.play(SoundFx.lightning);
          break;
        case GameEvent.hit:
          SoundService.play(SoundFx.hit);
          break;
        case GameEvent.leak:
          SoundService.play(SoundFx.leak);
          LogService.warning(
            '敌人突破防线, 萝卜剩余 ${engine.carrotHp}/${engine.carrotMaxHp}',
          );
          break;
        case GameEvent.waveStart:
          SoundService.play(SoundFx.waveStart);
          LogService.info(
            '第 ${engine.waveIndex}/${engine.level.waveCount} 波开始',
          );
          break;
        case GameEvent.waveClear:
          SoundService.play(SoundFx.waveClear);
          LogService.info('第 ${engine.waveIndex} 波清理完毕');
          break;
        case GameEvent.victory:
          SoundService.play(SoundFx.victory);
          _logResult(engine, true);
          break;
        case GameEvent.defeat:
          SoundService.play(SoundFx.defeat);
          _logResult(engine, false);
          break;
        case GameEvent.gold:
          SoundService.play(SoundFx.coin);
          break;
      }
    }
    events.clear();
  }

  void _logResult(DefenseEngine engine, bool victory) {
    if (_resultLogged) return;
    _resultLogged = true;
    LogService.info(
      '关卡结束: ${engine.level.name} ${victory ? '胜利' : '失败'}, '
      '萝卜 ${engine.carrotHp}/${engine.carrotMaxHp}, '
      '击杀 ${engine.kills}, 漏怪 ${engine.leaked}, 金币收入 ${engine.goldEarned}',
    );
  }
}
