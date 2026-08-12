import 'package:flutter/material.dart';

import '../ai/criminal_ai.dart';
import '../models/game_phase.dart';
import '../models/helicopter.dart';
import '../models/player_role.dart';

/// ヘリコプターが移動できる「道路（ルート）」を描画するペインター。
/// 4×4の交差点同士を線でつなぎ、ビルの層とは別のレイヤーとして
/// ヘリの移動範囲を視覚的に示す。ゲームロジックには影響しない（見た目のみ）。
class _RoadNetworkPainter extends CustomPainter {
  final double boardPixelSize;

  _RoadNetworkPainter({required this.boardPixelSize});

  Offset _centerOf(int i, int j) {
    final double cx = (j + 1) * (boardPixelSize / 5);
    final double cy = (i + 1) * (boardPixelSize / 5);
    return Offset(cx, cy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueGrey[300]!.withOpacity(0.9)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = Colors.blueGrey[300]!.withOpacity(0.9);

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final center = _centerOf(i, j);
        if (j < 3) {
          canvas.drawLine(center, _centerOf(i, j + 1), linePaint);
        }
        if (i < 3) {
          canvas.drawLine(center, _centerOf(i + 1, j), linePaint);
        }
        canvas.drawCircle(center, 6, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadNetworkPainter oldDelegate) {
    return oldDelegate.boardPixelSize != boardPixelSize;
  }
}

/// ゲーム盤面（5×5のビルと4×4の交差点）の描画とタップ処理
class BoardWidget extends StatelessWidget {
  // ヘリ1・ヘリ2・ヘリ3をそれぞれ異なる色（警察カラーの範囲内）で表示する
  static const List<Color> heliColors = [
    Color(0xFF1A237E), // ヘリ1：紺（Indigo 900）
    Color(0xFF2E7D32), // ヘリ2：緑（Green 800）
    Color(0xFF6A1B9A), // ヘリ3：紫（Purple 800）
  ];

  final double boardPixelSize;
  final double heliMarkerSize;
  final int boardSize;
  final GamePhase currentPhase;
  final PlayerRole? playerRole;
  final int carRow;
  final int carCol;
  final List<List<int>> traceGrid;
  final List<List<bool>> revealedTraces;
  // ヘリごとの「直近の捜索場所」。要素数3（ヘリ1〜3に対応、インデックス=id-1）で、
  // 各要素は [row, col]（未捜索時は [-1, -1]）。盤面上には最大3箇所同時に表示される。
  final List<List<int>> lastSearchedByHeli;
  final int searchingRow;
  final int searchingCol;
  final List<Helicopter> helicopters;
  final int currentHeliIndex;
  final bool isPoliceTurnRunning;
  // 警察役=人間が、確定前に選択している「候補」の座標（誤操作防止のための確認ステップ用）。
  // 未選択時は pendingRow/pendingCol ともに -1。
  final int pendingRow;
  final int pendingCol;
  // true: pendingRow/pendingColはビル（捜索候補）／false: 交差点（移動候補）
  final bool pendingIsSearch;
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
    required this.lastSearchedByHeli,
    required this.searchingRow,
    required this.searchingCol,
    required this.helicopters,
    required this.currentHeliIndex,
    required this.isPoliceTurnRunning,
    required this.pendingRow,
    required this.pendingCol,
    required this.pendingIsSearch,
    required this.getTraceColor,
    required this.onBuildingTap,
    required this.onIntersectionTap,
  });

  @override
  Widget build(BuildContext context) {
    // 現在操作中のヘリ（警察役=人間のプレイ中のみ意味を持つ）
    final currentHeli =
        helicopters.isNotEmpty &&
            currentPhase == GamePhase.playing &&
            playerRole == PlayerRole.police
        ? helicopters[currentHeliIndex]
        : null;
    // 選択中のヘリがまだ行動していない場合のみ、移動・捜索の候補ハイライトを出す
    final activeHeli = currentHeli != null && !currentHeli.hasActedThisTurn
        ? currentHeli
        : null;

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
                            currentPhase == GamePhase.gameOver &&
                            r == carRow &&
                            c == carCol;
                        bool isOwnCarVisible =
                            playerRole == PlayerRole.criminal &&
                            carRow != -1 &&
                            r == carRow &&
                            c == carCol;
                        bool showCar =
                            isCarRevealedAtGameOver || isOwnCarVisible;

                        // 痕跡の可視性：
                        // ・ゲーム終了後は犯人の全痕跡を両陣営に公開（逃走ルートを振り返れるように）
                        // ・プレイ中は、犯人役=自分の全痕跡、警察役=発見済みの痕跡のみ
                        bool isTraceRevealed =
                            currentPhase == GamePhase.gameOver
                            ? traceGrid[r][c] > 0
                            : (playerRole == PlayerRole.criminal
                                  ? traceGrid[r][c] > 0
                                  : revealedTraces[r][c]);

                        // 犯人視点でのみ意味を持つ：この痕跡がすでに警察に発見されているか
                        bool isFoundByPolice =
                            playerRole == PlayerRole.criminal &&
                            revealedTraces[r][c];

                        // 捜索済みマーカーの表示判定：ヘリ1〜3それぞれの「直近の捜索場所」と
                        // 一致するかどうかを見る。同じラウンド内で複数ヘリが別の場所を捜索した
                        // 場合、それぞれの跡が同時に（最大3箇所）残る。あるヘリが新たに別の場所を
                        // 捜索すると、そのヘリ自身の前回の跡だけが消えて新しい場所に移る
                        // （他のヘリの跡には影響しない）。
                        bool showSearchedMarker = lastSearchedByHeli.any(
                          (pos) => pos[0] == r && pos[1] == c,
                        );

                        // 捜索候補（未確定）：警察役=人間がタップしたが、まだ「確定」ボタンを
                        // 押していないビル。誤操作防止のため、確定するまで実際の捜索は行われない。
                        bool isPendingSearch =
                            pendingIsSearch &&
                            pendingRow == r &&
                            pendingCol == c;

                        // 選択中ヘリの捜索可能範囲（周囲4マス）。モード切替は廃止したため、
                        // ヘリが選択されていて未行動であれば常にガイドとして表示する。
                        bool isSearchableArea =
                            currentPhase == GamePhase.playing &&
                            playerRole == PlayerRole.police &&
                            activeHeli != null &&
                            (r == activeHeli.row || r == activeHeli.row + 1) &&
                            (c == activeHeli.col || c == activeHeli.col + 1);

                        bool isMoveCandidate =
                            currentPhase == GamePhase.playing &&
                            playerRole == PlayerRole.criminal &&
                            !isPoliceTurnRunning &&
                            carRow != -1 &&
                            CriminalAi.getValidMoves(
                              traceGrid,
                              boardSize,
                              carRow,
                              carCol,
                            ).any((mv) => mv[0] == r && mv[1] == c);

                        Color cellColor;
                        if (showCar) {
                          cellColor = Colors.amber[300]!;
                        } else if (isPendingSearch) {
                          cellColor = Colors.orange[300]!;
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
                                border: isPendingSearch
                                    ? Border.all(
                                        color: Colors.deepOrange,
                                        width: 3,
                                      )
                                    : (isSearchableArea || isMoveCandidate)
                                    ? Border.all(
                                        color: isMoveCandidate
                                            ? Colors.green
                                            : Colors.blue,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: showCar
                                        ? const Icon(
                                            Icons.directions_car,
                                            color: Colors.black,
                                            size: 36,
                                          )
                                        : const Icon(
                                            Icons.location_city,
                                            color: Colors.white24,
                                            size: 30,
                                          ),
                                  ),
                                  if (isTraceRevealed && !showCar)
                                    Positioned(
                                      top: 3,
                                      right: 3,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: getTraceColor(
                                                traceGrid[r][c],
                                              ),
                                              shape: BoxShape.circle,
                                              border: isFoundByPolice
                                                  ? Border.all(
                                                      color: Colors.red,
                                                      width: 2.5,
                                                    )
                                                  : null,
                                            ),
                                            child: Text(
                                              '${traceGrid[r][c]}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // 警察に発見済みの痕跡を強調する目印（犯人視点のみ）
                                          if (isFoundByPolice)
                                            Positioned(
                                              bottom: -4,
                                              left: -4,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.visibility,
                                                  color: Colors.white,
                                                  size: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  // 捜索済みマーカー：ヘリごとの直近の捜索場所（最大3箇所同時表示）
                                  if (showSearchedMarker && !showCar)
                                    Positioned(
                                      bottom: 3,
                                      left: 3,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white70,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  // 捜索中の演出：拡大鏡アイコン＋ポップ（パルス）アニメーション
                                  if (r == searchingRow && c == searchingCol)
                                    Center(
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.4, end: 1.3),
                                        duration: const Duration(
                                          milliseconds: 450,
                                        ),
                                        curve: Curves.easeOutBack,
                                        builder: (context, scale, child) =>
                                            Transform.scale(
                                              scale: scale,
                                              child: child,
                                            ),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.search,
                                            color: Colors.white,
                                            size: 26,
                                          ),
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

            // 2. ヘリコプター専用の通り道（道路レイヤー）。ビルとは別レイヤーで、
            //    交差点同士を線でつなぐことで、ヘリがこのルート上のみを
            //    移動していることを視覚的に示す。
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RoadNetworkPainter(boardPixelSize: boardPixelSize),
                ),
              ),
            ),

            // 3. 交差点(4x4)の描画（ヘリ移動・配置タップ用）
            ...List.generate(4, (i) {
              return List.generate(4, (j) {
                final double top =
                    (i + 1) * (boardPixelSize / 5) - (heliMarkerSize / 2);
                final double left =
                    (j + 1) * (boardPixelSize / 5) - (heliMarkerSize / 2);

                int heliIndex = helicopters.indexWhere(
                  (h) => h.row == i && h.col == j,
                );
                bool isCurrentHeli =
                    currentPhase == GamePhase.playing &&
                    playerRole == PlayerRole.police &&
                    heliIndex == currentHeliIndex;
                // このヘリが今ターン、既に行動済みかどうか（警察役=人間の操作順が
                // 自由に選べるようになったため、どれが行動済みか一目で分かるようにする）
                bool isActed =
                    heliIndex != -1 && helicopters[heliIndex].hasActedThisTurn;

                // 空いている交差点が、選択中ヘリの移動先として有効（タテヨコ隣接）かどうか
                bool isValidMoveTarget = false;
                if (heliIndex == -1 &&
                    currentPhase == GamePhase.playing &&
                    playerRole == PlayerRole.police &&
                    activeHeli != null) {
                  int dr = (activeHeli.row - i).abs();
                  int dc = (activeHeli.col - j).abs();
                  isValidMoveTarget =
                      (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
                }

                // 移動候補（未確定）：タップしたがまだ「確定」ボタンを押していない交差点
                bool isPendingMove =
                    heliIndex == -1 &&
                    !pendingIsSearch &&
                    pendingRow == i &&
                    pendingCol == j;

                Color emptyRingColor;
                double emptyRingWidth;
                Color emptyFillColor;
                if (isPendingMove) {
                  emptyRingColor = Colors.deepOrange;
                  emptyRingWidth = 3;
                  emptyFillColor = Colors.orange.withOpacity(0.85);
                } else if (isValidMoveTarget) {
                  emptyRingColor = Colors.greenAccent.shade400;
                  emptyRingWidth = 2.5;
                  emptyFillColor = Colors.transparent;
                } else {
                  emptyRingColor = Colors.white.withOpacity(0.7);
                  emptyRingWidth = 1.5;
                  emptyFillColor = Colors.transparent;
                }

                return Positioned(
                  top: top,
                  left: left,
                  child: GestureDetector(
                    onTap: () => onIntersectionTap(i, j),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: heliMarkerSize,
                          height: heliMarkerSize,
                          decoration: BoxDecoration(
                            color: heliIndex != -1
                                ? heliColors[(helicopters[heliIndex].id - 1) %
                                          heliColors.length]
                                      .withOpacity(isActed ? 0.4 : 1.0)
                                : emptyFillColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: heliIndex != -1
                                  ? (isCurrentHeli
                                        ? Colors.orangeAccent
                                        : Colors.white)
                                  : emptyRingColor,
                              width: heliIndex != -1
                                  ? (isCurrentHeli ? 3.5 : 1.5)
                                  : emptyRingWidth,
                            ),
                            boxShadow: heliIndex != -1
                                ? const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: heliIndex != -1
                                ? const Icon(
                                    Icons.local_police,
                                    color: Colors.white,
                                    size: 22,
                                  )
                                : (isPendingMove
                                      ? const Icon(
                                          Icons.flag,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : const SizedBox()),
                          ),
                        ),
                        // 行動済みバッジ：警察役=人間がどのヘリを操作済みか一目で分かるように表示
                        if (isActed)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 11,
                              ),
                            ),
                          ),
                      ],
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
