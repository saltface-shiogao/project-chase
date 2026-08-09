import 'dart:math';

class CriminalAi {
  static List<List<int>> getValidMoves(int x, int y) {
    List<List<int>> moves = [];
    List<List<int>> directions = [
      [0, -1], [0, 1], [-1, 0], [1, 0]
    ];
    for (var dir in directions) {
      int nx = x + dir[0];
      int ny = y + dir[1];
      if (nx >= 0 && nx < 5 && ny >= 0 && ny < 5) {
        moves.add([nx, ny]);
      }
    }
    return moves;
  }

  static List<int> decideMove({
    required int currentX,
    required int currentY,
    required List<List<int>> policePositions,
    required List<List<int>> searchedBuildings,
  }) {
    List<List<int>> validMoves = getValidMoves(currentX, currentY);
    if (validMoves.isEmpty) return [currentX, currentY];

    List<List<int>> unsearchedMoves = validMoves.where((move) {
      return !searchedBuildings.any((b) => b[0] == move[0] && b[1] == move[1]);
    }).toList();

    List<List<int>> candidateMoves =
        unsearchedMoves.isNotEmpty ? unsearchedMoves : validMoves;

    List<int> bestMove = candidateMoves.first;
    double maxMinDistance = -1;

    for (var move in candidateMoves) {
      double minDistance = double.infinity;
      for (var police in policePositions) {
        double dist = sqrt(
            pow(move[0] - police[0], 2) + pow(move[1] - police[1], 2));
        if (dist < minDistance) {
          minDistance = dist;
        }
      }
      if (minDistance > maxMinDistance) {
        maxMinDistance = minDistance;
        bestMove = move;
      }
    }

    return bestMove;
  }
}
