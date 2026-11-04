import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../flame/gomoku_game.dart';

/// 棋盘舞台：统一圆角、投影与 Flame 容器，对局、残局与复盘页共用。
///
/// 棋盘保持 1:1 的宽高比，按可用空间取最大尺寸；组件自带重绘边界，
/// 状态栏或操作区变化时不会触发棋盘重绘。
class BoardStage extends StatelessWidget {
  const BoardStage({
    super.key,
    required this.game,
    required this.gameKey,
    this.maxWidth = 680,
  });

  final GomokuGame game;
  final Key gameKey;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          var width = math.min(constraints.maxWidth, maxWidth);
          var height = width;
          if (height > constraints.maxHeight) {
            height = constraints.maxHeight;
            width = height;
          }
          return Center(
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: GameWidget<GomokuGame>(key: gameKey, game: game),
              ),
            ),
          );
        },
      ),
    );
  }
}
