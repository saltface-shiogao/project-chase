import 'package:flutter/material.dart';

import '../ai/criminal_ai.dart';
import '../models/app_theme.dart';
import '../models/game_phase.dart';
import '../models/helicopter.dart';
import '../models/player_role.dart';

/// ビルの見た目スタイル。
/// roofPattern = 屋根パターン風（真上から見たパネル継ぎ目＋室外機）
/// shadowRelief = 新影（立体感）風（屋上ハイライト＋下部の濃色バンドで高さを表現）
/// 将来、設定画面から切り替えられるようにする際は、呼び出し側（game_page.dart）で
/// 選択中のスタイルを保持し、ここへ渡すだけでよい。
enum BuildingStyle { roofPattern, shadowRelief }

/// 道路の見た目スタイル。
/// thin = 現行の細線＋丸ノード
/// twoLane = 太めの2車線風（センターライン＋交差点のクロスウォーク風テクスチャ、
///           盤面の端まで道路を延長）
enum RoadStyle { thin, twoLane }

/// ヘリコプターが移動できる「道路（ルート）」を描画するペインター。
/// 4×4の交差点同士を線でつなぎ、ビルの層とは別のレイヤーとして
/// ヘリの移動範囲を視覚的に示す。ゲームロジックには影響しない（見た目のみ）。
class _RoadNetworkPainter extends CustomPainter {
  final double boardPixelSize;
  final Color lineColor;
  final RoadStyle roadStyle;
  final Color asphaltColor;

  _RoadNetworkPainter({
    required this.boardPixelSize,
    required this.lineColor,
    this.roadStyle = RoadStyle.thin,
    this.asphaltColor = const Color(0xFF3E4A57),
  });

  Offset _centerOf(int i, int j) {
    final double cx = (j + 1) * (boardPixelSize / 5);
    final double cy = (i + 1) * (boardPixelSize / 5);
    return Offset(cx, cy);
  }

  // 各セグメントの座標をPathに追記するだけにして、実際のcanvas描画は
  // paint()内で「レイヤーごとに1回」だけ行う（drawLineの呼び出し回数を
  // 数百→数回に減らし、負荷を大きく下げるため）。
  void _addSegment(
    Offset a,
    Offset b, {
    required Path mainPath,
    Path? edgePathA,
    Path? edgePathB,
    Path? dashPath,
  }) {
    mainPath.moveTo(a.dx, a.dy);
    mainPath.lineTo(b.dx, b.dy);

    if (roadStyle == RoadStyle.thin) return;

    final isHorizontal = (a.dy - b.dy).abs() < 0.01;
    final double edgeOffset = boardPixelSize * 0.019;
    final Offset offsetVec = isHorizontal
        ? Offset(0, edgeOffset)
        : Offset(edgeOffset, 0);
    edgePathA!.moveTo(a.dx - offsetVec.dx, a.dy - offsetVec.dy);
    edgePathA.lineTo(b.dx - offsetVec.dx, b.dy - offsetVec.dy);
    edgePathB!.moveTo(a.dx + offsetVec.dx, a.dy + offsetVec.dy);
    edgePathB.lineTo(b.dx + offsetVec.dx, b.dy + offsetVec.dy);

    // 中央の破線（センターライン）
    const dashLen = 6.0, gapLen = 6.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    double covered = 0;
    while (covered < total) {
      final start = a + dir * covered;
      final end = a + dir * (covered + dashLen).clamp(0, total);
      dashPath!.moveTo(start.dx, start.dy);
      dashPath.lineTo(end.dx, end.dy);
      covered += dashLen + gapLen;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mainPath = Path();
    final edgePathA = roadStyle == RoadStyle.thin ? null : Path();
    final edgePathB = roadStyle == RoadStyle.thin ? null : Path();
    final dashPath = roadStyle == RoadStyle.thin ? null : Path();

    void addSeg(Offset a, Offset b) => _addSegment(
      a,
      b,
      mainPath: mainPath,
      edgePathA: edgePathA,
      edgePathB: edgePathB,
      dashPath: dashPath,
    );

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final center = _centerOf(i, j);
        if (j < 3) addSeg(center, _centerOf(i, j + 1));
        if (i < 3) addSeg(center, _centerOf(i + 1, j));
      }
    }

    // 道路を盤面の端まで延長（内側4×4交差点 → 盤の外周）
    for (int i = 0; i < 4; i++) {
      final left = _centerOf(i, 0);
      addSeg(Offset(0, left.dy), left);
      final right = _centerOf(i, 3);
      addSeg(right, Offset(boardPixelSize, right.dy));
    }
    for (int j = 0; j < 4; j++) {
      final top = _centerOf(0, j);
      addSeg(Offset(top.dx, 0), top);
      final bottom = _centerOf(3, j);
      addSeg(bottom, Offset(bottom.dx, boardPixelSize));
    }

    if (roadStyle == RoadStyle.thin) {
      final linePaint = Paint()
        ..color = lineColor.withOpacity(0.9)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(mainPath, linePaint);

      // 交差点ノード（丸）。これも1つのPathにまとめて1回で描画する。
      final nodesPath = Path();
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          nodesPath.addOval(
            Rect.fromCircle(center: _centerOf(i, j), radius: 6),
          );
        }
      }
      canvas.drawPath(nodesPath, Paint()..color = lineColor.withOpacity(0.9));
      return;
    }

    // 2車線風：太めのアスファルト本線
    canvas.drawPath(
      mainPath,
      Paint()
        ..color = asphaltColor
        ..strokeWidth = boardPixelSize * 0.045
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 交差点の四角（アスファルト色のRect）は描かない。
    // ビルの層より手前に描かれるため各ビルの角にめり込んで見えるうえ、
    // ビル側の「捜索済みマーカー」を隠してしまっていたため廃止。
    // 本線同士は strokeCap.round のおかげで自然につながる。

    // レーンライン（両端）
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(edgePathA!, edgePaint);
    canvas.drawPath(edgePathB!, edgePaint);

    // 中央の破線（センターライン）
    canvas.drawPath(
      dashPath!,
      Paint()
        ..color = const Color(0xFFF2E7C9)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RoadNetworkPainter oldDelegate) {
    return oldDelegate.boardPixelSize != boardPixelSize ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.roadStyle != roadStyle ||
        oldDelegate.asphaltColor != asphaltColor;
  }
}

/// ビルスタイル「屋根パターン風」のパネル継ぎ目を描く簡易ペインター。
class _RoofPatternPainter extends CustomPainter {
  final Color lineColor;
  _RoofPatternPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RoofPatternPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
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
  // アプリ全体のデザインテーマ。省略時は「ボードゲーム風」テーマを使う。
  // 将来、設定画面からの切り替えに対応する際は、呼び出し側からここへ
  // 選択中のテーマを渡すだけでよい（BoardWidget内のロジックは変更不要）。
  final AppTheme theme;
  // ビル・道路の見た目スタイル。将来、設定画面から切り替えられるようにする際は、
  // 呼び出し側（game_page.dart）で選択中のスタイルを保持し、ここへ渡すだけでよい。
  final BuildingStyle buildingStyle;
  final RoadStyle roadStyle;

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
    this.theme = const AppTheme(
      name: 'ボードゲーム風',
      appBarBackground: Color(0xFF2B3A55),
      appBarForeground: Color(0xFFE8DCC3),
      scaffoldBackground: Color(0xFFE8DCC3),
      boardBackground: Color(0xFFE8DCC3),
      gridLine: Color(0xFF2B3A55),
      buildingColor: Color(0xFF8A7A64),
      buildingHighlight: Color(0xFFA9998A),
      buildingShadow: Color(0xFF5C4F3F),
      searchedBuildingColor: Color(0xFFBEB29B),
      searchableZoneColor: Color(0xFFB5533C),
      pendingSearchColor: Color(0xFFC9A227),
      moveCandidateColor: Color(0xFF6B7A4F),
      deadEndWarningColor: Color(0xFFB5533C),
      carColor: Color(0xFFC9A227),
      traceAccentColor: Color(0xFFC9A227),
      inkColor: Color(0xFF1F1B16),
    ),
    this.buildingStyle = BuildingStyle.shadowRelief,
    this.roadStyle = RoadStyle.twoLane,
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

    // 盤面本体（boardPixelSize角）を薄い芝生＋縁石のトリムで囲む。
    // トリムの太さはビル間の道路幅に近い値（板面サイズの約2.6%＋1.1%）にしており、
    // 純粋な装飾レイヤーなので、内部の交差点・ビルの座標計算（boardPixelSize基準）
    // には一切影響しない。
    final double grassPad = boardPixelSize * 0.026;
    final double curbPad = boardPixelSize * 0.011;

    final Widget boardCore = Container(
      width: boardPixelSize,
      height: boardPixelSize,
      decoration: BoxDecoration(
        color: theme.boardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.gridLine, width: 2),
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
                      bool showCar = isCarRevealedAtGameOver || isOwnCarVisible;

                      // 痕跡の可視性：
                      // ・ゲーム終了後は犯人の全痕跡を両陣営に公開（逃走ルートを振り返れるように）
                      // ・プレイ中は、犯人役=自分の全痕跡、警察役=発見済みの痕跡のみ
                      bool isTraceRevealed = currentPhase == GamePhase.gameOver
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
                          pendingIsSearch && pendingRow == r && pendingCol == c;

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

                      // 包囲事前警告（表示のみ・ルール変更なし）：
                      // この候補へ移動すると、次に動ける隣接マスが0件になる
                      // （＝次のターンで包囲状態が確定する）場合に警告を出す。
                      // 1人プレイ・2人対戦を問わず、犯人役=人間のときは常に有効。
                      bool isDeadEndMoveCandidate =
                          isMoveCandidate &&
                          CriminalAi.getValidMoves(
                            traceGrid,
                            boardSize,
                            r,
                            c,
                          ).isEmpty;

                      Color cellColor;
                      if (showCar) {
                        cellColor = theme.carColor;
                      } else if (isPendingSearch) {
                        cellColor = theme.pendingSearchColor;
                      } else if (isSearchableArea) {
                        cellColor = theme.searchableZoneColor;
                      } else if (isDeadEndMoveCandidate) {
                        cellColor = theme.deadEndWarningColor;
                      } else if (isMoveCandidate) {
                        cellColor = theme.moveCandidateColor;
                      } else {
                        // 新影風のときは、通常ビルの基本色として写真参考の
                        // 紺色（buildingShadowReliefTop）を使う。
                        cellColor = buildingStyle == BuildingStyle.shadowRelief
                            ? theme.buildingShadowReliefTop
                            : theme.buildingColor;
                      }

                      // 特別な状態（捜索候補／捜索可能ゾーン／移動候補／包囲警告）の
                      // ときは、その状態色をはっきり見せたいので枠を出す。
                      // 通常時は枠を出さず、グラデーションのみで立体感を出すことで
                      // マス同士の「継ぎ目」が目立たないようにしている。
                      final bool isSpecialState =
                          isPendingSearch ||
                          isSearchableArea ||
                          isMoveCandidate;
                      final Color topShade = Color.lerp(
                        cellColor,
                        Colors.white,
                        0.16,
                      )!;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onBuildingTap(r, c),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [topShade, cellColor],
                              ),
                              borderRadius: BorderRadius.circular(
                                buildingStyle == BuildingStyle.shadowRelief
                                    ? 5
                                    : 6,
                              ),
                              border: isPendingSearch
                                  ? Border.all(
                                      color: theme.pendingSearchColor,
                                      width: 3,
                                    )
                                  : isSpecialState
                                  ? Border.all(
                                      color: isDeadEndMoveCandidate
                                          ? theme.deadEndWarningColor
                                          : isMoveCandidate
                                          ? theme.moveCandidateColor
                                          : theme.searchableZoneColor,
                                      width: isDeadEndMoveCandidate ? 3 : 2,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                // 新影（立体感）風：屋上のハイライト帯＋下部の
                                // 濃色バンドで高さを表現する（マス内に収める版）。
                                if (buildingStyle ==
                                    BuildingStyle.shadowRelief) ...[
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    child: FractionallySizedBox(
                                      heightFactor: 0.16,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.16),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(5),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: FractionallySizedBox(
                                      heightFactor: 0.22,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color.lerp(
                                            cellColor,
                                            Colors.black,
                                            0.38,
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                bottom: Radius.circular(5),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else
                                  // 屋根パターン風：パネル継ぎ目＋室外機
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: CustomPaint(
                                        painter: _RoofPatternPainter(
                                          lineColor: theme.buildingShadow
                                              .withOpacity(0.25),
                                        ),
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: showCar
                                      ? Icon(
                                          Icons.directions_car,
                                          color: theme.inkColor,
                                          size: 36,
                                        )
                                      : Icon(
                                          Icons.location_city,
                                          color: theme.buildingShadow
                                              .withOpacity(0.5),
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
                                          // 警察が実際に発見済みの痕跡は、誰の視点でも
                                          // 大きめ・赤枠で強調する（プレイ中／終了後とも）。
                                          padding: EdgeInsets.all(
                                            revealedTraces[r][c] ? 7 : 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getTraceColor(
                                              traceGrid[r][c],
                                            ),
                                            shape: BoxShape.circle,
                                            border: revealedTraces[r][c]
                                                ? Border.all(
                                                    color: Colors.red,
                                                    width: 2.5,
                                                  )
                                                : null,
                                            boxShadow: revealedTraces[r][c]
                                                ? const [
                                                    BoxShadow(
                                                      color: Colors.black45,
                                                      blurRadius: 3,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          // 痕跡が何ターン目のものかは、プレイ中は
                                          // 隠す（新しい／古いは色の違いのみで表現）。
                                          // ゲーム終了後の振り返り時のみ数字を表示する。
                                          child:
                                              currentPhase == GamePhase.gameOver
                                              ? Text(
                                                  '${traceGrid[r][c]}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : SizedBox(
                                                  width: revealedTraces[r][c]
                                                      ? 10
                                                      : 6,
                                                  height: revealedTraces[r][c]
                                                      ? 10
                                                      : 6,
                                                ),
                                        ),
                                        // 警察に発見済みの痕跡を強調する目印
                                        if (isFoundByPolice)
                                          Positioned(
                                            bottom: -4,
                                            left: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
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
                                // ※ヘリの「行動済み」バッジ（交差点側）と紛らわしいとの
                                // 　フィードバックを受け、こちらは警察系の色（searchableZoneColor）
                                // 　の丸に統一し、色で見分けられるようにしている。
                                if (showSearchedMarker && !showCar)
                                  Positioned(
                                    bottom: 3,
                                    left: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: theme.searchableZoneColor
                                            .withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                // 包囲事前警告アイコン：この候補へ移動すると
                                // 次に動けなくなる（表示のみ・ルール変更なし）
                                if (isDeadEndMoveCandidate && !showCar)
                                  Positioned(
                                    bottom: 3,
                                    right: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: theme.deadEndWarningColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                        size: 14,
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
                painter: _RoadNetworkPainter(
                  boardPixelSize: boardPixelSize,
                  lineColor: theme.gridLine,
                  roadStyle: roadStyle,
                  asphaltColor: theme.roadAsphaltColor,
                ),
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
                emptyRingColor = theme.pendingSearchColor;
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
                      // ※ビル側の「捜索済み」マーカー（赤茶の丸＋チェック）と紛らわしいとの
                      // 　フィードバックを受け、こちらは紺色の丸＋二重チェックに変更している。
                      if (isActed)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.gridLine,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.done_all,
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
    );

    return Center(
      child: Container(
        padding: EdgeInsets.all(grassPad),
        decoration: BoxDecoration(
          color: theme.boardTrimGrassColor, // 芝生（グラスグリーン）
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.gridLine, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 3,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(curbPad),
          decoration: BoxDecoration(
            color: theme.boardTrimCurbColor, // 縁石（グレージュ）
            borderRadius: BorderRadius.circular(6),
          ),
          child: boardCore,
        ),
      ),
    );
  }
}
