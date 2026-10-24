import 'dart:ui' as ui;

import 'package:flame/events.dart';

import '../../models/game_state.dart';
import '../components/board_layer_component.dart';

/// 棋盘输入层：点击吸附到最近交叉点，回调由外层决定落子或忽略。
class BoardInputComponent extends BoardLayerComponent with TapCallbacks {
  BoardInputComponent({
    required super.source,
    required super.palette,
    required this.onTap,
    super.priority,
  });

  final void Function(Position position) onTap;

  @override
  void onTapUp(TapUpEvent event) {
    if (!source.isPlaying) {
      return;
    }
    final point = ui.Offset(event.localPosition.x, event.localPosition.y);
    final position = geometry.positionAt(point);
    if (position != null) {
      onTap(position);
    }
  }
}
