import 'dart:math' as math;
import 'dart:ui';

/// 折线路径：按弧长取样位置与切线，敌人只保存「已走距离」。
class PathTrack {
  PathTrack(this.points)
    : assert(points.length >= 2),
      _cumulative = List<double>.filled(points.length, 0) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
      _cumulative[i] = total;
    }
    length = total;
  }

  final List<Offset> points;
  final List<double> _cumulative;
  late final double length;

  Offset pointAt(double distance) {
    final clamped = distance.clamp(0.0, length);
    for (var i = 1; i < points.length; i++) {
      if (clamped <= _cumulative[i]) {
        final span = _cumulative[i] - _cumulative[i - 1];
        final t = span <= 0 ? 0.0 : (clamped - _cumulative[i - 1]) / span;
        return Offset.lerp(points[i - 1], points[i], t)!;
      }
    }
    return points.last;
  }

  Offset tangentAt(double distance) {
    final clamped = distance.clamp(0.0, length);
    for (var i = 1; i < points.length; i++) {
      if (clamped <= _cumulative[i]) {
        final delta = points[i] - points[i - 1];
        final len = delta.distance;
        return len <= 0 ? const Offset(1, 0) : delta / len;
      }
    }
    final delta = points.last - points[points.length - 2];
    final len = delta.distance;
    return len <= 0 ? const Offset(1, 0) : delta / len;
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

double _distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
  if (lengthSquared <= 0) return (p - a).distance;
  final ap = p - a;
  final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared).clamp(0.0, 1.0);
  final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  return (p - closest).distance;
}
