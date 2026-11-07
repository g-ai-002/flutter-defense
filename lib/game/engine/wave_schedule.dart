import '../../models/defense_models.dart';
import '../../models/level.dart';

/// 一个出怪事件：波次开始后 [time] 秒生成 [kind]，血量按 [hpScale] 缩放。
class SpawnEvent {
  const SpawnEvent(this.time, this.kind, this.hpScale);

  final double time;
  final EnemyKind kind;
  final double hpScale;
}

/// 波次时间表：把多组敌人展开为按时间排序的事件，并记录消费进度。
class WaveSchedule {
  WaveSchedule(WaveDef wave, {required double hpScale})
    : _events = _build(wave, hpScale);

  final List<SpawnEvent> _events;
  int _cursor = 0;

  int get total => _events.length;

  int get pending => _events.length - _cursor;

  bool get done => _cursor >= _events.length;

  /// 取出 [elapsed] 秒前应当生成的下一个事件，没有到点则返回 null。
  SpawnEvent? nextAt(double elapsed) {
    if (done) return null;
    final event = _events[_cursor];
    if (event.time > elapsed) return null;
    _cursor++;
    return event;
  }

  static List<SpawnEvent> _build(WaveDef wave, double hpScale) {
    final events = <SpawnEvent>[
      for (final group in wave.groups)
        for (var i = 0; i < group.count; i++)
          SpawnEvent(group.delay + i * group.gap, group.kind, hpScale),
    ];
    events.sort((a, b) => a.time.compareTo(b.time));
    return events;
  }
}
