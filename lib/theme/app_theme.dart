import 'package:flutter/material.dart';

import '../utils/system_ui.dart';

/// 胡萝卜橙 + 奶油底色的视觉基调。
const Color appOrange = Color(0xFFE4572E);
const Color appOrangeDeep = Color(0xFFC84520);
const Color appGreen = Color(0xFF3F7D46);
const Color appGreenDeep = Color(0xFF2C5C35);
const Color appCream = Color(0xFFFBF7EA);

/// Web 端 Font：CanvasKit 没有系统中文字体回退，使用 soup_fonts 的思源黑体。
const String kWebFontFamily = 'SourceHanSansCN';

/// 标题与牌匾使用的中文字体回退链，优先楷体。
const List<String> kDisplayFontFallback = [
  'STKaiti',
  'KaiTi',
  'Microsoft YaHei UI',
  'Noto Serif CJK SC',
];

/// 卡片与弹窗共用的表面装饰：圆角、描边与投影。
BoxDecoration appPanelDecoration(
  BuildContext context, {
  double radius = 16,
  double surfaceAlpha = 1,
  double borderAlpha = 0.7,
  double shadowOpacity = 0.06,
  double shadowBlur = 12,
  Offset shadowOffset = const Offset(0, 4),
}) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surface.withValues(alpha: surfaceAlpha),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: colors.outline.withValues(alpha: borderAlpha)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: shadowOpacity),
        blurRadius: shadowBlur,
        offset: shadowOffset,
      ),
    ],
  );
}

ThemeData buildLightTheme({String? fontFamily}) {
  const scheme = ColorScheme.light(
    primary: appOrange,
    onPrimary: Color(0xFFFFFBF4),
    primaryContainer: Color(0xFFFFE0D2),
    onPrimaryContainer: Color(0xFF5C1D0C),
    secondary: appGreen,
    onSecondary: Color(0xFFFFFDF5),
    secondaryContainer: Color(0xFFDDEFC8),
    onSecondaryContainer: Color(0xFF1F3A21),
    surface: Color(0xFFFFFDF6),
    onSurface: Color(0xFF2E2A21),
    surfaceContainerHighest: Color(0xFFF2EBD8),
    onSurfaceVariant: Color(0xFF7B7260),
    outline: Color(0xFFE4D9C1),
    outlineVariant: Color(0xFFEFE7D4),
    error: Color(0xFFB3261E),
    surfaceTint: Colors.transparent,
    tertiary: Color(0xFF3E7FA6),
  );

  return _buildBase(colorScheme: scheme, scaffoldColor: appCream, fontFamily: fontFamily);
}

ThemeData buildDarkTheme({String? fontFamily}) {
  const scheme = ColorScheme.dark(
    primary: Color(0xFFFF9C74),
    onPrimary: Color(0xFF4A1608),
    primaryContainer: Color(0xFF6B2714),
    onPrimaryContainer: Color(0xFFFFD9C8),
    secondary: Color(0xFFA8D08A),
    onSecondary: Color(0xFF17351B),
    secondaryContainer: Color(0xFF2C4A2E),
    onSecondaryContainer: Color(0xFFD8EDC5),
    surface: Color(0xFF262219),
    onSurface: Color(0xFFF2EBDD),
    surfaceContainerHighest: Color(0xFF332D22),
    onSurfaceVariant: Color(0xFFB3A892),
    outline: Color(0xFF463D2E),
    outlineVariant: Color(0xFF3A3326),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF3A0A08),
    surfaceTint: Colors.transparent,
    tertiary: Color(0xFF8FC0D8),
  );

  return _buildBase(
    colorScheme: scheme,
    scaffoldColor: const Color(0xFF1B1811),
    fontFamily: fontFamily,
  );
}

ThemeData _buildBase({
  required ColorScheme colorScheme,
  required Color scaffoldColor,
  String? fontFamily,
}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: fontFamily,
  );
  final textTheme = base.textTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  return base.copyWith(
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: systemOverlayStyleFor(scaffoldColor),
      toolbarHeight: 52,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      ),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: false,
      side: BorderSide(color: colorScheme.outline),
      shape: const StadiumBorder(),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontFamily: fontFamily),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outline.withValues(alpha: 0.6),
      thickness: 0.6,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
