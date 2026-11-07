import 'package:flutter/foundation.dart';

import '../game/levels.dart';
import '../services/storage_service.dart';

/// 关卡进度：星级与解锁状态，通关后立即持久化并通知界面。
class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._storage) : _stars = Map.of(_storage.stars);

  final StorageService _storage;
  Map<int, int> _stars;

  Map<int, int> get stars => Map.unmodifiable(_stars);
  int get totalStars => _stars.values.fold(0, (sum, value) => sum + value);
  int get maxStars => kLevels.length * 3;
  int get unlockedLevel => _storage.unlockedLevel;

  bool isUnlocked(int levelId) => levelId <= _storage.unlockedLevel;

  int starsFor(int levelId) => _stars[levelId] ?? 0;

  Future<void> record(int levelId, int starCount) async {
    await _storage.recordStars(levelId, starCount);
    _stars = Map.of(_storage.stars);
    notifyListeners();
  }
}
