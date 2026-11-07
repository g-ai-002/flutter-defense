import '../models/defense_models.dart';
import '../models/level.dart';
import '../theme/level_theme.dart';

/// 把关卡坐标压缩成「列,行 列,行 …」的紧凑写法，减少重复样板。
List<GridPos> _cells(String spec) => [
  for (final cell in spec.split(' '))
    GridPos(double.parse(cell.split(',')[0]), double.parse(cell.split(',')[1])),
];

final List<GridPos> _pathA = _cells('-1.2,1 4,1 4,4 11,4 11,7 15,7');

final List<GridPos> _slotsA = _cells(
  '2,2 6,2 2,3 5,3 8,3 10,3 13,2 3,5 6,5 8,5 10,5 13,5 9,6 12,6',
);

final List<GridPos> _pathB = _cells('-1.2,7 3,7 3,2 7,2 7,6 11,6 11,1 14,1');

final List<GridPos> _slotsB = _cells(
  '1,5 2,6 4,6 2,3 4,3 5,1 6,4 8,4 8,2 10,4 9,7 12,3 12,5 13,6 14,4',
);

final List<GridPos> kPathC = _cells('-1.2,1 13,1 13,3 3,3 3,5 13,5 13,7 5,7');

final List<GridPos> kSlotsC = _cells(
  '4,0 9,0 14,0 1,2 6,2 10,2 14,2 1,4 6,4 10,4 14,4 1,6 7,6 10,6 12,6',
);

final List<GridPos> _pathD = _cells('-1.2,4 3,4 3,1 8,1 8,6 12,6 12,2 15,2 15,7');

final List<GridPos> _slotsD = _cells(
  '1,2 2,5 4,2 4,5 5,3 6,0 7,3 9,3 9,7 10,5 11,0 13,4 14,5 13,0',
);

final List<GridPos> _pathE = _cells('-1.2,2 5,2 5,6 9,6 9,2 13,2 13,7');

final List<GridPos> _slotsE = _cells(
  '2,0 6,0 11,0 3,3 4,4 7,4 10,4 2,4 6,5 11,5 7,7 8,7 14,4 15,6',
);

final List<GridPos> _pathA2 = _cells('-1.2,7 4,7 4,4 10,4 10,1 15,1');

final List<GridPos> _slotsA2 = _cells(
  '2,2 6,2 8,2 12,2 13,2 2,3 5,3 3,5 6,5 8,5 12,5 9,6 12,6 14,3',
);

final List<GridPos> _pathC2 = _cells('-1.2,7 13,7 13,5 3,5 3,3 13,3 13,1 5,1');

final List<GridPos> _pathD2 = _cells('-1.2,1 3,1 3,6 8,6 8,2 12,2 12,7 15,7');

final List<GridPos> _pathF = _cells('-1.2,2 4,2 4,6 8,6 8,2 12,2 12,6 15.2,6');

final List<GridPos> _slotsF = _cells('2,0 6,0 10,0 14,0 2,4 6,4 10,4 14,4 2,8 6,8 10,8 14,8 13,0');

/// 第 12 关：主路绕上侧，支路绕下侧，在萝卜前汇合。
final List<GridPos> _pathG = _cells('-1.2,2 4,2 4,5 9,5 9,1 12,1 12,4 15,4');

final List<GridPos> _branchG = _cells('-1.2,2 4,2 4,7 9,7 12,7 12,4 15,4');

final List<GridPos> _slotsG = _cells(
  '2,0 6,0 10,0 1,4 3,4 6,3 7,3 10,3 2,6 6,6 8,6 10,6 13,2 14,6 15,2',
);

WaveDef _wave(List<SpawnGroup> groups, {int reward = 30, double hp = 1}) =>
    WaveDef(groups, reward: reward, hpScale: hp);

/// 敌人小队简写：数量、间隔、延迟与分岔路线都按位置传入，便于紧凑排版。
SpawnGroup _g(EnemyKind kind, int count, [double gap = 0.9, double delay = 0, int lane = -1]) =>
    SpawnGroup(kind, count, gap: gap, delay: delay, lane: lane);

const EnemyKind _s = EnemyKind.slime;
const EnemyKind _r = EnemyKind.runner;
const EnemyKind _b = EnemyKind.beetle;
const EnemyKind _t = EnemyKind.tank;
const EnemyKind _boss = EnemyKind.boss;
const EnemyKind _f = EnemyKind.flyer;

final List<LevelDef> kLevels = [
  LevelDef(
    id: 1,
    name: '青草平原',
    subtitle: '萝卜村的第一道防线',
    theme: LevelTheme.meadow,
    path: _pathA,
    slots: _slotsA,
    startGold: 260,
    carrotHp: 20,
    hpScale: 0.85,
    seed: 101,
    waves: [
      _wave([_g(_s, 6, 1.1)]),
      _wave([_g(_s, 8, 0.95), _g(_r, 2, 1.2, 4)]),
      _wave([_g(_s, 8, 0.9), _g(_b, 2, 1.4, 3)]),
      _wave([_g(_r, 6, 0.75), _g(_b, 3, 1.5, 2)]),
      _wave([_g(_s, 10, 0.8), _g(_b, 4, 1.3, 2)], reward: 40),
      _wave([_g(_b, 4, 1.4), _g(_t, 1, 0.9, 2), _g(_s, 8, 0.7, 4)], reward: 70, hp: 1.1),
    ],
  ),
  LevelDef(
    id: 2,
    name: '蘑菇小径',
    subtitle: '林间小路，怪物成群',
    theme: LevelTheme.forest,
    path: _pathB,
    slots: _slotsB,
    startGold: 260,
    carrotHp: 20,
    hpScale: 0.95,
    seed: 202,
    waves: [
      _wave([_g(_s, 6, 1.0)]),
      _wave([_g(_s, 8, 0.9), _g(_r, 3, 1.0, 3)]),
      _wave([_g(_b, 3, 1.3), _g(_s, 6, 0.8)]),
      _wave([_g(_r, 8, 0.65), _g(_b, 3, 1.4, 2)], reward: 40),
      _wave([_g(_s, 10, 0.75), _g(_b, 4, 1.2, 2)]),
      _wave([_g(_b, 5, 1.2), _g(_t, 1, 0.9, 2), _g(_s, 6, 0.9, 5)]),
      _wave([_g(_s, 10, 0.6), _g(_b, 4, 1.1, 3), _g(_t, 2, 2, 6)], reward: 80, hp: 1.1),
    ],
  ),
  LevelDef(
    id: 3,
    name: '黄沙绿洲',
    subtitle: '沙漠深处的流寇',
    theme: LevelTheme.desert,
    path: _pathA2,
    slots: _slotsA2,
    startGold: 280,
    carrotHp: 20,
    hpScale: 1.1,
    seed: 303,
    waves: [
      _wave([_g(_s, 7, 0.95)]),
      _wave([_g(_r, 6, 0.7), _g(_s, 6, 0.9, 2)]),
      _wave([_g(_b, 4, 1.2), _g(_s, 8, 0.8)]),
      _wave([_g(_r, 8, 0.6), _g(_b, 4, 1.2, 2)], reward: 40),
      _wave([_g(_s, 12, 0.65), _g(_b, 4, 1.1, 3)]),
      _wave([_g(_t, 2, 2.0), _g(_r, 8, 0.55, 1)]),
      _wave([_g(_b, 6, 1.0), _g(_s, 10, 0.6)], reward: 55),
      _wave([_g(_t, 3, 1.8), _g(_b, 5, 1.0, 3), _g(_r, 8, 0.5, 6)], reward: 95, hp: 1.15),
    ],
  ),
  LevelDef(
    id: 4,
    name: '霜雪回廊',
    subtitle: '寒风中的折返长路',
    theme: LevelTheme.snow,
    path: kPathC,
    slots: kSlotsC,
    startGold: 300,
    carrotHp: 20,
    hpScale: 1.2,
    seed: 404,
    waves: [
      _wave([_g(_s, 8, 0.9)]),
      _wave([_g(_r, 8, 0.65), _g(_s, 6, 0.8, 3)]),
      _wave([_g(_b, 4, 1.2), _g(_r, 6, 0.7, 2)]),
      _wave([_g(_s, 12, 0.65), _g(_b, 4, 1.1)], reward: 40),
      _wave([_g(_t, 2, 2.2), _g(_b, 4, 1.2, 2)]),
      _wave([_g(_r, 10, 0.55), _g(_b, 5, 1.0, 3)], reward: 55),
      _wave([_g(_s, 14, 0.55), _g(_t, 2, 2.0, 4)]),
      _wave([_g(_b, 6, 1.0), _g(_t, 3, 1.8, 2), _g(_r, 10, 0.5, 5)], reward: 100, hp: 1.15),
    ],
  ),
  LevelDef(
    id: 5,
    name: '月夜湖畔',
    subtitle: '夜色下的连环弯道',
    theme: LevelTheme.night,
    path: _pathE,
    slots: _slotsE,
    startGold: 300,
    carrotHp: 20,
    hpScale: 1.4,
    seed: 505,
    waves: [
      _wave([_g(_s, 8, 0.85)]),
      _wave([_g(_r, 8, 0.6), _g(_b, 3, 1.2, 2)]),
      _wave([_g(_b, 5, 1.1), _g(_s, 8, 0.8)]),
      _wave([_g(_t, 2, 2.2), _g(_r, 8, 0.6, 2)], reward: 45),
      _wave([_g(_s, 14, 0.6), _g(_b, 5, 1.0, 2)]),
      _wave([_g(_r, 12, 0.5), _g(_t, 2, 2.0, 4)], reward: 60),
      _wave([_g(_b, 7, 0.9), _g(_s, 10, 0.6, 3)]),
      _wave([_g(_t, 3, 1.8), _g(_r, 10, 0.55, 2), _g(_f, 2, 1.8, 5)], reward: 70),
      _wave([_g(_b, 8, 0.8), _g(_t, 3, 1.7, 4), _g(_boss, 1, 0.9, 6)], reward: 120, hp: 1.1),
    ],
  ),
  LevelDef(
    id: 6,
    name: '熔岩峡谷',
    subtitle: '炽热岩浆上的蛇形路',
    theme: LevelTheme.lava,
    path: _pathD,
    slots: _slotsD,
    startGold: 320,
    carrotHp: 20,
    hpScale: 1.55,
    seed: 606,
    waves: [
      _wave([_g(_s, 9, 0.8)]),
      _wave([_g(_r, 10, 0.55), _g(_s, 8, 0.8, 2)]),
      _wave([_g(_b, 6, 1.0), _g(_r, 6, 0.6, 3)]),
      _wave([_g(_t, 2, 2.0), _g(_b, 5, 1.1, 2)], reward: 50),
      _wave([_g(_s, 16, 0.55), _g(_b, 5, 1.0, 2)]),
      _wave([_g(_r, 12, 0.5), _g(_t, 2, 2.0, 3)], reward: 65),
      _wave([_g(_b, 8, 0.9), _g(_s, 10, 0.55, 4)]),
      _wave([_g(_t, 4, 1.6), _g(_r, 12, 0.45, 2), _g(_f, 2, 1.5, 4)], reward: 80),
      _wave([_g(_b, 8, 0.8), _g(_boss, 1, 0.9, 3), _g(_t, 3, 1.6, 6)], reward: 140, hp: 1.1),
    ],
  ),
  LevelDef(
    id: 7,
    name: '幽影林地',
    subtitle: '毒雾弥漫，怪物抱团冲锋',
    theme: LevelTheme.forest,
    path: _pathB,
    slots: _slotsB,
    startGold: 340,
    carrotHp: 20,
    hpScale: 1.9,
    seed: 707,
    fog: const [FogZone(GridPos(5, 2), radius: 112), FogZone(GridPos(9, 6), radius: 112)],
    waves: [
      _wave([_g(_s, 10, 0.75)]),
      _wave([_g(_r, 10, 0.55), _g(_b, 4, 1.1, 2)]),
      _wave([_g(_b, 6, 1.0), _g(_s, 10, 0.7)]),
      _wave([_g(_t, 3, 1.8), _g(_r, 8, 0.55, 3)], reward: 50),
      _wave([_g(_s, 16, 0.55), _g(_b, 6, 1.0, 2), _g(_f, 2, 1.8, 5)]),
      _wave([_g(_r, 14, 0.45), _g(_t, 2, 2.0, 4)], reward: 65),
      _wave([_g(_b, 8, 0.9), _g(_s, 12, 0.55, 3)]),
      _wave([_g(_t, 4, 1.6), _g(_b, 6, 1.0, 2), _g(_f, 3, 1.6, 4)], reward: 75),
      _wave([_g(_r, 16, 0.4), _g(_s, 12, 0.5, 4)]),
      _wave(
        [_g(_b, 10, 0.7), _g(_t, 4, 1.6, 3), _g(_f, 3, 1.5, 5), _g(_boss, 1, 0.9, 8)],
        reward: 150,
        hp: 1.15,
      ),
    ],
  ),
  LevelDef(
    id: 8,
    name: '极寒栈道',
    subtitle: '冰霜与铁甲的双重考验',
    theme: LevelTheme.snow,
    path: _pathC2,
    slots: kSlotsC.reversed.toList(),
    startGold: 340,
    carrotHp: 22,
    hpScale: 2.15,
    seed: 808,
    waves: [
      _wave([_g(_s, 10, 0.75)]),
      _wave([_g(_r, 12, 0.5), _g(_s, 8, 0.8, 2)]),
      _wave([_g(_b, 6, 1.0), _g(_r, 8, 0.6, 2)]),
      _wave([_g(_t, 3, 1.8), _g(_b, 5, 1.1, 2)], reward: 55),
      _wave([_g(_s, 18, 0.5), _g(_b, 6, 1.0, 2)]),
      _wave([_g(_r, 14, 0.45), _g(_t, 3, 1.8, 3), _g(_f, 3, 1.6, 5)], reward: 70),
      _wave([_g(_b, 9, 0.85), _g(_s, 12, 0.5, 3)]),
      _wave([_g(_t, 5, 1.5), _g(_r, 12, 0.45, 2)], reward: 85),
      _wave([_g(_b, 10, 0.75), _g(_s, 14, 0.5, 4), _g(_f, 4, 1.4, 6)]),
      _wave([_g(_t, 4, 1.6), _g(_boss, 1, 0.9, 3), _g(_b, 8, 0.8, 6)], reward: 160, hp: 1.15),
    ],
  ),
  LevelDef(
    id: 9,
    name: '赤沙关隘',
    subtitle: '通往魔王城塞的咽喉',
    theme: LevelTheme.desert,
    path: _pathA2,
    slots: _slotsA2,
    startGold: 360,
    carrotHp: 22,
    hpScale: 2.2,
    seed: 909,
    waves: [
      _wave([_g(_s, 12, 0.7)]),
      _wave([_g(_r, 12, 0.5), _g(_b, 5, 1.0, 2)]),
      _wave([_g(_b, 7, 0.95), _g(_s, 12, 0.6)]),
      _wave([_g(_t, 3, 1.8), _g(_r, 10, 0.5, 3)], reward: 60),
      _wave([_g(_s, 18, 0.5), _g(_b, 7, 0.95, 2), _g(_f, 3, 1.5, 5)]),
      _wave([_g(_r, 16, 0.42), _g(_t, 3, 1.8, 4)], reward: 75),
      _wave([_g(_b, 10, 0.8), _g(_s, 14, 0.5, 3)]),
      _wave([_g(_t, 5, 1.5), _g(_b, 7, 0.9, 2), _g(_f, 4, 1.4, 5)], reward: 90),
      _wave([_g(_r, 18, 0.4), _g(_s, 16, 0.45, 4)]),
      _wave([_g(_b, 12, 0.7), _g(_t, 5, 1.5, 3), _g(_f, 5, 1.3, 6)], reward: 110),
      _wave([_g(_boss, 1), _g(_b, 10, 0.75, 3), _g(_t, 5, 1.4, 6)], reward: 200, hp: 1.2),
    ],
  ),
  LevelDef(
    id: 10,
    name: '魔王城塞',
    subtitle: '最终决战，守住最后一根萝卜',
    theme: LevelTheme.lava,
    path: _pathD2,
    slots: _slotsD,
    startGold: 380,
    carrotHp: 25,
    hpScale: 2.9,
    seed: 1010,
    waves: [
      _wave([_g(_s, 12, 0.65)]),
      _wave([_g(_r, 14, 0.45), _g(_b, 6, 0.9, 2)]),
      _wave([_g(_b, 8, 0.9), _g(_s, 14, 0.55)]),
      _wave([_g(_t, 4, 1.6), _g(_r, 12, 0.45, 3)], reward: 65),
      _wave([_g(_s, 20, 0.45), _g(_b, 8, 0.9, 2)]),
      _wave([_g(_r, 18, 0.4), _g(_t, 4, 1.6, 3), _g(_f, 4, 1.4, 5)], reward: 80),
      _wave([_g(_b, 12, 0.7), _g(_s, 16, 0.45, 3)]),
      _wave([_g(_t, 6, 1.4), _g(_b, 8, 0.85, 2)], reward: 100),
      _wave([_g(_r, 20, 0.38), _g(_b, 10, 0.8, 4), _g(_f, 5, 1.3, 6)]),
      _wave([_g(_b, 14, 0.65), _g(_t, 6, 1.4, 3)], reward: 120),
      _wave([_g(_boss, 1), _g(_r, 16, 0.4, 2)], reward: 160, hp: 1.1),
      _wave(
        [_g(_boss, 2, 6), _g(_b, 12, 0.7, 4), _g(_t, 6, 1.4, 8), _g(_r, 20, 0.35, 12)],
        reward: 300,
        hp: 1.25,
      ),
    ],
  ),
  LevelDef(
    id: 11,
    name: '毒沼秘境',
    subtitle: '毒雾与蝠群的双重试炼',
    theme: LevelTheme.night,
    path: _pathF,
    slots: _slotsF,
    startGold: 460,
    carrotHp: 25,
    hpScale: 2.95,
    seed: 1111,
    fog: const [
      FogZone(GridPos(2, 2), radius: 108),
      FogZone(GridPos(6, 2), radius: 118),
      FogZone(GridPos(10, 6), radius: 118),
    ],
    waves: [
      _wave([_g(_s, 12, 0.7)], hp: 0.62),
      _wave([_g(_s, 12, 0.65), _g(_r, 10, 0.5, 2)], hp: 0.66),
      _wave([_g(_b, 8, 0.9), _g(_s, 12, 0.6, 2)], hp: 0.7),
      _wave([_g(_t, 3, 1.8), _g(_r, 10, 0.5, 3)], reward: 60, hp: 0.76),
      _wave([_g(_s, 18, 0.5), _g(_f, 3, 1.6, 4)], hp: 0.82),
      _wave([_g(_b, 10, 0.8), _g(_r, 14, 0.45, 2), _g(_f, 3, 1.5, 5)], reward: 75, hp: 0.88),
      _wave([_g(_t, 4, 1.6), _g(_b, 8, 0.9, 2), _g(_f, 4, 1.4, 5)], hp: 0.92),
      _wave([_g(_s, 16, 0.45), _g(_b, 10, 0.8, 3), _g(_f, 4, 1.4, 6)], reward: 90),
      _wave([_g(_r, 18, 0.4), _g(_t, 4, 1.6, 3)], reward: 95),
      _wave([_g(_b, 10, 0.7), _g(_t, 4, 1.5, 3), _g(_f, 5, 1.3, 6)], reward: 110, hp: 1.05),
      _wave([_g(_s, 18, 0.4), _g(_boss, 1, 0.9, 4)], reward: 160, hp: 1.05),
      _wave(
        [_g(_boss, 2, 6), _g(_b, 10, 0.65, 4), _g(_t, 4, 1.4, 7), _g(_f, 5, 1.2, 10)],
        reward: 320,
        hp: 1.15,
      ),
    ],
  ),
  LevelDef(
    id: 12,
    name: '双径幻阵',
    subtitle: '分岔土路、传送门与毒雾',
    theme: LevelTheme.night,
    path: _pathG,
    branch: _branchG,
    slots: _slotsG,
    startGold: 640,
    carrotHp: 32,
    hpScale: 3,
    seed: 1212,
    fog: const [FogZone(GridPos(6, 4), radius: 110)],
    portals: const [Portal(GridPos(9, 5), GridPos(12, 1))],
    waves: [
      _wave([_g(_s, 10, 0.8)], hp: 0.5),
      _wave([_g(_s, 10, 0.7), _g(_r, 6, 0.6, 2)], hp: 0.52),
      _wave([_g(_b, 6, 1), _g(_s, 10, 0.65, 2)], hp: 0.55),
      _wave([_g(_r, 10, 0.5, 0, 1), _g(_b, 5, 0.9, 2, 1)], reward: 55, hp: 0.58),
      _wave([_g(_s, 12, 0.6), _g(_f, 3, 1.5, 4)], hp: 0.6),
      _wave([_g(_b, 8, 0.9), _g(_t, 2, 1.8, 2), _g(_r, 10, 0.5, 3)], reward: 65, hp: 0.62),
      _wave([_g(_t, 3, 1.7, 0, 0), _g(_b, 6, 0.9, 0, 1), _g(_f, 3, 1.4, 4)], hp: 0.65),
      _wave([_g(_s, 16, 0.5), _g(_b, 8, 0.8, 2), _g(_f, 4, 1.3, 5)], reward: 80, hp: 0.68),
      _wave([_g(_r, 14, 0.45), _g(_t, 4, 1.6, 3)], hp: 0.7),
      _wave([_g(_b, 10, 0.8), _g(_t, 3, 1.5, 2), _g(_f, 4, 1.2, 5)], reward: 100, hp: 0.72),
      _wave([_g(_boss, 1, 0.9, 1), _g(_b, 8, 0.8, 3), _g(_r, 12, 0.45, 5)], reward: 170, hp: 0.75),
      _wave(
        [_g(_boss, 2, 6), _g(_b, 10, 0.7, 4), _g(_t, 4, 1.4, 7), _g(_f, 5, 1.2, 10)],
        reward: 340,
        hp: 0.8,
      ),
    ],
  ),
];
