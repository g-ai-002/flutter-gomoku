import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/gomoku_game.dart';
import '../providers/game_provider.dart';

/// 棋盘组件：用 [GameWidget] 承载 Flame 对局。
class BoardWidget extends StatefulWidget {
  const BoardWidget({super.key});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  GomokuGame? _game;
  Brightness? _brightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final provider = context.read<GameProvider>();
    if (_game != null &&
        _brightness == brightness &&
        _game!.provider == provider) {
      return;
    }

    _brightness = brightness;
    final colors = Theme.of(context).colorScheme;
    final isDark = brightness == Brightness.dark;
    _game = GomokuGame(
      provider: provider,
      surfaceColor: colors.surface,
      boardColor: isDark ? const Color(0xFF2A2724) : const Color(0xFFE8C99B),
      lineColor: isDark ? const Color(0xFF5A5A5A) : const Color(0xFF8D6E63),
      borderColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFC9A97A),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return const SizedBox.expand();
    }
    return GameWidget<GomokuGame>(game: game);
  }
}
