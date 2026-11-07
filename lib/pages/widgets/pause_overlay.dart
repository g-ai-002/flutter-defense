import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import 'overlay_shell.dart';

/// 暂停面板：继续、重开、离开，并可快速切换音频。
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.logicLabel,
    required this.speed,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
    this.exitLabel = '返回选关',
  });

  final String logicLabel;
  final double speed;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final String exitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    return GameOverlayFrame(
      width: 340,
      scrimAlpha: 0.5,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      shadowOpacity: 0.3,
      shadowBlur: 26,
      shadowOffset: const Offset(0, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.pause_circle_outline, color: colors.primary),
              const SizedBox(width: 8),
              Text('游戏暂停', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '逻辑 $logicLabel · 战斗速度 ${speed.toInt()}x',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            title: '游戏音效',
            value: settings.soundEnabled,
            onChanged: settings.setSoundEnabled,
          ),
          _ToggleRow(
            title: '背景音乐',
            value: settings.musicEnabled,
            onChanged: settings.setMusicEnabled,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onResume,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('继续游戏'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRestart,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('重新开始'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onExit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text(exitLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
