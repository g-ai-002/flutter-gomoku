import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'components/board_grid_component.dart';
import 'components/gomoku_particles_component.dart';
import 'components/stone_layer_component.dart';
import 'components/win_line_component.dart';
import 'gomoku_board_geometry.dart';
import 'gomoku_board_source.dart';
import 'gomoku_palette.dart';
import 'gomoku_world.dart';
import 'input/board_input_component.dart';

/// 基于 Flame 的五子棋对局 / 回放。
///
/// 棋盘、棋子、连线与粒子由组件渲染；对局时 [controller] 负责规则与 AI，
/// 回放时只提供只读的 [source]，通过 [onAutoStep] 推进。
class GomokuGame extends FlameGame<GomokuWorld> with KeyboardEvents {
  GomokuGame({
    required this.source,
    required this.palette,
    this.controller,
    this.onCellTap,
    this.onAutoStep,
  }) : super(
          world: GomokuWorld(),
          camera: CameraComponent.withFixedResolution(
            width: GomokuBoardGeometry.worldSize,
            height: GomokuBoardGeometry.worldSize,
          ),
        );

  static const String gameOverOverlayId = 'gomokuGameOver';

  final GomokuBoardSource source;
  final GomokuPalette palette;
  final GameProvider? controller;
  final void Function(Position position)? onCellTap;
  final VoidCallback? onAutoStep;

  bool autoPlay = false;
  double autoPlayInterval = 0.5;

  final Set<String> _activeOverlays = {};
  late final GomokuParticlesComponent _particles;

  double _autoElapsed = 0;
  double _aiElapsed = 0;
  int _lastHistory = 0;

  @override
  Color backgroundColor() => palette.surfaceColor;

  @override
  Future<void> onLoad() async {
    _particles = GomokuParticlesComponent(
      source: source,
      palette: palette,
      priority: 3,
    );
    await world.addAll([
      BoardGridComponent(source: source, palette: palette, priority: 0),
      StoneLayerComponent(source: source, palette: palette, priority: 1),
      WinLineComponent(source: source, palette: palette, priority: 2),
      _particles,
      if (onCellTap != null)
        BoardInputComponent(
          source: source,
          palette: palette,
          onTap: onCellTap!,
          priority: 10,
        ),
    ]);

    const half = GomokuBoardGeometry.worldSize / 2;
    camera.viewfinder.position = Vector2(half, half);
    camera.viewfinder.zoom = 1;

    if (controller != null) {
      _lastHistory = controller!.history.length;
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final game = controller;
    if (game == null) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyR:
        game.restart();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyU:
        game.undo();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  void update(double dt) {
    final game = controller;
    if (game != null) {
      _driveAi(game, dt);
      _syncParticles(game);
      _syncGameOverOverlay();
    }

    if (autoPlay) {
      _autoElapsed += dt;
      if (_autoElapsed >= autoPlayInterval) {
        _autoElapsed = 0;
        onAutoStep?.call();
      }
    }

    super.update(dt);
  }

  void _driveAi(GameProvider game, double dt) {
    if (!game.aiThinking) {
      _aiElapsed = 0;
      return;
    }
    _aiElapsed += dt;
    if (_aiElapsed >= AppConstants.aiMoveDelayMs / 1000) {
      _aiElapsed = 0;
      game.resolveAiMove();
    }
  }

  void _syncParticles(GameProvider game) {
    final length = game.history.length;
    if (length > _lastHistory) {
      final last = game.lastMove;
      if (last != null) {
        _particles.burst(last);
      }
      final start = game.winStart;
      final end = game.winEnd;
      if (start != null && end != null) {
        _particles.burstLine(start, end);
      }
    } else if (length < _lastHistory) {
      _particles.clear();
    }
    _lastHistory = length;
  }

  void _syncGameOverOverlay() {
    final visible = !source.isPlaying;
    if (visible && !_activeOverlays.contains(gameOverOverlayId)) {
      overlays.add(gameOverOverlayId, priority: 20);
      _activeOverlays.add(gameOverOverlayId);
    } else if (!visible && _activeOverlays.contains(gameOverOverlayId)) {
      overlays.remove(gameOverOverlayId);
      _activeOverlays.remove(gameOverOverlayId);
    }
  }
}
