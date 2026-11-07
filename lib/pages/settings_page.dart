import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/logic_rate.dart';
import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../services/log_service.dart';
import '../utils/constants.dart';
import '../utils/platform_info.dart';
import 'widgets/section_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 26),
              children: [
                SectionCard(
                  title: '音频与反馈',
                  icon: Icons.graphic_eq_rounded,
                  children: [
                    _SwitchRow(
                      title: '游戏音效',
                      subtitle: '建造、射击、金币与胜负提示音，运行时合成',
                      value: settings.soundEnabled,
                      onChanged: settings.setSoundEnabled,
                    ),
                    const SizedBox(height: 10),
                    _SwitchRow(
                      title: '背景音乐',
                      subtitle: '轻快五声音阶循环，可随时关闭',
                      value: settings.musicEnabled,
                      onChanged: settings.setMusicEnabled,
                    ),
                    const SizedBox(height: 10),
                    _SwitchRow(
                      title: '震动反馈',
                      subtitle: '建造、漏怪与胜负时的触感',
                      value: settings.hapticsEnabled,
                      onChanged: settings.setHapticsEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: '战斗',
                  icon: Icons.speed_rounded,
                  children: [
                    Text(
                      '逻辑刷新率',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '战斗逻辑按固定步长推进，渲染仍跟随屏幕刷新率。'
                      '低刷新率更省电，高刷新率更顺滑。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final rate in LogicRate.values)
                          ChoiceChip(
                            label: Text(rate.label),
                            selected: settings.logicRate == rate,
                            onSelected: (_) => settings.setLogicRate(rate),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前：${settings.logicRate.label}，默认 60Hz',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: '外观',
                  icon: Icons.palette_outlined,
                  children: [
                    _SwitchRow(
                      title: '深色模式',
                      subtitle: '夜间游戏更护眼',
                      value: settings.darkMode,
                      onChanged: settings.setDarkMode,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: '运行日志',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    FutureBuilder<String>(
                      future: FileSystemService.instance.getLogRootPath(),
                      builder: (context, snapshot) {
                        final path = snapshot.data ?? '';
                        return SelectableText(
                          path.isEmpty ? '日志仅保存在内存中，可在下方查看最近记录' : path,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showLogs(context),
                          icon: const Icon(Icons.article_outlined, size: 17),
                          label: const Text('查看最近日志'),
                        ),
                        if (isDesktopPlatform)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final path = await FileSystemService.instance
                                  .getLogRootPath();
                              await FileSystemService.instance.openDirectory(
                                path,
                              );
                            },
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 17,
                            ),
                            label: const Text('打开日志目录'),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: '关于',
                  icon: Icons.info_outline_rounded,
                  children: [
                    Text(
                      '${AppConstants.appName} v${AppConstants.version}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '本地单机塔防，不含任何联网功能。塔与怪物均为程序化绘制，'
                      '音效与音乐在运行时合成，仓库不携带音频文件。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showLogs(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.72,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('最近日志', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    reverse: true,
                    child: SelectableText(
                      LogService.getRecentLogs(400).join('\n'),
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.55,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
