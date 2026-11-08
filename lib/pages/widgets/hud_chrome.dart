import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// HUD 通用装饰与小型控件，供顶栏、底栏共用。

BoxDecoration hudPanelDecoration(BuildContext context, {required double radius}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return appPanelDecoration(
    context,
    radius: radius,
    surfaceAlpha: dark ? 0.9 : 0.92,
    borderAlpha: 0.75,
    shadowOpacity: dark ? 0.3 : 0.12,
  );
}

/// 信息簇上的小卡片：直接悬浮在战场地貌上，不套大外框，
/// 每个数值自带半透明底与描边，避免在地图上留下多余的空心方框。
BoxDecoration hudChipDecoration(BuildContext context, {double radius = 99}) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: theme.colorScheme.surface.withValues(alpha: dark ? 0.82 : 0.88),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.75)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.32 : 0.14),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class HudMiniBar extends StatelessWidget {
  const HudMiniBar({super.key, required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: ratio.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
        ),
      ),
    );
  }
}

class HudInfoPill extends StatelessWidget {
  const HudInfoPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.compact,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: compact ? 26 : 30,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
      decoration: hudChipDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: iconColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

/// 信息簇左上角的圆形图标按钮，与外框分离，看起来就是一枚按钮而不是方框。
class HudIconChip extends StatelessWidget {
  const HudIconChip({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.compact,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = compact ? 30.0 : 34.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: hudChipDecoration(context),
            child: Icon(
              icon,
              size: compact ? 17 : 19,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// 关卡名称与当前状态的两行小卡片，替代原先包住整簇信息的大外框。
class HudTitleChip extends StatelessWidget {
  const HudTitleChip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: compact ? 30 : 34,
      constraints: const BoxConstraints(maxWidth: 170),
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11),
      decoration: hudChipDecoration(context, radius: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          if (!compact)
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                height: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class HudSpeedButton extends StatelessWidget {
  const HudSpeedButton({
    super.key,
    required this.speed,
    required this.compact,
    required this.onPressed,
    this.width,
    this.height,
  });

  final double speed;
  final bool compact;
  final VoidCallback onPressed;

  /// 控制条可指定更紧凑的尺寸，默认沿用信息条尺寸。
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: '切换战斗速度',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: width ?? (compact ? 34 : 40),
          height: height ?? (compact ? 28 : 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${speed % 1 == 0 ? speed.toInt() : speed}x',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ),
      ),
    );
  }
}

class HudIconButton extends StatelessWidget {
  const HudIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.compact,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 17 : 19),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(width: compact ? 28 : 32, height: compact ? 28 : 32),
    );
  }
}

/// 控制条上的小图标按钮：尺寸完全受控，便于与倍速按钮竖直排布。
class HudGlyphButton extends StatelessWidget {
  const HudGlyphButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.width,
    required this.height,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double width;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: Icon(icon, size: height * 0.62, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class HudPanelButton extends StatelessWidget {
  const HudPanelButton({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.compact,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 13 : 15),
        if (!compact) ...[
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 12)),
        ] else if (label.contains('升级'))
          Text(label.replaceAll('升级 ', ''), style: const TextStyle(fontSize: 11)),
      ],
    );
    return Material(
      color: outlined
          ? colors.surface
          : enabled
          ? colors.primary
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: compact ? 30 : 38,
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: outlined ? Border.all(color: colors.outline) : null,
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(
              color: outlined
                  ? colors.onSurface
                  : enabled
                  ? colors.onPrimary
                  : colors.onSurfaceVariant,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: outlined
                    ? colors.onSurface
                    : enabled
                    ? colors.onPrimary
                    : colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
