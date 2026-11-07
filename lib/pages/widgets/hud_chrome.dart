import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// HUD 通用装饰与小型控件，供顶栏、底栏共用。

BoxDecoration hudPanelDecoration(
  BuildContext context, {
  required double radius,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return appPanelDecoration(
    context,
    radius: radius,
    surfaceAlpha: dark ? 0.9 : 0.92,
    borderAlpha: 0.75,
    shadowOpacity: dark ? 0.3 : 0.12,
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
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
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
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(99),
      ),
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

class HudSpeedButton extends StatelessWidget {
  const HudSpeedButton({
    super.key,
    required this.speed,
    required this.compact,
    required this.onPressed,
  });

  final double speed;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: '切换战斗速度',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: compact ? 34 : 40,
          height: compact ? 28 : 32,
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
      constraints: BoxConstraints.tightFor(
        width: compact ? 28 : 32,
        height: compact ? 28 : 32,
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
          Text(
            label.replaceAll('升级 ', ''),
            style: const TextStyle(fontSize: 11),
          ),
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
