import 'package:flutter/material.dart';
import '../models/board.dart';

class BoardPainter extends CustomPainter {
  final Board board;
  final List<List<int>> legalMoves;

  // アニメーション用
  final Map<String, ({int fromColor, int toColor})> flippingStones;
  final double animationProgress; // 0.0 → 1.0
  final List<int>? placedStone;   // [row, col, color]

  BoardPainter({
    required this.board,
    required this.legalMoves,
    this.flippingStones = const {},
    this.animationProgress = 1.0,
    this.placedStone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 8;

    // 背景（緑）
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF2E7D32),
    );

    // グリッド線
    final gridPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
    for (int i = 0; i <= 8; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), gridPaint);
    }

    // 合法手ヒント
    final hintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    for (final move in legalMoves) {
      canvas.drawCircle(
        Offset((move[1] + 0.5) * cellSize, (move[0] + 0.5) * cellSize),
        cellSize * 0.15,
        hintPaint,
      );
    }

    // 石（通常 + アニメーション）
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final key = '$r,$c';
        final center = Offset((c + 0.5) * cellSize, (r + 0.5) * cellSize);
        final radius = cellSize * 0.42;

        if (flippingStones.containsKey(key)) {
          // ひっくり返るアニメーション
          final flip = flippingStones[key]!;
          final scaleX = animationProgress < 0.5
              ? 1.0 - animationProgress * 2       // 1→0（縮む）
              : (animationProgress - 0.5) * 2;    // 0→1（広がる）
          final color = animationProgress < 0.5 ? flip.fromColor : flip.toColor;
          _drawStoneOval(canvas, center, radius, color, scaleX);
        } else if (board.cells[r][c] != Board.empty) {
          // 通常の石
          _drawStone(canvas, center, radius, board.cells[r][c]);
        }
      }
    }

    // 置いた石のポップインアニメーション
    if (placedStone != null) {
      final r = placedStone![0], c = placedStone![1], color = placedStone![2];
      final center = Offset((c + 0.5) * cellSize, (r + 0.5) * cellSize);
      final scale = Curves.easeOut.transform(animationProgress.clamp(0.0, 1.0));
      _drawStone(canvas, center, cellSize * 0.42 * scale, color);
    }
  }

  void _drawStone(Canvas canvas, Offset center, double radius, int color) {
    canvas.drawCircle(
      center + const Offset(2, 2),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color == Board.black ? Colors.black : Colors.white,
    );
    if (color == Board.white) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawStoneOval(Canvas canvas, Offset center, double radius, int color, double scaleX) {
    if (scaleX.abs() < 0.01) return;
    final width = radius * 2 * scaleX;
    final height = radius * 2;
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(2, 2), width: width, height: height),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: height),
      Paint()..color = color == Board.black ? Colors.black : Colors.white,
    );
    if (color == Board.white) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: width, height: height),
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;
}
