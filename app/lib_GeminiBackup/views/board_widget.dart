import 'package:flutter/material.dart';
import '../models/helicopter.dart';
import '../models/player_role.dart';
import '../ai/criminal_ai.dart';

class BoardWidget extends StatelessWidget {
  final List<Helicopter> helicopters;
  final Helicopter? selectedHelicopter;
  final List<List<int>> searchedBuildings;
  final int criminalX;
  final int criminalY;
  final PlayerRole playerRole;
  final bool isGameOver;
  final Function(Helicopter) onSelectHelicopter;
  final Function(int, int) onMoveHelicopter;
  final Function(int, int) onMoveCriminal;

  const BoardWidget({
    super.key,
    required this.helicopters,
    required this.selectedHelicopter,
    required this.searchedBuildings,
    required this.criminalX,
    required this.criminalY,
    required this.playerRole,
    required this.isGameOver,
    required this.onSelectHelicopter,
    required this.onMoveHelicopter,
    required this.onMoveCriminal,
  });

  @override
  Widget build(BuildContext context) {
    // 犯人の有効な移動可能マスを取得
    List<List<int>> validCriminalMoves = [];
    try {
      validCriminalMoves = CriminalAi.getValidMoves(criminalX, criminalY);
    } catch (_) {
      final directions = [
        [0, -1],
        [0, 1],
        [-1, 0],
        [1, 0]
      ];
      for (var d in directions) {
        int nx = criminalX + d[0];
        int ny = criminalY + d[1];
        if (nx >= 0 && nx < 5 && ny >= 0 && ny < 5) {
          validCriminalMoves.add([nx, ny]);
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double boardSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        if (boardSize > 600) boardSize = 600;

        double cellSize = boardSize / 9;

        // 1. グリッドセルの生成
        List<Widget> gridCells = [];
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            bool isBuilding = (row % 2 == 0) && (col % 2 == 0);

            if (isBuilding) {
              int bX = col ~/ 2;
              int bY = row ~/ 2;
              bool isSearched =
                  searchedBuildings.any((b) => b[0] == bX && b[1] == bY);

              gridCells.add(
                Positioned(
                  left: col * cellSize,
                  top: row * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSearched
                          ? Colors.grey.shade600
                          : Colors.amber.shade300,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSearched
                            ? Colors.grey.shade800
                            : Colors.amber.shade800,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSearched
                                ? Icons.domain_disabled
                                : Icons.domain,
                            color: isSearched
                                ? Colors.grey.shade300
                                : Colors.amber.shade900,
                            size: cellSize * 0.45,
                          ),
                          Text(
                            '${bX + 1},${bY + 1}',
                            style: TextStyle(
                              fontSize: cellSize * 0.16,
                              fontWeight: FontWeight.bold,
                              color: isSearched
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              gridCells.add(
                Positioned(
                  left: col * cellSize,
                  top: row * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    color: Colors.grey.shade800.withValues(alpha: 0.5),
                  ),
                ),
              );
            }
          }
        }

        // 2. 選択中ヘリの移動目標マス生成
        List<Widget> helicopterMoveTargets = [];
        if (selectedHelicopter != null &&
            playerRole == PlayerRole.police &&
            !isGameOver) {
          for (int r = 0; r < 5; r++) {
            for (int c = 0; c < 5; c++) {
              int dist = (selectedHelicopter!.x - c).abs() +
                  (selectedHelicopter!.y - r).abs();
              if (dist == 1) {
                helicopterMoveTargets.add(
                  Positioned(
                    left: (c * 2 + 1) * cellSize,
                    top: (r * 2) * cellSize,
                    width: cellSize,
                    height: cellSize,
                    child: GestureDetector(
                      onTap: () => onMoveHelicopter(c, r),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.cyanAccent, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.navigation, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
          }
        }

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border.all(color: Colors.black, width: 3),
          ),
          child: Stack(
            children: [
              // 背景グリッド
              ...gridCells,

              // 犯人移動ガイド
              if (playerRole == PlayerRole.criminal && !isGameOver)
                ...validCriminalMoves.map((move) {
                  int mX = move[0];
                  int mY = move[1];
                  return Positioned(
                    left: (mX * 2) * cellSize,
                    top: (mY * 2) * cellSize,
                    width: cellSize,
                    height: cellSize,
                    child: GestureDetector(
                      onTap: () => onMoveCriminal(mX, mY),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.lightGreenAccent, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.touch_app, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }),

              // 犯人表示
              if (playerRole == PlayerRole.criminal || isGameOver)
                Positioned(
                  left: (criminalX * 2) * cellSize,
                  top: (criminalY * 2) * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_pin,
                        color: Colors.white,
                        size: cellSize * 0.6,
                      ),
                    ),
                  ),
                ),

              // 警察ヘリ表示
              ...helicopters.map((h) {
                bool isSelected = selectedHelicopter == h;
                double hLeft = (h.x * 2 + 1) * cellSize;
                double hTop = (h.y * 2) * cellSize;
                if (h.x >= 4) hLeft = (4 * 2 - 1) * cellSize;

                return Positioned(
                  left: hLeft,
                  top: hTop,
                  width: cellSize,
                  height: cellSize,
                  child: GestureDetector(
                    onTap: () => onSelectHelicopter(h),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.8)
                            : Colors.blue.shade900.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.cyanAccent : Colors.white,
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.airplanemode_active,
                          color: h.isSearching ? Colors.amber : Colors.white,
                          size: cellSize * 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // ヘリ移動目標
              ...helicopterMoveTargets,
            ],
          ),
        );
      },
    );
  }
}