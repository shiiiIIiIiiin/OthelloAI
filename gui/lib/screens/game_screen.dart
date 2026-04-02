import 'dart:async';
import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/game_config.dart';
import '../engine/engine_process.dart';
import '../widgets/board_painter.dart';

enum _TurnState { humanTurn, engineThinking, gameOver }

class GameScreen extends StatefulWidget {
  final GameConfig config;
  const GameScreen({super.key, required this.config});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

typedef _Snapshot = ({Board board, int color, int timeMs});

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Board _board;
  int _currentColor = Board.black;
  _TurnState _turnState = _TurnState.humanTurn;
  List<List<int>> _legalMoves = [];
  EngineProcess? _blackEngine;
  EngineProcess? _whiteEngine;
  late String _blackName;
  late String _whiteName;
  String _message = '';
  int _currentTimeMs = 0;
  final List<_Snapshot> _history = [];
  late AnimationController _flipController;
  Map<String, ({int fromColor, int toColor})> _flippingStones = {};
  List<int>? _placedStone; // [row, col, color]
  Timer? _countdownTimer;
  int _remainingMs = 0;

  @override
  void initState() {
    super.initState();
    _board = Board();
    _currentTimeMs = widget.config.timePerMove;
    _blackName = widget.config.blackName;
    _whiteName = widget.config.whiteName;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() => setState(() {}));
    _initEngines();
  }

  Future<void> _initEngines() async {
    final config = widget.config;

    if (config.blackPlayer == PlayerType.engine) {
      _blackEngine = EngineProcess();
      await _blackEngine!.start(config.blackEnginePath);
      if (_blackName == '黒') _blackName = await _blackEngine!.getName() ?? _blackName;
      _blackEngine!.sendRule('B', config.timePerMove, config.increment);
    }
    if (config.whitePlayer == PlayerType.engine) {
      _whiteEngine = EngineProcess();
      await _whiteEngine!.start(config.whiteEnginePath);
      if (_whiteName == '白') _whiteName = await _whiteEngine!.getName() ?? _whiteName;
      _whiteEngine!.sendRule('W', config.timePerMove, config.increment);
    }

    _nextTurn();
  }

  void _nextTurn() {
    _legalMoves = _board.legalMoves(_currentColor);

    if (_board.isGameOver()) {
      setState(() => _turnState = _TurnState.gameOver);
      return;
    }

    if (_legalMoves.isEmpty) {
      setState(() => _message = '${_colorName(_currentColor)} はパス');
      Future.delayed(const Duration(milliseconds: 800), () {
        _currentColor = Board.opponent(_currentColor);
        _currentTimeMs = widget.config.timePerMove;
        _nextTurn();
      });
      return;
    }

    final isEngine = _currentColor == Board.black
        ? widget.config.blackPlayer == PlayerType.engine
        : widget.config.whitePlayer == PlayerType.engine;

    setState(() {
      _turnState = isEngine ? _TurnState.engineThinking : _TurnState.humanTurn;
      _message = isEngine
          ? '${_colorName(_currentColor)} が考え中...'
          : '${_colorName(_currentColor)} の番';
    });

    if (isEngine) {
      _startCountdown();
      _askEngine();
    }
  }

  Future<void> _askEngine() async {
    final engine =
        _currentColor == Board.black ? _blackEngine : _whiteEngine;
    if (engine == null) return;

    final colorStr = _currentColor == Board.black ? 'B' : 'W';
    try {
      final response = await engine.sendPosition(
          _board.toProtocolString(), colorStr, _currentTimeMs);

      if (response == 'pass') {
        _applyMove(-1, -1);
      } else if (response.length == 2) {
        final col = response.codeUnitAt(0) - 'a'.codeUnitAt(0);
        final row = int.parse(response[1]) - 1;
        _applyMove(row, col);
      }
    } catch (e) {
      setState(() => _message = 'エンジンエラー: $e');
    }
  }

  void _onTap(Offset localPosition, Size boardSize) {
    if (_turnState != _TurnState.humanTurn) return;
    if (_flipController.isAnimating) return;

    final cellSize = boardSize.width / 8;
    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();

    if (row < 0 || row >= 8 || col < 0 || col >= 8) return;
    if (!_board.isLegal(row, col, _currentColor)) return;

    _applyMove(row, col);
  }

  void _applyMove(int row, int col) {
    _stopCountdown();
    _history.add((board: Board.copy(_board), color: _currentColor, timeMs: _currentTimeMs));

    if (row >= 0 && col >= 0) {
      final flipped = _board.getFlippedStones(row, col, _currentColor);
      setState(() {
        _flippingStones = {
          for (final s in flipped)
            '${s[0]},${s[1]}': (fromColor: _board.cells[s[0]][s[1]], toColor: _currentColor)
        };
        _placedStone = [row, col, _currentColor];
      });
      _flipController.reset();
      _flipController.forward().whenComplete(() {
        setState(() {
          _board.place(row, col, _currentColor);
          _flippingStones = {};
          _placedStone = null;
          _currentColor = Board.opponent(_currentColor);
          _currentTimeMs += widget.config.increment;
        });
        _nextTurn();
      });
    } else {
      setState(() {
        _currentColor = Board.opponent(_currentColor);
        _currentTimeMs = widget.config.timePerMove;
      });
      _nextTurn();
    }
  }

  void _undo() {
    if (_history.isEmpty) return;
    if (_turnState == _TurnState.engineThinking) return;
    _stopCountdown();
    _flipController.stop();
    final snapshot = _history.removeLast();
    setState(() {
      _board = snapshot.board;
      _currentColor = snapshot.color;
      _currentTimeMs = snapshot.timeMs;
      _flippingStones = {};
      _placedStone = null;
      _turnState = _TurnState.humanTurn;
    });
    _nextTurn();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _remainingMs = _currentTimeMs;
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _remainingMs -= 100;
        if (_remainingMs <= 0) {
          _remainingMs = 0;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  String _formatTime(int ms) {
    if (ms <= 0) return '0.0s';
    if (ms >= 60000) {
      final m = ms ~/ 60000;
      final s = (ms % 60000) ~/ 1000;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  String _colorName(int color) => color == Board.black ? '黒' : '白';

  String _resultText() {
    final b = _board.count(Board.black);
    final w = _board.count(Board.white);
    if (b > w) return '黒の勝ち！（$b vs $w）';
    if (w > b) return '白の勝ち！（$w vs $b）';
    return '引き分け（$b vs $w）';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _flipController.dispose();
    _blackEngine?.quit();
    _whiteEngine?.quit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OthelloAI'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // スコア
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreChip(Board.black, _blackName),
              const SizedBox(width: 32),
              _scoreChip(Board.white, _whiteName),
            ],
          ),
          const SizedBox(height: 8),
          // 盤面
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                          constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapDown: (d) => _onTap(d.localPosition, size),
                        child: CustomPaint(
                          size: size,
                          painter: BoardPainter(
                            board: _board,
                            legalMoves: _turnState == _TurnState.humanTurn && !_flipController.isAnimating
                                ? _legalMoves
                                : [],
                            flippingStones: _flippingStones,
                            animationProgress: _flipController.value,
                            placedStone: _placedStone,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // メッセージ＋ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _turnState == _TurnState.gameOver ? _resultText() : _message,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.undo),
                  label: const Text('1手戻す'),
                  onPressed: _history.isEmpty || _turnState == _TurnState.engineThinking || _flipController.isAnimating
                      ? null
                      : _undo,
                ),
                if (_turnState == _TurnState.gameOver) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('設定画面に戻る'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _scoreChip(int color, String name) {
    final isActive =
        _currentColor == color && _turnState != _TurnState.gameOver;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color == Board.black ? Colors.black : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$name: ${_board.count(color)}',
                  style: const TextStyle(fontSize: 16)),
              Visibility(
                visible: isActive && _turnState == _TurnState.engineThinking,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Text(
                  _formatTime(_remainingMs),
                  style: TextStyle(
                    fontSize: 13,
                    color: _remainingMs < 5000 ? Colors.red : Colors.black54,
                    fontWeight: _remainingMs < 5000 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
