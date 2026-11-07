import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Gradient;

import '../game/engine/defense_engine.dart';
import '../game/logic_rate.dart';
import '../services/sound_service.dart';
import '../theme/level_theme.dart';
import '../utils/constants.dart';
import 'art_utils.dart';
import 'board_actor_layer.dart';
import 'board_event_feedback.dart';
import 'board_ground.dart';
import 'board_layout.dart';

/// 战场编排：按固定步长推进引擎，协调地面、角色与事件反馈的绘制。
class BoardComponent extends PositionComponent with TapCallbacks {
  BoardComponent({
    required this.engine,
    required this.logicRate,
    required this.pausedNotifier,
    required this.speed,
  }) : _clock = FixedStepClock(logicRate.step) {
    _ground = BoardGround(engine: engine);
    _actors = BoardActorLayer(engine: engine);
  }

  final DefenseEngine engine;
  final LogicRate logicRate;
  final ValueNotifier<bool> pausedNotifier;
  final ValueNotifier<double> speed;

  final FixedStepClock _clock;
  final BoardEventFeedback _feedback = BoardEventFeedback();
  late final BoardGround _ground;
  late final BoardActorLayer _actors;
  late final void Function(double) _stepEngine = engine.update;
  double _visualTime = 0;

  BoardLayout? _layout;
  Size _layoutSize = Size.zero;
  RRect _frame = _boardClip.shift(Offset.zero);
  RRect _frameInner = _boardClip.shift(Offset.zero).deflate(4);

  static final RRect _boardClip = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, kDesignWidth, kDesignHeight),
    const Radius.circular(28),
  );

  /// 布局只与视口尺寸有关，渲染与点击共用同一份结果。
  BoardLayout _layoutFor() {
    final view = Size(size.x, size.y);
    if (_layout == null || _layoutSize != view) {
      _layout = BoardLayout.resolve(view);
      _layoutSize = view;
      _frame = _boardClip.shift(_layout!.origin);
      _frameInner = _frame.deflate(4);
    }
    return _layout!;
  }

  /// 静态图层被录制的次数，供性能回归测试确认缓存生效。
  @visibleForTesting
  int get staticLayerBuilds => _ground.staticLayerBuilds;

  /// 屏幕背景图层被录制的次数，尺寸不变时应保持为 1。
  @visibleForTesting
  int get backdropBuilds => _ground.backdropBuilds;

  @override
  void update(double dt) {
    super.update(dt);
    _visualTime += dt;
    if (pausedNotifier.value) return;
    _clock.advance(dt * speed.value, _stepEngine);
    _feedback.consume(engine);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final layout = _layoutFor();
    final design = layout.toDesign(
      Offset(event.localPosition.x, event.localPosition.y),
    );
    if (!layout.contains(design)) return;
    final slot = layout.slotAt(engine.slotPositions, design);
    if (slot == null) {
      engine.clearSelection();
      return;
    }
    final tower = engine.towerAt(slot);
    if (tower != null) {
      engine.selectSlot(slot);
      SoundService.play(SoundFx.tap);
      return;
    }
    final kind = engine.armedKind;
    if (kind != null) {
      engine.build(slot, kind);
    } else {
      engine.selectSlot(slot);
      SoundService.play(SoundFx.tap);
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final layout = _layoutFor();
    _ground.paintBackdrop(canvas, Size(size.x, size.y), layout);

    canvas.save();
    canvas.translate(layout.origin.dx, layout.origin.dy);
    canvas.scale(layout.scale);
    canvas.clipRRect(_boardClip);

    _ground.paintStatic(canvas);
    _ground.paintStartGlow(canvas, _visualTime);
    _actors.paintFogMist(canvas, _visualTime);
    _actors.paintCarrotTarget(canvas);
    _actors.paintPads(canvas, _visualTime);
    _actors.paintRange(canvas);
    _actors.paintTowers(canvas);
    _actors.paintEnemies(canvas, _visualTime, _clock.alpha);
    _actors.paintProjectiles(canvas);
    _actors.paintEffects(canvas, _visualTime);
    _actors.paintFloaters(canvas);
    canvas.restore();

    final palette = paletteOf(engine.level.theme);
    canvas.drawRRect(
      _frame,
      dynStroke(palette.frame.withValues(alpha: 0.55), 3),
    );
    canvas.drawRRect(
      _frameInner,
      dynStroke(Colors.white.withValues(alpha: 0.18), 1.2),
    );
  }

  @override
  void onRemove() {
    _ground.dispose();
    _actors.dispose();
    super.onRemove();
  }
}
