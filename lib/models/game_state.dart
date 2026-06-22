/// 游戏模式
enum GameMode {
  pvp,
  pve;

  String get label {
    switch (this) {
      case GameMode.pvp:
        return '双人对弈';
      case GameMode.pve:
        return '人机对弈';
    }
  }
}

/// 棋子颜色
enum StoneColor {
  black,
  white;

  StoneColor get opponent =>
      this == StoneColor.black ? StoneColor.white : StoneColor.black;

  String get label => this == StoneColor.black ? '黑棋' : '白棋';
}

/// 游戏状态
enum GameStatus {
  playing,
  blackWin,
  whiteWin,
  draw,
}

/// 棋盘上的一个位置
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => row * 31 + col;

  @override
  String toString() => '($row, $col)';
}

/// 一步棋
class Move {
  final Position position;
  final StoneColor color;
  final int stepNumber;

  const Move({
    required this.position,
    required this.color,
    required this.stepNumber,
  });
}

/// 游戏状态数据
class GameState {
  final int boardSize;
  final List<List<StoneColor?>> board;
  final StoneColor currentPlayer;
  final GameStatus status;
  final List<Move> history;
  final Position? lastMove;
  final Position? winStart;
  final Position? winEnd;

  const GameState({
    required this.boardSize,
    required this.board,
    required this.currentPlayer,
    required this.status,
    required this.history,
    this.lastMove,
    this.winStart,
    this.winEnd,
  });

  /// 创建初始状态
  factory GameState.initial(int boardSize) {
    return GameState(
      boardSize: boardSize,
      board: List.generate(
        boardSize,
        (_) => List.filled(boardSize, null),
      ),
      currentPlayer: StoneColor.black,
      status: GameStatus.playing,
      history: const [],
    );
  }

  bool get isGameOver => status != GameStatus.playing;

  GameState copyWith({
    int? boardSize,
    List<List<StoneColor?>>? board,
    StoneColor? currentPlayer,
    GameStatus? status,
    List<Move>? history,
    Position? lastMove,
    Position? winStart,
    Position? winEnd,
  }) {
    return GameState(
      boardSize: boardSize ?? this.boardSize,
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      status: status ?? this.status,
      history: history ?? this.history,
      lastMove: lastMove ?? this.lastMove,
      winStart: winStart,
      winEnd: winEnd,
    );
  }
}
