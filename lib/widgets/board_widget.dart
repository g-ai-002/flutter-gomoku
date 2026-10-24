import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/gomoku_game.dart';
import '../game/gomoku_palette.dart';
import '../game/overlays/gomoku_game_over_overlay.dart';
import '../providers/game_provider.dart';

/// 棋盘组件：用 [GameWidget] 承载 Flame 对局，并注册结束浮层。
class BoardWidget extends StatefulWidget {
  const BoardWidget({super.key});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  final FocusNode _focusNode = FocusNode();
  GomokuGame? _game;
  GomokuPalette? _palette;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<GameProvider>();
    final themePalette = GomokuPalette.of(Theme.of(context));

    if (_game != null && _palette != null) {
      _palette!.updateFrom(themePalette);
      return;
    }

    _palette = themePalette;
    _game = GomokuGame(
      source: provider,
      palette: themePalette,
      controller: provider,
      onCellTap: (position) => provider.placeStone(position.row, position.col),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final provider = context.read<GameProvider>();
    if (game == null) {
      return const SizedBox.expand();
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _focusNode.requestFocus(),
      child: GameWidget<GomokuGame>(
        game: game,
        focusNode: _focusNode,
        autofocus: false,
        overlayBuilderMap: {
          GomokuGame.gameOverOverlayId: (context, _) => GomokuGameOverOverlay(
                status: provider.state.status,
                moves: provider.history.length,
                onRestart: () {
                  provider.restart();
                  _focusNode.requestFocus();
                },
              ),
        },
      ),
    );
  }
}
