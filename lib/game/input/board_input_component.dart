import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../models/game_state.dart';
import '../components/board_layer_component.dart';

/// 棋盘输入层：点击吸附到最近交叉点落子。
class BoardInputComponent extends BoardLayerComponent with TapCallbacks {
  BoardInputComponent({required super.provider, super.priority});

  @override
  void onTapUp(TapUpEvent event) {
    if (provider.state.status != GameStatus.playing) {
      return;
    }
    final point = ui.Offset(event.localPosition.x, event.localPosition.y);
    final position = geometry.positionAt(point);
    if (position != null) {
      provider.placeStone(position.row, position.col);
    }
  }
}
