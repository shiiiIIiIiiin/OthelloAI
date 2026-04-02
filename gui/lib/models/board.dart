class Board {
  static const int empty = 0;
  static const int black = 1;
  static const int white = 2;

  final List<List<int>> cells;

  Board() : cells = List.generate(8, (_) => List.filled(8, empty)) {
    cells[3][3] = white;
    cells[3][4] = black;
    cells[4][3] = black;
    cells[4][4] = white;
  }

  Board.copy(Board other)
      : cells = List.generate(8, (i) => List.from(other.cells[i]));

  static const _dirs = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1],
  ];

  static int opponent(int color) => color == black ? white : black;

  bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  bool _canFlipDir(int row, int col, int color, List<int> dir) {
    final opp = opponent(color);
    int r = row + dir[0], c = col + dir[1];
    if (!_inBounds(r, c) || cells[r][c] != opp) return false;
    r += dir[0];
    c += dir[1];
    while (_inBounds(r, c)) {
      if (cells[r][c] == empty) return false;
      if (cells[r][c] == color) return true;
      r += dir[0];
      c += dir[1];
    }
    return false;
  }

  bool isLegal(int row, int col, int color) {
    if (cells[row][col] != empty) return false;
    return _dirs.any((d) => _canFlipDir(row, col, color, d));
  }

  List<List<int>> legalMoves(int color) {
    final moves = <List<int>>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (isLegal(r, c, color)) moves.add([r, c]);
      }
    }
    return moves;
  }

  void place(int row, int col, int color) {
    cells[row][col] = color;
    for (final dir in _dirs) {
      if (!_canFlipDir(row, col, color, dir)) continue;
      int r = row + dir[0], c = col + dir[1];
      while (cells[r][c] != color) {
        cells[r][c] = color;
        r += dir[0];
        c += dir[1];
      }
    }
  }

  // 指定した手でひっくり返る石の座標一覧を返す
  List<List<int>> getFlippedStones(int row, int col, int color) {
    final flipped = <List<int>>[];
    for (final dir in _dirs) {
      if (!_canFlipDir(row, col, color, dir)) continue;
      int r = row + dir[0], c = col + dir[1];
      while (cells[r][c] != color) {
        flipped.add([r, c]);
        r += dir[0];
        c += dir[1];
      }
    }
    return flipped;
  }

  int count(int color) =>
      cells.expand((r) => r).where((c) => c == color).length;

  bool isGameOver() =>
      legalMoves(black).isEmpty && legalMoves(white).isEmpty;

  // プロトコル用の64文字盤面文字列
  String toProtocolString() {
    return cells.expand((r) => r).map((c) {
      if (c == black) return 'B';
      if (c == white) return 'W';
      return '.';
    }).join();
  }
}
