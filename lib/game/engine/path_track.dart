import 'dart:math' as math;
import 'dart:ui';

/// 路径采样结果：位置与单位切线一次算出，避免同一帧重复扫描折线。
class PathSample {
  const PathSample(this.position, this.tangent);

  final Offset position;
  final Offset tangent;
}

/// 折线路径：按弧长取样位置与切线，敌人只保存「已走距离」。
///
/// 构造函数预先算好每段的长度与单位切线，采样时用二分查找定位分段，
/// 供每帧高频调用的渲染与索敌逻辑使用。
class PathTrack {
  PathTrack(this.points)
    : assert(points.length >= 2),
      _cumulative = List<double>.filled(points.length, 0),
      _tangents = List<Offset>.filled(points.length - 1, Offset.zero) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
      _cumulative[i] = total;
      _tangents[i - 1] = _unitTangent(points[i - 1], points[i]);
    }
    length = total;
  }

  final List<Offset> points;
  final List<double> _cumulative;
  final List<Offset> _tangents;
  late final double length;

  Offset pointAt(double distance) => sampleAt(distance).position;

  Offset tangentAt(double distance) => sampleAt(distance).tangent;

  /// 按弧长取样：返回位置与该处的单位切线。
  PathSample sampleAt(double distance) {
    final clamped = distance.clamp(0.0, length);
    var low = 1;
    var high = points.length - 1;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (clamped <= _cumulative[mid]) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    final index = low;
    final span = _cumulative[index] - _cumulative[index - 1];
    final t = span <= 0 ? 0.0 : (clamped - _cumulative[index - 1]) / span;
    return PathSample(
      Offset.lerp(points[index - 1], points[index], t)!,
      _tangents[index - 1],
    );
  }

  /// 点到路径的最短距离，用于校验建造点与摆放装饰。
  double distanceTo(Offset point) {
    var best = double.infinity;
    for (var i = 1; i < points.length; i++) {
      best = math.min(
        best,
        _distanceToSegment(point, points[i - 1], points[i]),
      );
    }
    return best;
  }

  /// 判断点是否落在路径两侧 [margin] 范围内。
  bool isNear(Offset point, double margin) => distanceTo(point) <= margin;
}

Offset _unitTangent(Offset a, Offset b) {
  final delta = b - a;
  final len = delta.distance;
  return len <= 0 ? const Offset(1, 0) : delta / len;
}

double _distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
  if (lengthSquared <= 0) return (p - a).distance;
  final ap = p - a;
  final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared).clamp(0.0, 1.0);
  final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  return (p - closest).distance;
}
