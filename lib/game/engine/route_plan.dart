import 'dart:ui';

import '../../models/level.dart';
import 'path_track.dart';

/// 路线上的一道传送门跳跃：入口与出口的弧长，以及两端的设计坐标。
class PortalJump {
  const PortalJump({required this.entry, required this.exit, required this.at, required this.away});

  final double entry;
  final double exit;
  final Offset at;
  final Offset away;
}

/// 多路线规划：把关卡的路线、分流与传送门一次性解析成可查表的运行时结构。
///
/// 分岔关卡的地面敌人需要选路，同一道传送门在不同路线上的弧长也不相同。
/// 这些计算只在开局做一次，出怪与推进阶段直接查表，不再重复解析关卡定义。
class RoutePlan {
  RoutePlan(LevelDef level)
    : tracks = [
        for (final route in level.routes) PathTrack([for (final point in route) point.design]),
      ],
      _jumps = List.generate(level.routes.length, (_) => <PortalJump>[]) {
    for (final portal in level.portals) {
      for (var route = 0; route < tracks.length; route++) {
        final jump = _jumpOn(tracks[route], portal);
        if (jump != null) _jumps[route].add(jump);
      }
    }
  }

  /// 全部可行路线，主路固定在第 0 条。
  final List<PathTrack> tracks;

  /// 按路线分桶的传送门跳跃表，逐帧判定只遍历自己那条路线。
  final List<List<PortalJump>> _jumps;

  PathTrack get main => tracks.first;

  List<PortalJump> jumpsOn(int route) => _jumps[route];

  /// 出怪路线：飞行敌人固定走主航线，分岔关卡按小队指定或按出怪序号交替。
  int laneFor({required int requested, required int id, required bool flying}) {
    if (flying || tracks.length == 1) return 0;
    return requested >= 0 ? requested % tracks.length : id % tracks.length;
  }

  /// 路线总长度：飞行敌人走入口到萝卜的直线，地面敌人沿土路。
  double routeLength(int route, {required bool flying}) =>
      flying ? tracks[route].airLength : tracks[route].length;

  /// 点到任意一条土路的距离是否小于 [gap]，供装饰避让与摆放校验使用。
  bool nearRoute(Offset position, double gap) =>
      tracks.any((track) => track.distanceTo(position) < gap);

  /// 传送门两端都落在路线上且出口位于入口前方时才生效。
  static PortalJump? _jumpOn(PathTrack track, Portal portal) {
    final entry = track.nearest(portal.entryDesign);
    final exit = track.nearest(portal.exitDesign);
    if (entry.gap > portal.radius || exit.gap > portal.radius) return null;
    if (exit.along <= entry.along + 2) return null;
    return PortalJump(
      entry: entry.along,
      exit: exit.along,
      at: portal.entryDesign,
      away: portal.exitDesign,
    );
  }
}
