import 'package:carrot_defense/game/engine/defense_engine.dart';
import 'package:carrot_defense/models/defense_models.dart';
import 'package:carrot_defense/models/level.dart';
import 'package:carrot_defense/services/log_service.dart';
import 'package:carrot_defense/services/music_service.dart';
import 'package:carrot_defense/services/sound_service.dart';
import 'package:carrot_defense/services/storage_service.dart';
import 'package:carrot_defense/theme/level_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 初始化测试环境：内存偏好、静音出口、重置单例。
Future<void> initTestEnvironment() async {
  SharedPreferences.setMockInitialValues({});
  StorageService.resetForTests();
  LogService.reset();
  SoundService.reset();
  MusicService.reset();
  SoundService.sink = (_) {};
}

/// 一条横穿地图的直路，便于精确验证伤害与减速。
LevelDef straightLevel({
  int carrotHp = 10,
  int startGold = 1000,
  double hpScale = 1,
  required List<WaveDef> waves,
  List<GridPos>? slots,
  List<FogZone> fog = const [],
  int id = 99,
}) {
  return LevelDef(
    id: id,
    name: '测试关卡',
    subtitle: '测试',
    theme: LevelTheme.meadow,
    path: const [GridPos(-1.2, 4), GridPos(15, 4)],
    slots:
        slots ??
        const [GridPos(4, 3), GridPos(6, 3), GridPos(8, 3), GridPos(10, 3), GridPos(12, 3)],
    startGold: startGold,
    carrotHp: carrotHp,
    hpScale: hpScale,
    waves: waves,
    fog: fog,
    seed: 42,
  );
}

/// 以固定步长推进引擎，返回实际推进的秒数。
double advance(DefenseEngine engine, double seconds, {double step = 1 / 60}) {
  var elapsed = 0.0;
  while (elapsed < seconds && !engine.isFinished) {
    engine.update(step);
    elapsed += step;
  }
  return elapsed;
}

SpawnGroup spawn(EnemyKind kind, int count, {double gap = 0.6, double delay = 0}) =>
    SpawnGroup(kind, count, gap: gap, delay: delay);
