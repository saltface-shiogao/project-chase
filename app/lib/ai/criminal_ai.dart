import 'dart:math';

import '../models/ai_difficulty.dart';

/// 犯人（車）に関するAIロジック・移動計算。
/// 人間プレイヤーの移動可否チェック（移動ハイライト・包囲判定）にも
/// 共通で利用される。
class CriminalAi {
  /// 指定マスから移動可能な隣接マス（盤内 かつ 未通過）の一覧を返す
  static List<List<int>> getValidMoves(
    List<List<int>> traceGrid,
    int boardSize,
    int fromRow,
    int fromCol,
  ) {
    final directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1]
    ];
    List<List<int>> moves = [];
    for (var dir in directions) {
      int nr = fromRow + dir[0];
      int nc = fromCol + dir[1];
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
        if (traceGrid[nr][nc] == 0) {
          moves.add([nr, nc]);
        }
      }
    }
    return moves;
  }

  /// 簡易知能：移動候補の中から「移動後にさらに進める逃げ道の数」が
  /// 最も多いものを選ぶ（同点の場合はランダム）。
  /// 移動候補が無い場合はnullを返す（＝包囲状態）。
  static List<int>? decideMove(
    List<List<int>> traceGrid,
    int boardSize,
    int carRow,
    int carCol,
    {AiDifficulty difficulty = AiDifficulty.normal,}
  ) {
    List<List<int>> validMoves = getValidMoves(traceGrid, boardSize, carRow, carCol);
    if (validMoves.isEmpty) {
      return null;
    }

    final random = Random();
    if (difficulty == AiDifficulty.easy) {
      return validMoves[random.nextInt(validMoves.length)];
    }

    int bestEscapeCount = -1;
    List<List<int>> bestMoves = [];
    for (var mv in validMoves) {
      int escapeCount = getValidMoves(traceGrid, boardSize, mv[0], mv[1]).length;
      if (difficulty == AiDifficulty.hard) {
        escapeCount = escapeCount * 100 + _reachableCellCount(traceGrid, boardSize, mv[0], mv[1]);
      }
      if (escapeCount > bestEscapeCount) {
        bestEscapeCount = escapeCount;
        bestMoves = [mv];
      } else if (escapeCount == bestEscapeCount) {
        bestMoves.add(mv);
      }
    }

    return bestMoves[random.nextInt(bestMoves.length)];
  }

  static int _reachableCellCount(List<List<int>> traceGrid, int boardSize, int startRow, int startCol) {
    final visited = <String>{'$startRow,$startCol'};
    final queue = <List<int>>[[startRow, startCol]];
    for (var index = 0; index < queue.length; index++) {
      final cell = queue[index];
      for (final next in getValidMoves(traceGrid, boardSize, cell[0], cell[1])) {
        final key = '${next[0]},${next[1]}';
        if (visited.add(key)) queue.add(next);
      }
    }
    return visited.length;
  }
}
