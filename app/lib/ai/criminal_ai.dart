import 'dart:math';

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
  ) {
    List<List<int>> validMoves = getValidMoves(traceGrid, boardSize, carRow, carCol);
    if (validMoves.isEmpty) {
      return null;
    }

    int bestEscapeCount = -1;
    List<List<int>> bestMoves = [];
    for (var mv in validMoves) {
      int escapeCount = getValidMoves(traceGrid, boardSize, mv[0], mv[1]).length;
      if (escapeCount > bestEscapeCount) {
        bestEscapeCount = escapeCount;
        bestMoves = [mv];
      } else if (escapeCount == bestEscapeCount) {
        bestMoves.add(mv);
      }
    }

    final random = Random();
    return bestMoves[random.nextInt(bestMoves.length)];
  }
}
