import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'log_service.dart';
import 'tone_synth.dart';

/// 游戏音效类型。
enum SoundFx {
  tap,
  build,
  upgrade,
  sell,
  arrow,
  cannon,
  frost,
  poison,
  lightning,
  hit,
  leak,
  waveStart,
  waveClear,
  victory,
  defeat,
  coin,
}

/// 音效与触感反馈。
///
/// 音效由 [synthesizeWav] 在运行时合成，不随包携带音频文件；合成好的
/// WAV 交给 flutter_soloud 的内存音源播放，Android、Windows 与 Web 共用
/// 同一套实现，Web 的自动播放限制会在用户首次操作页面后解除。
class SoundService {
  SoundService._();

  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// 测试注入的音频出口，非空时不再触碰平台播放器。
  @visibleForTesting
  static void Function(SoundFx fx)? sink;

  static final Map<SoundFx, AudioSource> _sources = {};
  static final Map<SoundFx, Uint8List> _clips = {};
  static final Map<SoundFx, DateTime> _lastPlayed = {};
  static Future<void>? _loading;
  static bool _loadFailed = false;

  /// 各音效的最小触发间隔，避免密集射击时音轨堆叠。
  static const Map<SoundFx, int> _minGapMs = {
    SoundFx.arrow: 70,
    SoundFx.cannon: 110,
    SoundFx.frost: 90,
    SoundFx.poison: 110,
    SoundFx.lightning: 120,
    SoundFx.hit: 60,
    SoundFx.coin: 80,
  };

  static const Map<SoundFx, List<SynthNote>> _presets = {
    SoundFx.tap: [
      SynthNote(frequency: 980, start: 0, duration: 0.04, gain: 0.4),
    ],
    SoundFx.build: [
      SynthNote(
        frequency: 330,
        start: 0,
        duration: 0.09,
        gain: 0.6,
        noise: 0.3,
      ),
      SynthNote(frequency: 494, start: 0.07, duration: 0.12, gain: 0.5),
      SynthNote(frequency: 659, start: 0.14, duration: 0.14, gain: 0.4),
    ],
    SoundFx.upgrade: [
      SynthNote(frequency: 523, start: 0, duration: 0.08, gain: 0.5),
      SynthNote(frequency: 659, start: 0.07, duration: 0.08, gain: 0.5),
      SynthNote(frequency: 784, start: 0.14, duration: 0.16, gain: 0.55),
    ],
    SoundFx.sell: [
      SynthNote(frequency: 523, start: 0, duration: 0.08, gain: 0.45),
      SynthNote(frequency: 392, start: 0.08, duration: 0.15, gain: 0.4),
    ],
    SoundFx.arrow: [
      SynthNote(
        frequency: 1500,
        start: 0,
        duration: 0.045,
        gain: 0.28,
        noise: 0.35,
        slide: -0.3,
      ),
    ],
    SoundFx.cannon: [
      SynthNote(
        frequency: 170,
        start: 0,
        duration: 0.16,
        gain: 0.7,
        noise: 0.4,
      ),
      SynthNote(frequency: 90, start: 0, duration: 0.22, gain: 0.6, noise: 0.2),
      SynthNote(
        frequency: 420,
        start: 0.02,
        duration: 0.09,
        gain: 0.3,
        noise: 0.5,
      ),
    ],
    SoundFx.frost: [
      SynthNote(frequency: 1250, start: 0, duration: 0.07, gain: 0.35),
      SynthNote(frequency: 1860, start: 0.03, duration: 0.1, gain: 0.28),
      SynthNote(frequency: 980, start: 0.05, duration: 0.12, gain: 0.3),
    ],
    SoundFx.poison: [
      SynthNote(
        frequency: 420,
        start: 0,
        duration: 0.09,
        gain: 0.4,
        noise: 0.4,
        slide: -0.35,
      ),
      SynthNote(frequency: 300, start: 0.06, duration: 0.14, gain: 0.32),
    ],
    SoundFx.lightning: [
      SynthNote(
        frequency: 760,
        start: 0,
        duration: 0.14,
        gain: 0.5,
        noise: 0.75,
      ),
      SynthNote(
        frequency: 1520,
        start: 0.03,
        duration: 0.1,
        gain: 0.35,
        noise: 0.5,
      ),
      SynthNote(
        frequency: 380,
        start: 0.08,
        duration: 0.16,
        gain: 0.4,
        noise: 0.6,
      ),
    ],
    SoundFx.hit: [
      SynthNote(
        frequency: 320,
        start: 0,
        duration: 0.06,
        gain: 0.3,
        noise: 0.55,
      ),
    ],
    SoundFx.leak: [
      SynthNote(frequency: 300, start: 0, duration: 0.14, gain: 0.55),
      SynthNote(frequency: 220, start: 0.1, duration: 0.2, gain: 0.5),
    ],
    SoundFx.waveStart: [
      SynthNote(frequency: 392, start: 0, duration: 0.12, gain: 0.5),
      SynthNote(frequency: 523, start: 0.11, duration: 0.12, gain: 0.5),
      SynthNote(frequency: 659, start: 0.22, duration: 0.2, gain: 0.55),
    ],
    SoundFx.waveClear: [
      SynthNote(frequency: 523, start: 0, duration: 0.1, gain: 0.45),
      SynthNote(frequency: 659, start: 0.09, duration: 0.1, gain: 0.45),
      SynthNote(frequency: 784, start: 0.18, duration: 0.18, gain: 0.5),
    ],
    SoundFx.victory: [
      SynthNote(frequency: 523, start: 0, duration: 0.14, gain: 0.5),
      SynthNote(frequency: 659, start: 0.12, duration: 0.14, gain: 0.5),
      SynthNote(frequency: 784, start: 0.24, duration: 0.16, gain: 0.55),
      SynthNote(frequency: 1047, start: 0.4, duration: 0.38, gain: 0.55),
    ],
    SoundFx.defeat: [
      SynthNote(frequency: 392, start: 0, duration: 0.2, gain: 0.5),
      SynthNote(frequency: 330, start: 0.18, duration: 0.22, gain: 0.5),
      SynthNote(frequency: 262, start: 0.38, duration: 0.4, gain: 0.55),
    ],
    SoundFx.coin: [
      SynthNote(frequency: 1320, start: 0, duration: 0.05, gain: 0.32),
      SynthNote(frequency: 1760, start: 0.045, duration: 0.09, gain: 0.3),
    ],
  };

  static void configure({required bool sound, required bool haptics}) {
    soundEnabled = sound;
    hapticsEnabled = haptics;
  }

  /// 预合成音效并载入 SoLoud 音源；失败时保持静默，不影响游戏。
  static Future<void> init() => _ensureLoaded();

  static Future<void> _ensureLoaded() {
    if (_loadFailed || _sources.isNotEmpty) return Future.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) await soloud.init();
      // 合成放到后台 isolate，避免启动瞬间占用 UI 线程。
      final clips = await compute(_synthesizeClips, null);
      for (final fx in SoundFx.values) {
        final bytes = clips[fx.name];
        if (bytes == null) continue;
        _clips[fx] = bytes;
        _sources[fx] = await soloud.loadMem('carrotd-${fx.name}.wav', bytes);
      }
    } catch (error) {
      _loadFailed = true;
      _disposeAll();
      debugPrint('[SoundService] 音效初始化失败，已静音: $error');
      LogService.warning('音效初始化失败，已静音: $error');
    }
  }

  /// 某个音效对应的合成音频，供测试校验配方。
  @visibleForTesting
  static Uint8List clipOf(SoundFx fx) =>
      _clips.putIfAbsent(fx, () => synthesizeWav(_presets[fx]!));

  static void play(SoundFx fx) {
    if (soundEnabled) {
      final target = sink;
      if (target != null) {
        target(fx);
      } else if (_shouldPlay(fx)) {
        unawaited(_play(fx));
      }
    }
    if (hapticsEnabled) _haptic(fx);
  }

  static bool _shouldPlay(SoundFx fx) {
    final gap = _minGapMs[fx] ?? 0;
    if (gap == 0) return true;
    final now = DateTime.now();
    final last = _lastPlayed[fx];
    if (last != null && now.difference(last).inMilliseconds < gap) {
      return false;
    }
    _lastPlayed[fx] = now;
    return true;
  }

  static Future<void> _play(SoundFx fx) async {
    try {
      await _ensureLoaded();
      final source = _sources[fx];
      if (source == null) return;
      final soloud = SoLoud.instance;
      if (fx == SoundFx.arrow ||
          fx == SoundFx.cannon ||
          fx == SoundFx.frost ||
          fx == SoundFx.poison ||
          fx == SoundFx.lightning) {
        soloud.stopAudioSource(source);
      }
      soloud.play(source);
    } catch (error) {
      debugPrint('[SoundService] 播放失败: $error');
    }
  }

  static void _haptic(SoundFx fx) {
    switch (fx) {
      case SoundFx.build:
      case SoundFx.upgrade:
        HapticFeedback.lightImpact();
        break;
      case SoundFx.leak:
      case SoundFx.defeat:
        HapticFeedback.heavyImpact();
        break;
      case SoundFx.victory:
        HapticFeedback.vibrate();
        break;
      case SoundFx.tap:
      case SoundFx.sell:
        HapticFeedback.selectionClick();
        break;
      default:
        break;
    }
  }

  static void _disposeAll() {
    final sources = _sources.values.toList();
    _sources.clear();
    for (final source in sources) {
      unawaited(_dispose(source));
    }
  }

  static Future<void> _dispose(AudioSource source) async {
    try {
      await SoLoud.instance.disposeSource(source);
    } catch (_) {
      // 音源已失效时无需再处理。
    }
  }

  @visibleForTesting
  static void reset() {
    sink = null;
    _disposeAll();
    _clips.clear();
    _lastPlayed.clear();
    _loading = null;
    _loadFailed = false;
    soundEnabled = true;
    hapticsEnabled = true;
  }
}

Map<String, Uint8List> _synthesizeClips(Object? _) => {
  for (final fx in SoundFx.values)
    fx.name: synthesizeWav(SoundService._presets[fx]!),
};
