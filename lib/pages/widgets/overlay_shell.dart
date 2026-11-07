import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 结算与暂停面板共用的遮罩 + 居中可滚动卡片外壳。
class GameOverlayFrame extends StatelessWidget {
  const GameOverlayFrame({
    super.key,
    required this.child,
    this.width = 380,
    this.scrimAlpha = 0.52,
    this.radius = 24,
    this.padding = const EdgeInsets.fromLTRB(22, 20, 22, 18),
    this.shadowOpacity = 0.35,
    this.shadowBlur = 30,
    this.shadowOffset = const Offset(0, 14),
    this.animate = true,
  });

  final Widget child;
  final double width;
  final double scrimAlpha;
  final double radius;
  final EdgeInsets padding;
  final double shadowOpacity;
  final double shadowBlur;
  final Offset shadowOffset;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: padding,
      decoration: appPanelDecoration(
        context,
        radius: radius,
        shadowOpacity: shadowOpacity,
        shadowBlur: shadowBlur,
        shadowOffset: shadowOffset,
      ),
      child: child,
    );
    if (animate) {
      card = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.86, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: card,
      );
    }
    return Container(
      color: Colors.black.withValues(alpha: scrimAlpha),
      alignment: Alignment.center,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: card,
          ),
        ),
      ),
    );
  }
}
