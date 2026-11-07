import 'dart:ui';

/// 游戏统一设计尺寸：所有关卡坐标与绘制都基于这个画布。
const double kDesignWidth = 1280;
const double kDesignHeight = 720;

/// 关卡网格：16 × 9 格，每格 64 逻辑像素，居中留出装饰边距。
const int kGridCols = 16;
const int kGridRows = 9;
const double kCellSize = 64;
const double kGridOriginX = (kDesignWidth - kGridCols * kCellSize) / 2;
const double kGridOriginY = (kDesignHeight - kGridRows * kCellSize) / 2;

/// 网格坐标（可为小数）换算为设计画布坐标，返回格子中心。
Offset gridToDesign(double col, double row) => Offset(
  kGridOriginX + (col + 0.5) * kCellSize,
  kGridOriginY + (row + 0.5) * kCellSize,
);

/// 屏幕较矮时 HUD 使用紧凑高度，棋盘区域据此预留空间。
bool compactHudFor(Size size) => size.height < 600 || size.width < 760;

/// 顶部信息条占用的高度（含外边距）。
double hudTopInset(Size size) => compactHudFor(size) ? 48 : 62;

/// 底部塔栏占用的高度（含外边距）。
double hudBottomInset(Size size) => compactHudFor(size) ? 76 : 112;

class AppConstants {
  AppConstants._();

  static const String appName = '萝卜保卫战';
  static const String version = '0.2.1';

  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeySound = 'sound_enabled';
  static const String prefKeyMusic = 'music_enabled';
  static const String prefKeyHaptics = 'haptics_enabled';
  static const String prefKeyLogicRate = 'logic_rate';
  static const String prefKeyStars = 'level_stars';
  static const String prefKeyUnlocked = 'level_unlocked';
  static const String prefKeyEndless = 'endless_records';

  /// 战斗倍速档位。
  static const List<double> battleSpeeds = [1, 2, 3];
}
