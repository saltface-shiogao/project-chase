import 'package:flutter/material.dart';

import '../ai/criminal_ai.dart';
import '../models/game_phase.dart';
import '../models/helicopter.dart';
import '../models/player_role.dart';

/// ゲーム盤面（5×5のビルと4×4の交差点）の描画とタップ処理
class BoardWidget extends StatelessWidget {
  final double boardPixelSize;
  final double heliMarkerSize;
  final int boardSize;
  final GamePhase currentPhase;
  final PlayerRole? playerRole;
  final int carRow;
  final int carCol;
  final List<List<int>> traceGrid;
  final List<List<bool>> revealedTraces;
  final List<Helicopter> helicopters;
  final int currentHeliIndex;
  final bool isSearchMode;
  final bool isPoliceTurnRunning;
  final Color Function(int roundNumber) getTraceColor;
  final void Function(int r, int c) onBuildingTap;
  final void Function(int i, int j) onIntersectionTap;

  const BoardWidget({
    super.key,
    required this.boardPixelSize,
    required this.heliMarkerSize,
    required this.boardSize,
    required this.currentPhase,
    required this.playerRole,
    required this.carRow,
    required this.carCol,
    required this.traceGrid,
    required this.revealedTraces,
    required this.helicopters,
    required this.currentHeliIndex,
    required this.isSearchMode,
    required this.isPoliceTurnRunning,
    required this.getTraceColor,
    required this.onBuildingTap,
    required this.onIntersectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: boardPixelSize,
        height: boardPixelSize,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!, width: 2),
        ),
        child: Stack(
          children: [
            // 1. ビル(5x5)の描画
            Positioned.fill(
              child: Column(
                children: List.generate(boardSize, (r) {
                  return Expanded(
                    child: Row(
                      children: List.generate(boardSize, (c) {
                        bool isCarRevealedAtGameOver =
                            currentPhase == GamePhase.gameOver && r == carRow && c == carCol;
                        bool isOwnCarVisible = playerRole == PlayerRole.criminal &&
                            carRow != -1 &&
                            r == carRow &&
                            c == carCol;
                        bool showCar = isCarRevealedAtGameOver || isOwnCarVisible;

                        bool isTraceRevealed = revealedTraces[r][c];

                        final currentHeli = helicopters.isNotEmpty &&
                                currentPhase == GamePhase.playing &&
                                playerRole == PlayerRole.police
                            ? helicopters[currentHeliIndex]
                            : null;
                        bool isSearchableArea = currentPhase == GamePhase.playing &&
                            playerRole == PlayerRole.police &&
                            isSearchMode &&
                            currentHeli != null &&
                            (r == currentHeli.row || r == currentHeli.row + 1) &&
                            (c == currentHeli.col || c == currentHeli.col + 1);

                        bool isMoveCandidate = currentPhase == GamePhase.playing &&
                            playerRole == PlayerRole.criminal &&
                            !isPoliceTurnRunning &&
                            carRow != -1 &&
                            CriminalAi.getValidMoves(traceGrid, boardSize, carRow, carCol)
                                .any((mv) => mv[0] == r && mv[1] == c);

                        Color cellColor;
                        if (showCar) {
                          cellColor = Colors.amber[300]!;
                        } else if (isSearchableArea) {
                          cellColor = Colors.blue[200]!;
                        } else if (isMoveCandidate) {
                          cellColor = Colors.green[300]!;
                        } else {
                          cellColor = Colors.blueGrey[800]!;
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onBuildingTap(r, c),
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(6),
                                border: (isSearchableArea || isMoveCandidate)
                                    ? Border.all(
                                        color: isMoveCandidate ? Colors.green : Colors.blue, width: 2)
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: showCar
                                        ? const Icon(Icons.directions_car, color: Colors.black, size: 36)
                                        : const Icon(Icons.location_city, color: Colors.white24, size: 30),
                                  ),
                                  if (isTraceRevealed && !showCar)
                                    Positioned(
                                      top: 3,
                                      right: 3,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: getTraceColor(traceGrid[r][c]),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${traceGrid[r][c]}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),

            // 2. 交差点(4x4)の描画（ヘリ移動・配置タップ用）
            ...List.generate(4, (i) {
              return List.generate(4, (j) {
                final double top = (i + 1) * (boardPixelSize / 5) - (heliMarkerSize / 2);
                final double left = (j + 1) * (boardPixelSize / 5) - (heliMarkerSize / 2);

                int heliIndex = helicopters.indexWhere((h) => h.row == i && h.col == j);
                bool isCurrentHeli = currentPhase == GamePhase.playing &&
                    playerRole == PlayerRole.police &&
                    heliIndex == currentHeliIndex;

                return Positioned(
                  top: top,
                  left: left,
                  child: GestureDetector(
                    onTap: () => onIntersectionTap(i, j),
                    child: Container(
                      width: heliMarkerSize,
                      height: heliMarkerSize,
                      decoration: BoxDecoration(
                        color: heliIndex != -1
                            ? (isCurrentHeli ? Colors.orange : Colors.blue)
                            : Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrentHeli ? Colors.red : Colors.white,
                          width: isCurrentHeli ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: heliIndex != -1
                            ? Text(
                                'H${helicopters[heliIndex].id}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ),
                );
              });
            }).expand((element) => element),
          ],
        ),
      ),
    );
  }
}
