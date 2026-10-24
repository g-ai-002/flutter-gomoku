import 'package:flutter/material.dart';

import '../../models/game_state.dart';

/// 对局结束浮层：结果、总步数与再来一局。
class GomokuGameOverOverlay extends StatelessWidget {
  const GomokuGameOverOverlay({
    super.key,
    required this.status,
    required this.moves,
    required this.onRestart,
  });

  final GameStatus status;
  final int moves;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status.label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('共 $moves 手'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay),
                label: const Text('再来一局'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
