import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 依赖清单回归：音频引擎版本与固定版本号约束不被悄悄放松。
void main() {
  late List<String> lines;

  setUpAll(() {
    lines = File('pubspec.yaml').readAsLinesSync();
  });

  /// 读取顶层依赖块中某项的版本号。
  String versionOf(String name) {
    var inDependencies = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'dependencies:' || trimmed == 'dev_dependencies:') {
        inDependencies = true;
        continue;
      }
      if (!inDependencies) continue;
      if (line.isNotEmpty && !line.startsWith(' ')) return '';
      if (trimmed.startsWith('$name:')) {
        return trimmed.substring(name.length + 1).trim();
      }
    }
    return '';
  }

  Map<String, String> pinnedDependencies() {
    final pinned = <String, String>{};
    var inDependencies = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'dependencies:' || trimmed == 'dev_dependencies:') {
        inDependencies = true;
        continue;
      }
      if (!inDependencies) continue;
      if (line.isNotEmpty && !line.startsWith(' ')) {
        inDependencies = false;
        continue;
      }
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final separator = trimmed.indexOf(':');
      if (separator <= 0) continue;
      final version = trimmed.substring(separator + 1).trim();
      if (version.isEmpty) continue;
      pinned[trimmed.substring(0, separator)] = version;
    }
    return pinned;
  }

  test('flutter_soloud 固定为 5.3.0', () {
    expect(versionOf('flutter_soloud'), '5.3.0');
  });

  test('所有依赖使用固定版本号，不使用范围约束', () {
    final pinned = pinnedDependencies();
    expect(pinned, isNotEmpty);
    final ranged = <String>[
      for (final entry in pinned.entries)
        if (RegExp(r'[\^~*<>]').hasMatch(entry.value)) '${entry.key}: ${entry.value}',
    ];
    expect(ranged, isEmpty, reason: '依赖必须写死版本号: $ranged');
  });

  test('关闭 Xiph 预编译库下载，构建不额外拉取 Ogg/Opus 库', () {
    final hooksIndex = lines.indexWhere((l) => l.trim() == 'hooks:');
    expect(hooksIndex, greaterThan(0));
    expect(lines.sublist(hooksIndex).join('\n'), contains('no_xiph_libs: true'));
  });
}
