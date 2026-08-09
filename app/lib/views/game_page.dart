import 'dart:math';
import 'package:flutter/material.dart';

import '../ai/criminal_ai.dart';
import '../ai/police_ai.dart';
import '../models/game_phase.dart';
import '../models/helicopter.dart';
import '../models/player_role.dart';
import '../models/police_ai_action.dart';
import 'board_widget.dart';
import 'log_panel.dart';
import 'role_select_view.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int boardSize = 5;
  static const int maxRounds = 11;

  // 盤面の表示サイズ（ピクセル）。ブラウザでの視認性を考慮したサイズ。
  static const double boardPixelSize = 520;
  static const double heliMarkerSize = 46;

  // ログとして画面に残す最大件数
  static const int maxLogEntries = 6;

  // 役割・フェーズ
  PlayerRole? playerRole;
  GamePhase currentPhase = GamePhase.roleSelect;

  // 車の位置
  int carRow = -1;
  int carCol = -1;

  // 痕跡データ: 0=なし, 1〜11=通ったラウンド
  late List<List<int>> traceGrid;
  // 発見された痕跡の記録（trueなら画面表示）
  late List<List<bool>> revealedTraces;
  // 一度でも捜索されたことがあるか（AI警察が同じ場所を無駄に捜索しないための記録・永続）
  late List<List<bool>> searchedGrid;
  // 何ラウンド目に捜索したか（表示用。0=未捜索）。
  // 「捜索したラウンド＋次の1ラウンドのみ表示」の判定に使う。AIの記憶(searchedGrid)には影響しない。
  late List<List<int>> searchedRoundGrid;

  // 現在アニメーション中（捜索演出中）のビル座標。捜索していない時は-1。
  int searchingRow = -1;
  int searchingCol = -1;

  // ラウンド
  int currentRound = 1;

  // ヘリコプター
  List<Helicopter> helicopters = [];
  int currentHeliIndex = 0;

  // モード（移動 or 捜索）：警察役=人間の時のみ使用
  bool isSearchMode = false;

  // 警察AIが行動中かどうか（犯人役=人間の時、この間は操作をブロックする）
  bool isPoliceTurnRunning = false;

  // アクションログ（複数件保持。先頭が最新）
  List<String> logHistory = [];
  // 勝利メッセージ
  String gameResultMessage = '';

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  // ログにメッセージを追加（最新が先頭、古いものは自動的に消える）
  void _pushLog(String message) {
    logHistory.insert(0, message);
    if (logHistory.length > maxLogEntries) {
      logHistory.removeRange(maxLogEntries, logHistory.length);
    }
  }

  // 盤面状態を初期化する（役割 playerRole はここでは変更しない）
  void _resetBoardState() {
    currentRound = 1;
    carRow = -1;
    carCol = -1;
    currentHeliIndex = 0;
    isSearchMode = false;
    isPoliceTurnRunning = false;
    searchingRow = -1;
    searchingCol = -1;
    gameResultMessage = '';
    logHistory = [];

    traceGrid = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    revealedTraces = List.generate(
      boardSize,
      (_) => List.filled(boardSize, false),
    );
    searchedGrid = List.generate(
      boardSize,
      (_) => List.filled(boardSize, false),
    );
    searchedRoundGrid = List.generate(
      boardSize,
      (_) => List.filled(boardSize, 0),
    );
    helicopters = [];
  }

  // リセット（役割選択画面に戻る）
  void _startNewGame() {
    setState(() {
      currentPhase = GamePhase.roleSelect;
      playerRole = null;
      _resetBoardState();
    });
  }

  // 「連続して遊ぶ」：現在の playerRole を維持したまま盤面だけ初期化し、
  // 役割選択画面を経由せずに次のゲームのセットアップから再開する。
  // ※ ai/criminal_ai.dart・ai/police_ai.dart は状態を持たない純粋関数のみで
  //   構成されているため、AI側で別途リセットすべき内部状態は存在しない。
  void _restartSameRole() {
    if (playerRole == null) {
      _startNewGame();
      return;
    }
    final role = playerRole!;

    setState(() {
      _resetBoardState();
    });

    if (role == PlayerRole.police) {
      setState(() {
        currentPhase = GamePhase.setupHelicopters;
        _pushLog('【セットアップ】警察ヘリコプター(3機)の初期配置場所（交差点）を3箇所選んでください。');
      });
    } else {
      _placeHelicoptersRandomly();
      setState(() {
        currentPhase = GamePhase.setupCarHuman;
        _pushLog('警察が展開しました。あなたの車の隠れ場所（ビル）を1つタップして選んでください。');
      });
    }
  }

  // 役割選択
  void _chooseRole(PlayerRole role) {
    setState(() {
      playerRole = role;

      if (role == PlayerRole.police) {
        currentPhase = GamePhase.setupHelicopters;
        _pushLog('【セットアップ】警察ヘリコプター(3機)の初期配置場所（交差点）を3箇所選んでください。');
      } else {
        _placeHelicoptersRandomly();
        currentPhase = GamePhase.setupCarHuman;
        _pushLog('警察が展開しました。あなたの車の隠れ場所（ビル）を1つタップして選んでください。');
      }
    });
  }

  // ============ 警察役=人間 用のセットアップ ============

  void _selectHelicopterInitialPosition(int r, int c) {
    if (helicopters.any((h) => h.row == r && h.col == c)) {
      return;
    }

    setState(() {
      helicopters.add(Helicopter(helicopters.length + 1, r, c));

      if (helicopters.length < 3) {
        _pushLog(
          'ヘリ${helicopters.length}を配置しました。残りのヘリを配置してください（あと${3 - helicopters.length}機）。',
        );
      } else {
        _placeCarRandomly();
        currentPhase = GamePhase.playing;
        currentHeliIndex = 0;
        _pushLog('警察の配置完了。犯人はどこかのビルに身を隠しました。');
        _pushLog('【第1ラウンド開始】ヘリ1の行動を選択してください。');
      }
    });
  }

  void _placeCarRandomly() {
    final random = Random();
    carRow = random.nextInt(boardSize);
    carCol = random.nextInt(boardSize);
    traceGrid[carRow][carCol] = 1;
  }

  // ============ 犯人役=人間 用のセットアップ ============

  void _placeHelicoptersRandomly() {
    final random = Random();
    Set<String> used = {};
    List<Helicopter> newHelis = [];
    while (newHelis.length < 3) {
      int r = random.nextInt(4);
      int c = random.nextInt(4);
      String key = '$r,$c';
      if (!used.contains(key)) {
        used.add(key);
        newHelis.add(Helicopter(newHelis.length + 1, r, c));
      }
    }
    helicopters = newHelis;
  }

  void _selectCarInitialPositionHuman(int r, int c) {
    if (currentPhase != GamePhase.setupCarHuman) return;

    setState(() {
      carRow = r;
      carCol = c;
      traceGrid[r][c] = 1;
      currentPhase = GamePhase.playing;
      _pushLog('あなたはビル($r, $c)に身を隠しました。');
      _pushLog('【第1ラウンド開始】警察が行動します…');
    });

    _runPoliceAITurn();
  }

  // ============ 警察役=人間 の操作 ============

  void _onHelicopterActed() {
    helicopters[currentHeliIndex].hasActedThisTurn = true;

    int nextHeliIndex = helicopters.indexWhere((h) => !h.hasActedThisTurn);

    if (nextHeliIndex != -1) {
      setState(() {
        currentHeliIndex = nextHeliIndex;
        _pushLog('次は ヘリ${helicopters[currentHeliIndex].id} のターンです。');
      });
    } else {
      _advanceTurnAICar();
    }
  }

  // 犯人AI（警察役=人間の時に使用）の移動 & ラウンド進行
  // ※移動先の判断ロジック自体は ai/criminal_ai.dart に委譲
  void _advanceTurnAICar() {
    if (currentRound >= maxRounds) {
      setState(() {
        currentPhase = GamePhase.gameOver;
        gameResultMessage = '🚨 11ラウンド逃走達成！犯人の勝利です！';
      });
      return;
    }

    final nextMove = CriminalAi.decideMove(
      traceGrid,
      boardSize,
      carRow,
      carCol,
    );

    if (nextMove == null) {
      setState(() {
        currentPhase = GamePhase.gameOver;
        gameResultMessage = '🚔 包囲完了！犯人は移動できなくなり、警察の勝利です！';
      });
      return;
    }

    carRow = nextMove[0];
    carCol = nextMove[1];
    traceGrid[carRow][carCol] = currentRound + 1;

    for (var h in helicopters) {
      h.hasActedThisTurn = false;
    }

    setState(() {
      currentRound++;
      currentHeliIndex = 0;
      isSearchMode = false;
      _pushLog('【第$currentRoundラウンド】犯人が移動しました。ヘリ1の行動を選択してください。');
    });
  }

  void _moveHelicopter(int targetRow, int targetCol) {
    if (currentPhase != GamePhase.playing || playerRole != PlayerRole.police)
      return;

    final currentHeli = helicopters[currentHeliIndex];

    int dr = (currentHeli.row - targetRow).abs();
    int dc = (currentHeli.col - targetCol).abs();

    if ((dr == 1 && dc == 0) || (dr == 0 && dc == 1)) {
      if (helicopters.any(
        (h) =>
            h.id != currentHeli.id && h.row == targetRow && h.col == targetCol,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('他のヘリコプターがいる交差点には移動できません。')),
        );
        return;
      }

      setState(() {
        currentHeli.row = targetRow;
        currentHeli.col = targetCol;
        _pushLog('ヘリ${currentHeli.id} を交差点($targetRow, $targetCol)へ移動。');
      });

      _onHelicopterActed();
    }
  }

  Future<void> _searchBuilding(int r, int c) async {
    if (currentPhase != GamePhase.playing || playerRole != PlayerRole.police)
      return;
    if (searchingRow != -1) return; // 演出中は多重実行を防止

    final currentHeli = helicopters[currentHeliIndex];

    bool isAdjacent =
        (r == currentHeli.row || r == currentHeli.row + 1) &&
        (c == currentHeli.col || c == currentHeli.col + 1);

    if (!isAdjacent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('このビルは選択中のヘリの捜索範囲外です。')));
      return;
    }

    setState(() {
      searchingRow = r;
      searchingCol = c;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    searchedGrid[r][c] = true;
    searchedRoundGrid[r][c] = currentRound;

    if (r == carRow && c == carCol) {
      setState(() {
        searchingRow = -1;
        searchingCol = -1;
        currentPhase = GamePhase.gameOver;
        gameResultMessage = '🎉 逮捕！ビル($r, $c)で犯人の車を発見しました！警察の勝利！';
        _pushLog('🎉 ビル($r, $c)で車を発見！逮捕成功！');
      });
    } else if (traceGrid[r][c] > 0) {
      setState(() {
        searchingRow = -1;
        searchingCol = -1;
        revealedTraces[r][c] = true;
        _pushLog(
          '🔍 ヘリ${currentHeli.id}：ビル($r, $c)で【痕跡コマ】を発見！(第${traceGrid[r][c]}ターン通過)',
        );
      });
      _onHelicopterActed();
    } else {
      setState(() {
        searchingRow = -1;
        searchingCol = -1;
        _pushLog('🔍 ヘリ${currentHeli.id}：ビル($r, $c)には何もいませんでした。');
      });
      _onHelicopterActed();
    }
  }

  // ============ 犯人役=人間 の操作 & 警察AI ============

  void _moveCarHuman(int r, int c) {
    if (currentPhase != GamePhase.playing || playerRole != PlayerRole.criminal)
      return;
    if (isPoliceTurnRunning) return;

    int dr = (carRow - r).abs();
    int dc = (carCol - c).abs();
    bool isAdjacentOrtho = (dr == 1 && dc == 0) || (dr == 0 && dc == 1);

    if (!isAdjacentOrtho) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('タテヨコに隣接するビルへのみ移動できます。')));
      return;
    }
    if (traceGrid[r][c] != 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('すでに痕跡のあるビルには戻れません。')));
      return;
    }

    setState(() {
      carRow = r;
      carCol = c;
      traceGrid[r][c] = currentRound + 1;
      currentRound++;
      _pushLog('あなたはビル($r, $c)へ移動しました。');
      _pushLog('【第$currentRoundラウンド】警察が行動します…');
    });

    _runPoliceAITurn();
  }

  // 警察AIの1ラウンド分の行動（ヘリ3機を順番に動かす）
  Future<void> _runPoliceAITurn() async {
    setState(() {
      isPoliceTurnRunning = true;
    });

    for (int idx = 0; idx < helicopters.length; idx++) {
      if (currentPhase == GamePhase.gameOver) return;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || currentPhase == GamePhase.gameOver) return;

      setState(() {
        currentHeliIndex = idx;
      });

      await _aiDecideAndActHelicopter(helicopters[idx]);

      if (currentPhase == GamePhase.gameOver) return;
    }

    if (currentRound >= maxRounds) {
      setState(() {
        currentPhase = GamePhase.gameOver;
        isPoliceTurnRunning = false;
        gameResultMessage = '🎉 11ラウンド逃走達成！あなたの勝利です！';
      });
      return;
    }

    List<List<int>> validMoves = CriminalAi.getValidMoves(
      traceGrid,
      boardSize,
      carRow,
      carCol,
    );
    if (validMoves.isEmpty) {
      setState(() {
        currentPhase = GamePhase.gameOver;
        isPoliceTurnRunning = false;
        gameResultMessage = '🚔 包囲されました。移動できる場所がありません。警察の勝利です。';
      });
      return;
    }

    setState(() {
      isPoliceTurnRunning = false;
      _pushLog('警察の捜索が終わりました。あなたの番です。緑色のビルをタップして移動してください。');
    });
  }

  // 1機のヘリのAI行動決定：
  // 「どこを捜索・移動するか」の判断自体は ai/police_ai.dart に委譲し、
  // ここでは判断結果（PoliceAiAction）に応じた状態更新（setState・ログ追加）のみを行う。
  Future<void> _aiDecideAndActHelicopter(Helicopter heli) async {
    final action = PoliceAi.decideAction(heli, helicopters, searchedGrid);

    switch (action.type) {
      case PoliceActionType.search:
        await _aiSearchBuilding(heli, action.targetRow, action.targetCol);
        break;
      case PoliceActionType.move:
        setState(() {
          heli.row = action.targetRow;
          heli.col = action.targetCol;
          _pushLog(
            'ヘリ${heli.id}：交差点(${action.targetRow}, ${action.targetCol})へ移動しました。',
          );
        });
        break;
      case PoliceActionType.wait:
        setState(() {
          _pushLog('ヘリ${heli.id}：身動きが取れず待機しました。');
        });
        break;
    }
  }

  Future<void> _aiSearchBuilding(Helicopter heli, int r, int c) async {
    setState(() {
      searchingRow = r;
      searchingCol = c;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    searchedGrid[r][c] = true;
    searchedRoundGrid[r][c] = currentRound;

    if (r == carRow && c == carCol) {
      setState(() {
        searchingRow = -1;
        searchingCol = -1;
        currentPhase = GamePhase.gameOver;
        isPoliceTurnRunning = false;
        gameResultMessage = '🚨 逮捕！警察がビル($r, $c)であなたの車を発見しました。警察の勝利です。';
        _pushLog('🚨 ヘリ${heli.id}がビル($r, $c)であなたを発見！');
      });
    } else if (traceGrid[r][c] > 0) {
      setState(() {
        searchingRow = -1;
        searchingCol = -1;
        revealedTraces[r][c] = true;
        _pushLog('🔍 ヘリ${heli.id}：ビル($r, $c)で痕跡を発見（第${traceGrid[r][c]}ターン通過）。');
      });
    } else {
      setState(() {
        searchingRow = -1;
        searchingCol = -1;
        _pushLog('🔍 ヘリ${heli.id}：ビル($r, $c)は空振りでした。');
      });
    }
  }

  // 痕跡の色を取得 (1ターン目=黄, 6ターン目=赤, その他=グレー)
  Color _getTraceColor(int roundNumber) {
    if (roundNumber == 1) return Colors.amber;
    if (roundNumber == 6) return Colors.redAccent;
    return Colors.grey[400]!;
  }

  String _statusLabel() {
    if (currentPhase == GamePhase.gameOver) return 'ゲーム終了';
    if (currentPhase == GamePhase.setupHelicopters) return 'セットアップ中（ヘリ配置）';
    if (currentPhase == GamePhase.setupCarHuman) return 'セットアップ中（隠れ場所選択）';
    if (currentPhase == GamePhase.playing) {
      if (playerRole == PlayerRole.police) return '警察フェーズ';
      if (playerRole == PlayerRole.criminal) {
        return isPoliceTurnRunning ? '警察(AI)行動中…' : 'あなたの番（逃走）';
      }
    }
    return '';
  }

  // 盤面（BoardWidget）からのタップを受け取り、フェーズ・役割に応じて処理を振り分ける
  void _onBuildingTap(int r, int c) {
    if (currentPhase == GamePhase.setupCarHuman) {
      _selectCarInitialPositionHuman(r, c);
    } else if (currentPhase == GamePhase.playing) {
      if (playerRole == PlayerRole.police && isSearchMode) {
        _searchBuilding(r, c);
      } else if (playerRole == PlayerRole.criminal) {
        _moveCarHuman(r, c);
      }
    }
  }

  void _onIntersectionTap(int i, int j) {
    if (currentPhase == GamePhase.setupHelicopters &&
        playerRole == PlayerRole.police) {
      _selectHelicopterInitialPosition(i, j);
    } else if (currentPhase == GamePhase.playing &&
        playerRole == PlayerRole.police &&
        !isSearchMode) {
      _moveHelicopter(i, j);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentPhase == GamePhase.roleSelect) {
      return RoleSelectView(onSelectRole: _chooseRole);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          playerRole == PlayerRole.police
              ? 'City Chase（警察役）'
              : playerRole == PlayerRole.criminal
              ? 'City Chase（犯人役）'
              : 'City Chase',
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewGame,
            tooltip: 'リセット（役割選択に戻る）',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ステータスヘッダー
            Container(
              color: Colors.indigo[50],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ターン: $currentRound / $maxRounds',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: currentPhase == GamePhase.gameOver
                          ? Colors.red
                          : Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),

            // 勝利判定ダイアログ
            if (currentPhase == GamePhase.gameOver)
              Container(
                width: double.infinity,
                color: Colors.amber[100],
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      gameResultMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _restartSameRole,
                          icon: const Icon(Icons.replay),
                          label: const Text('連続して遊ぶ（同じ役職で再戦）'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _startNewGame,
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('役割選択に戻る'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // アクションログ（直近数件を履歴として表示。最新ほど濃く表示）
            LogPanel(logHistory: logHistory),

            // プレイ中の操作コントロール（警察役=人間のみ）
            if (currentPhase == GamePhase.playing &&
                playerRole == PlayerRole.police) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '現在操作中: ヘリ${helicopters[currentHeliIndex].id}  ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('移動モード'),
                    icon: Icon(Icons.open_with),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('捜索モード'),
                    icon: Icon(Icons.search),
                  ),
                ],
                selected: {isSearchMode},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    isSearchMode = newSelection.first;
                  });
                },
              ),
            ],

            // 犯人役=人間へのヒント表示
            if (currentPhase == GamePhase.setupCarHuman)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '好きなビルをタップして、車の隠れ場所を選んでください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            if (currentPhase == GamePhase.playing &&
                playerRole == PlayerRole.criminal &&
                !isPoliceTurnRunning)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '緑色のビルをタップして移動してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),

            const SizedBox(height: 12),

            // ゲーム盤面
            BoardWidget(
              boardPixelSize: boardPixelSize,
              heliMarkerSize: heliMarkerSize,
              boardSize: boardSize,
              currentPhase: currentPhase,
              playerRole: playerRole,
              carRow: carRow,
              carCol: carCol,
              traceGrid: traceGrid,
              revealedTraces: revealedTraces,
              searchedRoundGrid: searchedRoundGrid,
              currentRound: currentRound,
              searchingRow: searchingRow,
              searchingCol: searchingCol,
              helicopters: helicopters,
              currentHeliIndex: currentHeliIndex,
              isSearchMode: isSearchMode,
              isPoliceTurnRunning: isPoliceTurnRunning,
              getTraceColor: _getTraceColor,
              onBuildingTap: _onBuildingTap,
              onIntersectionTap: _onIntersectionTap,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
