import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/logic_rate.dart';
import '../utils/constants.dart';

/// 轻量偏好存储：写入失败时静默忽略，不影响游戏主流程。
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> get instance async {
    if (_instance != null) return _instance!;
    final service = StorageService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;
    return service;
  }

  /// 仅供测试：清空单例，配合 SharedPreferences 的 mock 数据使用。
  static void resetForTests() => _instance = null;

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) throw StateError('StorageService 尚未初始化');
    return prefs;
  }

  Future<void> _write(
    Future<bool> Function(SharedPreferences prefs) action,
  ) async {
    try {
      await action(_p);
    } catch (_) {}
  }

  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyDarkMode, value));

  bool get soundEnabled => _p.getBool(AppConstants.prefKeySound) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeySound, value));

  bool get musicEnabled => _p.getBool(AppConstants.prefKeyMusic) ?? true;
  Future<void> setMusicEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyMusic, value));

  bool get hapticsEnabled => _p.getBool(AppConstants.prefKeyHaptics) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyHaptics, value));

  LogicRate get logicRate =>
      LogicRate.byName(_p.getString(AppConstants.prefKeyLogicRate));
  Future<void> setLogicRate(LogicRate value) =>
      _write((p) => p.setString(AppConstants.prefKeyLogicRate, value.name));

  /// 关卡星级：`{关卡号: 星数}`，未通关的关卡不在表中。
  Map<int, int> get stars {
    final raw = _p.getString(AppConstants.prefKeyStars);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (int.tryParse('${entry.key}') != null && entry.value is int)
            int.parse('${entry.key}'): entry.value as int,
      };
    } catch (_) {
      return const {};
    }
  }

  int get unlockedLevel => _p.getInt(AppConstants.prefKeyUnlocked) ?? 1;

  Future<void> recordStars(int levelId, int starCount) => _write((p) async {
    final current = stars;
    final best = current[levelId] ?? 0;
    if (starCount > best) {
      final next = {...current, levelId: starCount};
      await p.setString(
        AppConstants.prefKeyStars,
        jsonEncode(next.map((key, value) => MapEntry('$key', value))),
      );
    }
    if (levelId + 1 > (p.getInt(AppConstants.prefKeyUnlocked) ?? 1)) {
      await p.setInt(AppConstants.prefKeyUnlocked, levelId + 1);
    }
    return true;
  });
}
