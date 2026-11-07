import 'dart:math' as math;
import 'dart:typed_data';

/// 音效采样率：短促提示音用 22.05 kHz 足够，数据量约为 44.1 kHz 的一半。
const int kSynthSampleRate = 22050;

/// 单枚乐音：正弦基频叠加二、三次谐波，可混入少量噪声模拟木质敲击。
class SynthNote {
  const SynthNote({
    required this.frequency,
    required this.start,
    required this.duration,
    this.gain = 0.5,
    this.noise = 0,
    this.slide = 0,
  });

  /// 基频（Hz）。
  final double frequency;

  /// 相对整段音效的起始时间（秒）。
  final double start;

  /// 持续时长（秒）。
  final double duration;

  /// 音量，0 到 1。
  final double gain;

  /// 混入的噪声比例，用于表现撞击感。
  final double noise;

  /// 频率滑动比例，-0.5 表示结束时降八度的一半。
  final double slide;
}

/// 纯 Dart 音效合成：把若干乐音渲染成 16 位单声道 WAV 字节。
Uint8List synthesizeWav(
  List<SynthNote> notes, {
  int sampleRate = kSynthSampleRate,
}) {
  const tailSeconds = 0.04;
  final seconds = notes.fold<double>(
    0,
    (longest, note) => math.max(longest, note.start + note.duration),
  );
  final totalSamples = ((seconds + tailSeconds) * sampleRate).round();
  final mix = Float64List(totalSamples);
  final random = math.Random(20261107);

  for (final note in notes) {
    final offset = (note.start * sampleRate).round();
    final count = (note.duration * sampleRate).round();
    final attack = math.max(1, (0.003 * sampleRate).round());
    final release = math.max(1, (0.006 * sampleRate).round());
    final gain = note.gain / 1.44;
    var phase = 0.0;
    for (var i = 0; i < count; i++) {
      final index = offset + i;
      if (index >= totalSamples) break;
      final progress = i / count;
      final envelope =
          math.min(1, i / attack) *
          math.min(1, (count - i) / release) *
          math.exp(-3.2 * progress);
      final frequency = note.frequency * (1 + note.slide * progress);
      phase += 2 * math.pi * frequency / sampleRate;
      final tone =
          math.sin(phase) +
          0.32 * math.sin(2 * phase) +
          0.12 * math.sin(3 * phase);
      final hit = note.noise * (random.nextDouble() * 2 - 1);
      mix[index] += envelope * (tone * gain + hit);
    }
  }

  return encodePcm(mix, sampleRate);
}

class _PluckNote {
  const _PluckNote({
    required this.start,
    required this.frequency,
    required this.duration,
    this.gain = 0.4,
    this.damp = 1.2,
  });

  final double start;
  final double frequency;
  final double duration;
  final double gain;
  final double damp;
}

/// 背景音乐采样率与循环长度：轻快五声音阶，16 秒一循环。
const int kMusicSampleRate = 16000;
const double kMusicLoopSeconds = 16;

/// C 宫五声音阶旋律 + 低音铺底，全部为相对循环起点的秒数。
const List<_PluckNote> _musicNotes = [
  _PluckNote(start: 0, frequency: 130.81, duration: 3.8, gain: 0.26, damp: 0.7),
  _PluckNote(start: 4, frequency: 146.83, duration: 3.8, gain: 0.24, damp: 0.7),
  _PluckNote(start: 8, frequency: 130.81, duration: 3.8, gain: 0.26, damp: 0.7),
  _PluckNote(start: 12, frequency: 98.00, duration: 3.8, gain: 0.28, damp: 0.7),
  _PluckNote(start: 0.0, frequency: 392.00, duration: 0.9, gain: 0.46),
  _PluckNote(start: 0.5, frequency: 523.25, duration: 0.9, gain: 0.5),
  _PluckNote(start: 1.0, frequency: 587.33, duration: 0.9, gain: 0.5),
  _PluckNote(start: 1.5, frequency: 659.25, duration: 1.1, gain: 0.5),
  _PluckNote(start: 2.3, frequency: 587.33, duration: 0.9, gain: 0.42),
  _PluckNote(start: 3.1, frequency: 523.25, duration: 1.1, gain: 0.46),
  _PluckNote(start: 4.0, frequency: 440.00, duration: 0.9, gain: 0.44),
  _PluckNote(start: 4.6, frequency: 523.25, duration: 0.9, gain: 0.5),
  _PluckNote(start: 5.2, frequency: 587.33, duration: 0.9, gain: 0.5),
  _PluckNote(start: 5.8, frequency: 659.25, duration: 1.1, gain: 0.5),
  _PluckNote(start: 6.6, frequency: 783.99, duration: 1.2, gain: 0.48),
  _PluckNote(start: 7.4, frequency: 659.25, duration: 0.9, gain: 0.44),
  _PluckNote(start: 8.2, frequency: 587.33, duration: 0.9, gain: 0.46),
  _PluckNote(start: 8.8, frequency: 523.25, duration: 0.9, gain: 0.48),
  _PluckNote(start: 9.4, frequency: 440.00, duration: 0.9, gain: 0.44),
  _PluckNote(start: 10.0, frequency: 523.25, duration: 1.0, gain: 0.5),
  _PluckNote(start: 10.9, frequency: 587.33, duration: 0.9, gain: 0.48),
  _PluckNote(start: 11.6, frequency: 659.25, duration: 1.2, gain: 0.5),
  _PluckNote(start: 12.5, frequency: 587.33, duration: 0.9, gain: 0.46),
  _PluckNote(start: 13.1, frequency: 523.25, duration: 0.9, gain: 0.48),
  _PluckNote(start: 13.7, frequency: 392.00, duration: 1.1, gain: 0.46),
  _PluckNote(start: 14.6, frequency: 440.00, duration: 0.9, gain: 0.42),
  _PluckNote(start: 15.2, frequency: 523.25, duration: 0.8, gain: 0.5),
  // 轻巧的打击垫，让循环更有推进感。
  _PluckNote(start: 2.0, frequency: 196.00, duration: 0.2, gain: 0.16, damp: 4),
  _PluckNote(start: 6.0, frequency: 196.00, duration: 0.2, gain: 0.16, damp: 4),
  _PluckNote(
    start: 10.0,
    frequency: 220.00,
    duration: 0.2,
    gain: 0.16,
    damp: 4,
  ),
  _PluckNote(
    start: 14.0,
    frequency: 174.61,
    duration: 0.2,
    gain: 0.16,
    damp: 4,
  ),
];

/// 合成背景音乐：拨弦叠加低音，首尾淡入淡出后无缝循环。
Uint8List synthesizeMusicWav({int sampleRate = kMusicSampleRate}) {
  final totalSamples = (kMusicLoopSeconds * sampleRate).round();
  final mix = Float64List(totalSamples);
  final random = math.Random(20261108);
  for (final note in _musicNotes) {
    final offset = (note.start * sampleRate).round();
    final count = math.min(
      (note.duration * sampleRate).round(),
      totalSamples - offset,
    );
    final attack = math.max(1, (0.004 * sampleRate).round());
    for (var i = 0; i < count; i++) {
      final time = i / sampleRate;
      final envelope = math.min(1, i / attack) * math.exp(-note.damp * time);
      final phase = 2 * math.pi * note.frequency * time;
      final tone =
          math.sin(phase) +
          0.34 * math.sin(2.002 * phase) +
          0.14 * math.sin(3.006 * phase) +
          0.05 * math.sin(4.011 * phase);
      final pick = (random.nextDouble() * 2 - 1) * 0.16 * math.exp(-70 * time);
      mix[offset + i] += envelope * note.gain * (tone * 0.42 + pick);
    }
  }

  var peak = 0.0;
  for (final value in mix) {
    final magnitude = value.abs();
    if (magnitude > peak) peak = magnitude;
  }
  final scale = peak > 0 ? 0.78 / peak : 1.0;
  final edge = (0.025 * sampleRate).round();
  for (var i = 0; i < totalSamples; i++) {
    final fadeIn = i < edge ? i / edge : 1.0;
    final fadeOut = i >= totalSamples - edge ? (totalSamples - i) / edge : 1.0;
    mix[i] *= scale * fadeIn * fadeOut;
  }
  return encodePcm(mix, sampleRate);
}

/// 把 [-1,1] 的浮点混音编码为 16 位单声道 WAV。
Uint8List encodePcm(Float64List mix, int sampleRate) {
  final totalSamples = mix.length;
  final data = ByteData(44 + totalSamples * 2);
  _writeAscii(data, 0, 'RIFF');
  data.setUint32(4, 36 + totalSamples * 2, Endian.little);
  _writeAscii(data, 8, 'WAVE');
  _writeAscii(data, 12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  _writeAscii(data, 36, 'data');
  data.setUint32(40, totalSamples * 2, Endian.little);

  for (var i = 0; i < totalSamples; i++) {
    final sample = (mix[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, sample, Endian.little);
  }
  return data.buffer.asUint8List();
}

void _writeAscii(ByteData data, int offset, String text) {
  for (var i = 0; i < text.length; i++) {
    data.setUint8(offset + i, text.codeUnitAt(i));
  }
}
