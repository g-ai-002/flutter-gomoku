import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../flame/gomoku_game.dart';

/// 棋盘边长上限：超大屏避免棋盘无限放大，同时控制重绘面积。
const double kBoardMaxSide = 860;

/// 可用空间内棋盘占用的边长：取短边并限幅，页面布局与棋盘共用同一份几何。
double boardSideFor(Size available) =>
    math.min(math.min(available.width, available.height), kBoardMaxSide);

/// 棋盘舞台：统一圆角、投影与 Flame 容器，对局、残局与复盘页共用。
///
/// 棋盘保持 1:1 的宽高比，按可用空间取最大尺寸；棋盘本体自带重绘边界，
/// 状态栏或操作区变化时不会触发棋盘重绘。[overlays] 叠在棋盘上方，
/// 不参与布局计算，提示出现或消失都不会改变棋盘尺寸。
class BoardStage extends StatelessWidget {
  const BoardStage({
    super.key,
    required this.game,
    required this.gameKey,
    this.overlays,
  });

  final GomokuGame game;
  final Key gameKey;

  /// 棋盘浮层，缺省为空；由页面按需传入提示、图例等临时信息。
  final Widget? overlays;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = boardSideFor(constraints.biggest);
        return Center(
          child: Stack(
            children: [
              RepaintBoundary(
                child: Container(
                  width: side,
                  height: side,
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
              ),
              if (overlays != null) Positioned.fill(child: overlays!),
            ],
          ),
        );
      },
    );
  }
}
