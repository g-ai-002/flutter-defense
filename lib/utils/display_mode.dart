import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

/// 网格在横屏下是否明显比竖屏更舒展。
///
/// 分别按横竖两个方向计算战场缩放，只有横向能实际放大网格时才值得旋转屏幕，
/// 网格偏高或接近正方形时保持当前方向。
bool prefersLandscapeGrid(Size size) {
  final portrait = boardScaleFor(Size(size.shortestSide, size.longestSide));
  final landscape = boardScaleFor(Size(size.longestSide, size.shortestSide));
  return landscape > portrait * 1.02;
}

/// 手机与折叠屏折叠态等窄屏设备：网格横向更舒展时自动横屏全屏，
/// 否则保持竖屏；平板、桌面与 Web 不改变方向与系统栏，避免突然旋转。
bool shouldImmersiveLandscape(Size size) =>
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android &&
    size.shortestSide < 600 &&
    prefersLandscapeGrid(size);

/// 游戏页显示模式：满足 [shouldImmersiveLandscape] 时切到横屏并隐藏系统栏，
/// 离开后恢复系统栏与自动旋转。多个游戏页叠放时按引用计数只在最后一个退出时恢复。
class ImmersiveDisplayMode extends StatefulWidget {
  const ImmersiveDisplayMode({super.key, required this.child});

  final Widget child;

  @override
  State<ImmersiveDisplayMode> createState() => _ImmersiveDisplayModeState();
}

class _ImmersiveDisplayModeState extends State<ImmersiveDisplayMode> {
  static int _holders = 0;

  bool _applied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wanted = shouldImmersiveLandscape(MediaQuery.sizeOf(context));
    if (wanted == _applied) return;
    _applied = wanted;
    if (wanted) {
      _holders++;
      if (_holders == 1) _enter();
    } else {
      _release();
    }
  }

  Future<void> _enter() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _release() {
    if (_holders > 0) _holders--;
    if (_holders > 0) return;
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    if (_applied) _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
