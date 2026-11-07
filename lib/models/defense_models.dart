import 'dart:ui';

import '../utils/constants.dart';

/// 可建造的防御塔类型。
enum TowerKind {
  arrow('弓弩塔', '单体速射，性价比高'),
  cannon('火炮塔', '范围轰击，清理成群小怪'),
  frost('冰霜塔', '减速敌人，为输出争取时间'),
  lightning('雷电塔', '连锁闪电，最多命中多个目标'),
  poison('毒液塔', '持续中毒，无视护甲慢慢腐蚀');

  const TowerKind(this.label, this.blurb);

  final String label;
  final String blurb;
}

/// 敌人类型，决定体型、速度、护甲与赏金。
enum EnemyKind {
  slime('萝卜怪', '成群结队的基础敌人'),
  runner('疾风兔', '速度极快，血量较低'),
  beetle('铁甲虫', '护甲厚重，移动缓慢'),
  tank('岩甲兽', '高血量重装敌人'),
  boss('魔王', '最终波次的巨型首领');

  const EnemyKind(this.label, this.blurb);

  final String label;
  final String blurb;
}

/// 关卡网格坐标，可带小数，便于把入口放在屏幕外。
class GridPos {
  const GridPos(this.col, this.row);

  final double col;
  final double row;

  Offset get design => gridToDesign(col, row);
}
