import 'package:flutter/material.dart';

/// 关卡地貌：决定地面、道路与装饰物的配色。
enum LevelTheme {
  meadow('青草平原'),
  forest('蘑菇森林'),
  desert('黄沙绿洲'),
  snow('霜雪山口'),
  lava('熔岩峡谷'),
  night('月夜湖畔');

  const LevelTheme(this.label);
  final String label;
}

/// 单套地貌配色，渲染层只从这里取色。
class LevelPalette {
  const LevelPalette({
    required this.groundTop,
    required this.groundBottom,
    required this.groundDeep,
    required this.pathEdge,
    required this.pathFill,
    required this.pathLight,
    required this.padStone,
    required this.padStoneDark,
    required this.decorPrimary,
    required this.decorSecondary,
    required this.accent,
    required this.frame,
  });

  final Color groundTop;
  final Color groundBottom;
  final Color groundDeep;
  final Color pathEdge;
  final Color pathFill;
  final Color pathLight;
  final Color padStone;
  final Color padStoneDark;
  final Color decorPrimary;
  final Color decorSecondary;
  final Color accent;
  final Color frame;
}

const Map<LevelTheme, LevelPalette> _palettes = {
  LevelTheme.meadow: LevelPalette(
    groundTop: Color(0xFF9CD45F),
    groundBottom: Color(0xFF6FB544),
    groundDeep: Color(0xFF4E8F35),
    pathEdge: Color(0xFFB98C52),
    pathFill: Color(0xFFE0BE85),
    pathLight: Color(0xFFF0D9AC),
    padStone: Color(0xFFD9D2B4),
    padStoneDark: Color(0xFF9E9678),
    decorPrimary: Color(0xFF4C8F3B),
    decorSecondary: Color(0xFFF6E27A),
    accent: Color(0xFFE4572E),
    frame: Color(0xFF3E6B2C),
  ),
  LevelTheme.forest: LevelPalette(
    groundTop: Color(0xFF7FBE72),
    groundBottom: Color(0xFF4E8F58),
    groundDeep: Color(0xFF33663C),
    pathEdge: Color(0xFF9C704A),
    pathFill: Color(0xFFCBA579),
    pathLight: Color(0xFFE3C69C),
    padStone: Color(0xFFCAC3A9),
    padStoneDark: Color(0xFF8B846C),
    decorPrimary: Color(0xFF2F6B3C),
    decorSecondary: Color(0xFFE46A5A),
    accent: Color(0xFFF2A03D),
    frame: Color(0xFF284F2F),
  ),
  LevelTheme.desert: LevelPalette(
    groundTop: Color(0xFFF0D27E),
    groundBottom: Color(0xFFD9AC55),
    groundDeep: Color(0xFFB98A3B),
    pathEdge: Color(0xFFB47B45),
    pathFill: Color(0xFFE7C08A),
    pathLight: Color(0xFFF7DDAF),
    padStone: Color(0xFFE3D2A9),
    padStoneDark: Color(0xFFB39D72),
    decorPrimary: Color(0xFF6E9A4E),
    decorSecondary: Color(0xFFD9654A),
    accent: Color(0xFF3E8C8C),
    frame: Color(0xFF8A622E),
  ),
  LevelTheme.snow: LevelPalette(
    groundTop: Color(0xFFE7F2F7),
    groundBottom: Color(0xFFBCD8E6),
    groundDeep: Color(0xFF90B8CC),
    pathEdge: Color(0xFF98AEBB),
    pathFill: Color(0xFFD3E0E7),
    pathLight: Color(0xFFF1F7FA),
    padStone: Color(0xFFDDE8EE),
    padStoneDark: Color(0xFF9DB4C1),
    decorPrimary: Color(0xFF4C7C6A),
    decorSecondary: Color(0xFFF3FBFF),
    accent: Color(0xFF3E7FA6),
    frame: Color(0xFF5B7F92),
  ),
  LevelTheme.lava: LevelPalette(
    groundTop: Color(0xFF7A5243),
    groundBottom: Color(0xFF4B3029),
    groundDeep: Color(0xFF2E1E1A),
    pathEdge: Color(0xFF7D4A34),
    pathFill: Color(0xFFB07A57),
    pathLight: Color(0xFFD49B6F),
    padStone: Color(0xFFB79E8B),
    padStoneDark: Color(0xFF776353),
    decorPrimary: Color(0xFFE0602C),
    decorSecondary: Color(0xFFFFC14E),
    accent: Color(0xFFFF8A3D),
    frame: Color(0xFF3A241E),
  ),
  LevelTheme.night: LevelPalette(
    groundTop: Color(0xFF6C8794),
    groundBottom: Color(0xFF3D5763),
    groundDeep: Color(0xFF2B404A),
    pathEdge: Color(0xFF6E7C84),
    pathFill: Color(0xFFA6B4BC),
    pathLight: Color(0xFFC9D5DB),
    padStone: Color(0xFFC2CFD5),
    padStoneDark: Color(0xFF8497A0),
    decorPrimary: Color(0xFF2F4A54),
    decorSecondary: Color(0xFFF4E3A1),
    accent: Color(0xFF8FC6D8),
    frame: Color(0xFF23343C),
  ),
};

LevelPalette paletteOf(LevelTheme theme) => _palettes[theme] ?? _palettes[LevelTheme.meadow]!;
