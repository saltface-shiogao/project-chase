import 'dart:math';

import '../models/helicopter.dart';
import '../models/police_ai_action.dart';
import '../models/ai_difficulty.dart';

/// 警察（ヘリコプター）に関するAIロジック。
/// 「次に何をすべきか」を判断して PoliceAiAction として返すのみで、
/// setState・ログ追加・逮捕判定などの状態変更は一切行わない
/// （それらは views/game_page.dart 側の責務）。
class PoliceAi {
  /// 1機のヘリについて、次の行動を決定する。
  /// 担当エリア（周囲4マス）に未捜索の建物があれば捜索を、
  /// 全て捜索済みなら、未捜索マスが多く残る隣接交差点への移動を選ぶ。
  static PoliceAiAction decideAction(
    Helicopter heli,
    List<Helicopter> allHelicopters,
    List<List<bool>> searchedGrid,
    {
      AiDifficulty difficulty = AiDifficulty.normal,
      List<List<bool>>? revealedTraces,
    }
  ) {
    List<List<int>> zoneCells = [
      [heli.row, heli.col],
      [heli.row, heli.col + 1],
      [heli.row + 1, heli.col],
      [heli.row + 1, heli.col + 1],
    ];
    List<List<int>> unsearchedInZone =
        zoneCells.where((cell) => !searchedGrid[cell[0]][cell[1]]).toList();

    if (unsearchedInZone.isNotEmpty) {
      final random = Random();
      // 難しいAIは、発見済み痕跡の近くから優先して捜索する。
      if (difficulty == AiDifficulty.hard && revealedTraces != null) {
        final traces = <List<int>>[];
        for (var r = 0; r < revealedTraces.length; r++) {
          for (var c = 0; c < revealedTraces[r].length; c++) {
            if (revealedTraces[r][c]) traces.add([r, c]);
          }
        }
        if (traces.isNotEmpty) {
          unsearchedInZone.sort((a, b) {
            int distance(List<int> cell) => traces
                .map((trace) => (cell[0] - trace[0]).abs() + (cell[1] - trace[1]).abs())
                .reduce((a, b) => a < b ? a : b);
            return distance(a).compareTo(distance(b));
          });
          return PoliceAiAction.search(unsearchedInZone.first[0], unsearchedInZone.first[1]);
        }
      }
      final target = unsearchedInZone[random.nextInt(unsearchedInZone.length)];
      return PoliceAiAction.search(target[0], target[1]);
    }

    final directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1]
    ];
    List<List<int>> candidates = [];
    for (var dir in directions) {
      int nr = heli.row + dir[0];
      int nc = heli.col + dir[1];
      if (nr >= 0 && nr < 4 && nc >= 0 && nc < 4) {
        bool occupied = allHelicopters.any((h) => h.id != heli.id && h.row == nr && h.col == nc);
        if (!occupied) candidates.add([nr, nc]);
      }
    }

    if (candidates.isEmpty) {
      return const PoliceAiAction.wait();
    }

    if (difficulty == AiDifficulty.easy) {
      final random = Random();
      final move = candidates[random.nextInt(candidates.length)];
      return PoliceAiAction.move(move[0], move[1]);
    }

    int bestScore = -1;
    List<List<int>> best = [];
    for (var cand in candidates) {
      List<List<int>> zone = [
        [cand[0], cand[1]],
        [cand[0], cand[1] + 1],
        [cand[0] + 1, cand[1]],
        [cand[0] + 1, cand[1] + 1],
      ];
      int score = zone.where((cell) => !searchedGrid[cell[0]][cell[1]]).length;
      if (score > bestScore) {
        bestScore = score;
        best = [cand];
      } else if (score == bestScore) {
        best.add(cand);
      }
    }

    final random = Random();
    final move = best[random.nextInt(best.length)];
    return PoliceAiAction.move(move[0], move[1]);
  }
}
