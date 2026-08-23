import 'dart:math';
import 'package:flutter/material.dart';

import '../ai/criminal_ai.dart';
import '../ai/police_ai.dart';
import '../models/app_theme.dart';
import '../models/ai_difficulty.dart';
import '../models/game_phase.dart';
import '../models/helicopter.dart';
import '../models/player_role.dart';
import '../models/police_ai_action.dart';
import 'board_widget.dart';
import 'difficulty_select_view.dart';
import 'handoff_view.dart';
import 'log_panel.dart';
import 'mode_select_view.dart';
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
  // 道路（2車線）がビルの隙間にきちんと収まるよう、隙間を広げた分だけ
  // 盤面サイズも大きくしている（520→600）。
  static const double boardPixelSize = 600;
  static const double heliMarkerSize = 46;

  // ログとして画面に残す最大件数
  static const int maxLogEntries = 6;

  // ==== PCブラウザ版デスクトップレイアウト用の定数 ====
  // このセクションの値は「今回の画面配置（PC向け）」専用の見た目調整値であり、
  // ゲームロジックには一切影響しない。将来スマホ向けレイアウトを追加する際は、
  // ここを別レイアウト定義に差し替える想定（ゲームロジック側は変更不要）。
  //
  // 画面上部の「ステータスヘッダー／結果バナー」切り替え領域の高さ。
  // 通常時（ターン数・フェーズ表示）とゲーム終了時（結果メッセージ＋再戦ボタン）の
  // どちらの内容が入っても、この高さは変えない＝盤面の位置がズレない。
  static const double headerAreaHeight = 148;
  // ゲーム終了時の結果バナーは、メッセージ文言＋ボタン2つ分の高さが必要になるため、
  // 通常のステータスヘッダーより広めの専用の高さを用意する
  // （headerAreaHeightのままだと、環境によってはボタンがはみ出して押せなくなる
  // 　不具合があったための対応）。
  static const double gameOverHeaderAreaHeight = 200;
  // 盤面の左上に置く「操作コントロール／確認」領域の高さ
  // （警察役の「現在操作中のヘリ」表示・確定/キャンセルボタン、犯人役へのヒント文言などが入る）。
  // フェーズによって表示内容が有る/無いが変わっても、高さは固定する。
  static const double controlAreaHeight = 96;
  // スタイル切り替えチップ行のおおよその高さ（盤面の下に追加した分）。
  static const double styleToggleAreaHeight = 44;
  // 痕跡の色分け凡例のおおよその高さ（盤面のさらに下に追加した分）。
  static const double traceLegendAreaHeight = 24;
  // 上記2つを含め、ログパネルとの高さ揃え（mainAreaHeight）に反映する。
  // 左側ログパネルの幅（折り返し表示でも読みやすいよう少し広めに設定。
  // この値はゲーム中・ゲーム終了時を通じて変わらない固定値）
  static const double logPanelWidth = 260;
  // デザイン切替・凡例を右側パネルに出すかどうかの分岐に使う定数。
  // ※将来スマホの縦画面対応をする際は、この分岐をさらに増やす想定
  // 　（今回は「十分広い時は右パネル／狭い時は今まで通り盤面の下」の
  // 　2択のみ用意している）。
  static const double sidePanelWidth = 220;
  static const double _wideLayoutMinWidth =
      32 + logPanelWidth + 16 + boardPixelSize + 16 + sidePanelWidth;

  // 役割・フェーズ
  PlayerRole? playerRole;
  GamePhase currentPhase = GamePhase.roleSelect;

  // ローカル2人対戦モード用に追加。
  // null        : まだ「1人プレイ／2人対戦」を選んでいない（ModeSelectViewを表示する）
  // false       : 1人プレイ（AI対戦）を選択済み（従来通りRoleSelectViewを表示）
  // true        : ローカル2人対戦を選択済み（RoleSelectViewを2人対戦向け文言で表示）
  // 既存のGamePhaseには新しい値を追加していない。currentPhase == roleSelect の間、
  // この変数の値だけでどちらの画面を出すかを切り替える。
  bool? isTwoPlayerMode;
  AiDifficulty aiDifficulty = AiDifficulty.normal;

  // ローカル2人対戦用に追加。
  // HandoffView（受け渡し画面）の「続ける」ボタンを押した後に、
  // どのフェーズへ進むかを保持する。
  // - setupCarHuman : セットアップ中（警察配置→犯人へ受け渡し）の場合
  // - playing       : それ以外（ラウンド中の受け渡し、または犯人配置→警察へ受け渡しで
  //                    ラウンド1を開始する場合）
  GamePhase _phaseAfterHandoff = GamePhase.playing;

  // ローカル2人対戦用に追加。
  // 「受け渡し先」（handoffToCriminal / handoffToPolice）が決まった直後、
  // 即座に画面を切り替えるのではなく、いったんこの変数にセットして
  // 確認オーバーレイ（_buildHandoffConfirmOverlay）を表示する。
  // これにより、直前の操作結果を見たまま「次のプレイヤーに渡してよろしいですか？」と
  // ワンクッション置いてから受け渡し画面に進める。nullの間は通常表示。
  GamePhase? _pendingHandoffPhase;

  // 車の位置
  int carRow = -1;
  int carCol = -1;

  // 痕跡データ: 0=なし, 1〜11=通ったラウンド
  late List<List<int>> traceGrid;
  // 発見された痕跡の記録（trueなら画面表示）
  late List<List<bool>> revealedTraces;
  // 一度でも捜索されたことがあるか（AI警察が同じ場所を無駄に捜索しないための記録・永続）
  late List<List<bool>> searchedGrid;
  // 表示用：ヘリ1〜3それぞれの「直近の捜索場所」を保持する（インデックス=id-1、値は[row, col]、
  // 未捜索は[-1, -1]）。あるヘリが新たに捜索すると、そのヘリ自身のエントリだけが上書きされる。
  // 盤面上には常に最大3箇所（各ヘリ1箇所ずつ）のマーカーが同時に表示され得る。
  // AIの内部記憶(searchedGrid)には影響しない。
  late List<List<int>> lastSearchedByHeli;

  // 現在アニメーション中（捜索演出中）のビル座標。捜索していない時は-1。
  int searchingRow = -1;
  int searchingCol = -1;

  // ラウンド
  int currentRound = 1;

  // ヘリコプター
  List<Helicopter> helicopters = [];
  int currentHeliIndex = 0;

  // 警察役=人間が、確定前に選択している「候補」（誤操作防止のための確認ステップ用）。
  // 交差点（移動先）またはビル（捜索先）のどちらか一方のみを保持する。
  // 「確定」ボタンを押すまで、実際の移動・捜索は実行されない。
  int pendingRow = -1;
  int pendingCol = -1;
  bool pendingIsSearch = false; // true: ビル（捜索候補）／false: 交差点（移動候補）
  bool get _hasPendingAction => pendingRow != -1 && pendingCol != -1;

  // 警察AIが行動中かどうか（犯人役=人間の時、この間は操作をブロックする）
  bool isPoliceTurnRunning = false;

  // アクションログ（複数件保持。先頭が最新）
  List<String> logHistory = [];
  // 勝利メッセージ
  String gameResultMessage = '';

  // 盤面デザインの見た目スタイル（設定画面はまだ無いため、ひとまず
  // ここに状態を持たせている。デフォルトはBoardWidget側と同じ
  // 新影風・2車線道路）。
  BuildingStyle _buildingStyle = BuildingStyle.shadowRelief;
  RoadStyle _roadStyle = RoadStyle.twoLane;

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
    pendingRow = -1;
    pendingCol = -1;
    pendingIsSearch = false;
    isPoliceTurnRunning = false;
    searchingRow = -1;
    searchingCol = -1;
    gameResultMessage = '';
    logHistory = [];
    _phaseAfterHandoff = GamePhase.playing;
    _pendingHandoffPhase = null;

    traceGrid = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    revealedTraces = List.generate(
      boardSize,
      (_) => List.filled(boardSize, false),
    );
    searchedGrid = List.generate(
      boardSize,
      (_) => List.filled(boardSize, false),
    );
    lastSearchedByHeli = List.generate(3, (_) => [-1, -1]);
    helicopters = [];
  }

  // リセット（役割選択画面に戻る）
  void _startNewGame() {
    setState(() {
      currentPhase = GamePhase.roleSelect;
      playerRole = null;
      isTwoPlayerMode = null;
      _resetBoardState();
    });
  }

  // ModeSelectViewでの選択を受け取る。
  // 1人プレイ：モードを記録するのみで、役割決定は _chooseRole に、
  // 難易度決定は _chooseDifficulty に委ねる
  // （1人で遊ぶ → 役割選択 → 難易度選択 → ゲーム開始）。
  // ローカル2人対戦：2人対戦は必ず警察側のヘリ配置から始まり、役割も難易度も
  // 選ぶ余地がないため、RoleSelectView・DifficultySelectViewを経由せず
  // 直接ヘリ配置フェーズへ進む。
  void _choosePlayMode(PlayMode mode) {
    if (mode == PlayMode.localTwoPlayer) {
      setState(() {
        isTwoPlayerMode = true;
        playerRole = PlayerRole.police;
        currentPhase = GamePhase.setupHelicopters;
        _pushLog('【セットアップ】警察側のヘリコプター(3機)の配置場所を選んでください。');
      });
      return;
    }

    setState(() {
      isTwoPlayerMode = false;
    });
  }

  // 「連続して遊ぶ」：現在の playerRole を維持したまま盤面だけ初期化し、
  // 役割選択画面を経由せずに次のゲームのセットアップから再開する。
  // ※ ai/criminal_ai.dart・ai/police_ai.dart は状態を持たない純粋関数のみで
  //   構成されているため、AI側で別途リセットすべき内部状態は存在しない。
  void _restartSameRole() {
    if (isTwoPlayerMode == true) {
      setState(() {
        _resetBoardState();
      });
      setState(() {
        playerRole = PlayerRole.police;
        currentPhase = GamePhase.setupHelicopters;
        _pushLog('【セットアップ】警察側のヘリコプター(3機)の配置場所を選んでください。');
      });
      return;
    }

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

  // 役割選択（1人プレイのみ。2人対戦はRoleSelectViewを経由しないため
  // このメソッドは呼ばれない）。
  // 役割を記録し、次の難易度選択画面（DifficultySelectView）へ進む。
  // 実際のゲームセットアップ（ヘリ配置／車の隠れ場所選択）への遷移は、
  // 難易度が決まった後の _chooseDifficulty で行う。
  void _chooseRole(PlayerRole role) {
    setState(() {
      playerRole = role;
      currentPhase = GamePhase.difficultySelect;
    });
  }

  // 難易度選択（1人プレイのみ）。
  // DifficultySelectViewでの選択を受けて、選んだ役割に応じたセットアップ
  // フェーズへ進む。この部分の分岐は、変更前の _chooseRole にあった
  // ロジックをそのまま移したもの。
  void _chooseDifficulty(AiDifficulty difficulty) {
    setState(() {
      aiDifficulty = difficulty;

      if (playerRole == PlayerRole.police) {
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
        return;
      }

      if (isTwoPlayerMode == true) {
        // 2人対戦：ここでは車を自動配置せず、確認オーバーレイを経て
        // 犯人プレイヤーへ受け渡す。playerRoleの切り替えは、確認後に
        // 実際にhandoff画面へ入る時点で行う（A案）。
        _phaseAfterHandoff = GamePhase.setupCarHuman;
        _pendingHandoffPhase = GamePhase.handoffToCriminal;
        _pushLog('警察のヘリ配置が完了しました。');
        return;
      }

      _placeCarRandomly();
      currentPhase = GamePhase.playing;
      currentHeliIndex = 0;
      _pushLog('警察の配置完了。犯人はどこかのビルに身を隠しました。');
      _pushLog('【第1ラウンド開始】ヘリ1の行動を選択してください。');
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
    });

    if (isTwoPlayerMode == true) {
      setState(() {
        _phaseAfterHandoff = GamePhase.playing;
        _pendingHandoffPhase = GamePhase.handoffToPolice;
        _pushLog('犯人プレイヤーが隠れ場所を選び終えました。');
      });
      return;
    }

    setState(() {
      currentPhase = GamePhase.playing;
      _pushLog('あなたはビル($r, $c)に身を隠しました。');
      _pushLog('【第1ラウンド開始】警察が行動します…');
    });

    _runPoliceAITurn();
  }

  // ============ ローカル2人対戦：受け渡し画面（HandoffView）確定処理 ============

  // HandoffViewの「続ける」ボタンが押されたときの共通処理。
  // playerRoleの切り替え自体は _confirmProceedToHandoff で
  // 既に完了しているため、ここでは _phaseAfterHandoff に応じて
  // 次のフェーズへ進め、そのフェーズに応じた案内ログを出すだけでよい。
  void _confirmHandoff() {
    setState(() {
      currentPhase = _phaseAfterHandoff;

      if (_phaseAfterHandoff == GamePhase.setupCarHuman) {
        _pushLog('あなたの車の隠れ場所（ビル）を1つタップして選んでください。');
      } else if (playerRole == PlayerRole.police) {
        for (var h in helicopters) {
          h.hasActedThisTurn = false;
        }
        currentHeliIndex = 0;
        _pushLog(
          '【第$currentRoundラウンド】ヘリ${helicopters[currentHeliIndex].id}の行動を選択してください。',
        );
      } else {
        _pushLog('緑色のビルをタップして移動してください。');
      }
    });
  }

  // 直前の操作結果が見えている画面の上に出す「受け渡し確認」オーバーレイの
  // ボタンが押されたときの処理。ここで初めてplayerRoleとcurrentPhaseを
  // 実際に切り替え、HandoffView（画面全体を差し替える受け渡し画面）へ進む。
  void _confirmProceedToHandoff() {
    if (_pendingHandoffPhase == null) return;
    final target = _pendingHandoffPhase!;
    setState(() {
      playerRole = target == GamePhase.handoffToCriminal
          ? PlayerRole.criminal
          : PlayerRole.police;
      currentPhase = target;
      _pendingHandoffPhase = null;
    });
  }

  // 受け渡し確認オーバーレイ本体。直前の画面（盤面・ログ）はそのまま透けて
  // 見える状態で、その上に半透明の幕＋確認カードを重ねる。
  // ここではまだplayerRoleを切り替えていないため、表示中の盤面は
  // 直前のプレイヤー自身の情報のまま（非公開情報の漏洩にはならない）。
  Widget _buildHandoffConfirmOverlay() {
    final theme = AppTheme.boardGame();
    final bool toCriminal = _pendingHandoffPhase == GamePhase.handoffToCriminal;
    final String message = toCriminal
        ? '次は犯人プレイヤーの番です。\n端末を渡してよろしいですか？'
        : '次は警察プレイヤーの番です。\n端末を渡してよろしいですか？';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  toCriminal ? Icons.directions_car : Icons.local_police,
                  color: theme.inkColor,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.inkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _confirmProceedToHandoff,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.pendingSearchColor,
                    foregroundColor: theme.inkColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('次のプレイヤーに渡す'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ 警察役=人間 の操作 ============

  // ヘリ1機の行動完了時の処理。
  // 次に操作するヘリは「まだ行動していないヘリ」の中から自動的に1つ候補として選ばれるが、
  // これはあくまでデフォルトの提案であり、プレイヤーは盤面上の別の未行動ヘリをタップして
  // 自由に操作順を変更できる（_selectHelicopterToOperate参照）。
  void _onHelicopterActed() {
    helicopters[currentHeliIndex].hasActedThisTurn = true;

    int nextHeliIndex = helicopters.indexWhere((h) => !h.hasActedThisTurn);

    if (nextHeliIndex != -1) {
      setState(() {
        currentHeliIndex = nextHeliIndex;
        _pushLog(
          'ヘリ${helicopters[currentHeliIndex].id} の行動をどうぞ（他の未行動ヘリを選ぶこともできます）。',
        );
      });
      return;
    }

    if (isTwoPlayerMode == true) {
      // 3機とも行動完了。犯人プレイヤーへ受け渡す前に、勝敗条件を確認する
      // （タイミングは1人プレイの _advanceTurnAICar と同じ：警察行動直後、
      // 　犯人が実際に動く前）。
      if (currentRound >= maxRounds) {
        setState(() {
          currentPhase = GamePhase.gameOver;
          gameResultMessage = '🚨 11ラウンド逃走達成！犯人プレイヤーの勝利です！';
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
          gameResultMessage = '🚔 包囲完了！犯人は移動できなくなり、警察プレイヤーの勝利です！';
        });
        return;
      }

      setState(() {
        _phaseAfterHandoff = GamePhase.playing;
        _pendingHandoffPhase = GamePhase.handoffToCriminal;
      });
      return;
    }

    _advanceTurnAICar();
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
      difficulty: aiDifficulty,
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
      pendingRow = -1;
      pendingCol = -1;
      pendingIsSearch = false;
      _pushLog('【第$currentRoundラウンド】犯人が移動しました。ヘリ1の行動を選択してください。');
    });
  }

  void _moveHelicopter(int targetRow, int targetCol) {
    if (currentPhase != GamePhase.playing || playerRole != PlayerRole.police)
      return;

    final currentHeli = helicopters[currentHeliIndex];

    if (currentHeli.hasActedThisTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このヘリは行動済みです。まだ行動していないヘリを選択してください。')),
      );
      return;
    }

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

    if (currentHeli.hasActedThisTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このヘリは行動済みです。まだ行動していないヘリを選択してください。')),
      );
      return;
    }

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
    lastSearchedByHeli[currentHeli.id - 1] = [r, c];

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

  // 犯人役=人間の移動先タップ時の判定（隣接チェック・痕跡チェック）のみを行う。
  // 警察側と同じ確定フローに揃えるため、ここでは実際の移動は行わず、
  // 妥当な移動先であれば「候補」として保持するだけに留める
  // （実行は _confirmPendingAction → _executeCriminalMove で行う）。
  void _validateAndStageCriminalMove(int r, int c) {
    if (currentPhase != GamePhase.playing || playerRole != PlayerRole.criminal)
      return;
    if (isPoliceTurnRunning) return;

    // 既に候補として選択中のビルを、もう一度タップした場合は
    // 「確定ボタンを押した」のと同じ扱いにする（操作の手間を減らすショートカット）。
    if (_hasPendingAction &&
        !pendingIsSearch &&
        pendingRow == r &&
        pendingCol == c) {
      _confirmPendingAction();
      return;
    }

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
      pendingRow = r;
      pendingCol = c;
      pendingIsSearch = false;
    });
  }

  // 確定ボタンが押された後に実際に呼ばれる、犯人の移動本体。
  // 判定（隣接・痕跡チェック）は _validateAndStageCriminalMove で
  // 既に完了しているため、ここでは状態更新のみを行う
  // （移動ロジック自体は元の _moveCarHuman から変更していない）。
  void _executeCriminalMove(int r, int c) {
    setState(() {
      carRow = r;
      carCol = c;
      traceGrid[r][c] = currentRound + 1;
      currentRound++;
    });

    if (isTwoPlayerMode == true) {
      setState(() {
        _phaseAfterHandoff = GamePhase.playing;
        _pendingHandoffPhase = GamePhase.handoffToPolice;
      });
      return;
    }

    setState(() {
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
    final action = PoliceAi.decideAction(
      heli,
      helicopters,
      searchedGrid,
      difficulty: aiDifficulty,
      revealedTraces: revealedTraces,
    );

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
    lastSearchedByHeli[heli.id - 1] = [r, c];

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

  // 盤面（BoardWidget）からのタップを受け取り、フェーズ・役割に応じて処理を振り分ける。
  // 警察役・犯人役どちらの場合も、タップは即実行せず「候補」として保持し、
  // 確定ボタンで実行する（誤操作防止のための確認ステップ）。
  void _onBuildingTap(int r, int c) {
    if (currentPhase == GamePhase.setupCarHuman) {
      _selectCarInitialPositionHuman(r, c);
      return;
    }

    if (currentPhase != GamePhase.playing) return;

    if (playerRole == PlayerRole.criminal) {
      _validateAndStageCriminalMove(r, c);
      return;
    }

    if (playerRole == PlayerRole.police) {
      // 既に候補として選択中のビルを、もう一度タップした場合は
      // 「確定ボタンを押した」のと同じ扱いにする（操作の手間を減らすショートカット）。
      if (_hasPendingAction &&
          pendingIsSearch &&
          pendingRow == r &&
          pendingCol == c) {
        _confirmPendingAction();
        return;
      }

      final currentHeli = helicopters[currentHeliIndex];

      if (currentHeli.hasActedThisTurn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('このヘリは行動済みです。まだ行動していないヘリを選択してください。')),
        );
        return;
      }

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
        pendingRow = r;
        pendingCol = c;
        pendingIsSearch = true;
      });
    }
  }

  void _onIntersectionTap(int i, int j) {
    if (currentPhase == GamePhase.setupHelicopters &&
        playerRole == PlayerRole.police) {
      _selectHelicopterInitialPosition(i, j);
      return;
    }

    if (currentPhase != GamePhase.playing || playerRole != PlayerRole.police)
      return;

    // タップした交差点にヘリがいる場合は、そのヘリを「これから操作するヘリ」として
    // 選択する（移動として扱わない）。プレイヤーは3機を好きな順番で操作できる。
    int heliIndexAtCell = helicopters.indexWhere(
      (h) => h.row == i && h.col == j,
    );
    if (heliIndexAtCell != -1) {
      _selectHelicopterToOperate(heliIndexAtCell);
      return;
    }

    // 空いている交差点をタップした場合は、選択中のヘリの移動先「候補」として保持する
    final currentHeli = helicopters[currentHeliIndex];

    // 既に候補として選択中の交差点を、もう一度タップした場合は
    // 「確定ボタンを押した」のと同じ扱いにする（操作の手間を減らすショートカット）。
    if (_hasPendingAction &&
        !pendingIsSearch &&
        pendingRow == i &&
        pendingCol == j) {
      _confirmPendingAction();
      return;
    }

    if (currentHeli.hasActedThisTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このヘリは行動済みです。まだ行動していないヘリを選択してください。')),
      );
      return;
    }

    int dr = (currentHeli.row - i).abs();
    int dc = (currentHeli.col - j).abs();
    if (!((dr == 1 && dc == 0) || (dr == 0 && dc == 1))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タテヨコに隣接する交差点のみ移動先として選択できます。')),
      );
      return;
    }

    setState(() {
      pendingRow = i;
      pendingCol = j;
      pendingIsSearch = false;
    });
  }

  // 警察役=人間が、次に操作するヘリを自由に選択する。
  // 1ターンで3機とも行動することは変わらないが、操作する順番はプレイヤーが決められる。
  // 既に行動済みのヘリは選択できない（その旨をメッセージで案内する）。
  // ヘリを切り替えた場合、直前に選んでいた候補（別のヘリのもの）は破棄する。
  void _selectHelicopterToOperate(int index) {
    if (currentPhase != GamePhase.playing || playerRole != PlayerRole.police)
      return;

    final target = helicopters[index];

    if (target.hasActedThisTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このヘリは今ターン、すでに行動済みです。他のヘリを選んでください。')),
      );
      return;
    }

    if (index == currentHeliIndex) return; // 既に選択中のヘリを再度タップした場合は何もしない

    setState(() {
      currentHeliIndex = index;
      pendingRow = -1;
      pendingCol = -1;
      pendingIsSearch = false;
      _pushLog('ヘリ${target.id} を選択しました。');
    });
  }

  // 候補（pendingRow/pendingCol）を確定し、実際に移動または捜索を実行する。
  // 実行後は候補をクリアする。実際の移動・捜索ロジック自体は
  // 既存の _moveHelicopter / _searchBuilding にそのまま委譲する（ロジック変更なし）。
  void _confirmPendingAction() {
    if (!_hasPendingAction) return;

    final r = pendingRow;
    final c = pendingCol;
    final isSearch = pendingIsSearch;

    setState(() {
      pendingRow = -1;
      pendingCol = -1;
      pendingIsSearch = false;
    });

    if (playerRole == PlayerRole.criminal) {
      _executeCriminalMove(r, c);
      return;
    }

    if (isSearch) {
      _searchBuilding(r, c);
    } else {
      _moveHelicopter(r, c);
    }
  }

  // 選択中の候補をキャンセルする（実行せず破棄するのみ）
  void _cancelPendingAction() {
    setState(() {
      pendingRow = -1;
      pendingCol = -1;
      pendingIsSearch = false;
    });
  }

  // ============ 画面上部：ステータスヘッダー／結果バナー（表示専用・ロジックなし） ============
  //
  // 通常時は「ターン数・フェーズ」を表示するステータスヘッダー、
  // ゲーム終了時は「勝敗メッセージ＋再戦ボタン」の結果バナーを、
  // 同じ固定高さ領域（headerAreaHeight）の中で切り替えて表示する。
  // これにより、この下にあるログパネル・盤面の位置は状態によらず常に同じになる。
  // ここで呼んでいる _restartSameRole() / _startNewGame() は既存の機能をそのまま呼ぶだけで、
  // ロジック自体の変更は行っていない。

  Widget _buildStatusHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ターン: $currentRound / $maxRounds',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          _statusLabel(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
      ],
    );
  }

  Widget _buildResultBanner() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            gameResultMessage,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
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
    );
  }

  // ============ 盤面左上：操作コントロール／ヒント領域（表示専用・ロジックなし） ============
  //
  // 警察役=人間の移動/捜索モード切替、犯人役=人間へのヒント文言、
  // 犯人役セットアップ時のヒント文言などを、固定高さ（controlAreaHeight）の中に表示する。
  // 表示する/しないの判定条件は、変更前の build() に元々あった条件分岐をそのまま踏襲している。

  Widget _buildControlArea() {
    if (currentPhase == GamePhase.playing && playerRole == PlayerRole.police) {
      if (_hasPendingAction) {
        final actionLabel = pendingIsSearch ? '捜索' : '移動';
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ヘリ${helicopters[currentHeliIndex].id}：$actionLabel先 ($pendingRow, $pendingCol) を確定しますか？',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _confirmPendingAction,
                  icon: const Icon(Icons.check),
                  label: Text('$actionLabelを確定'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _cancelPendingAction,
                  icon: const Icon(Icons.close),
                  label: const Text('キャンセル'),
                ),
              ],
            ),
          ],
        );
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '現在操作中: ヘリ${helicopters[currentHeliIndex].id}（盤面のヘリをタップで選択変更可）',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '交差点をタップで移動先、ビルをタップで捜索先を選択',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      );
    }

    if (currentPhase == GamePhase.setupCarHuman) {
      return const Center(
        child: Text(
          '好きなビルをタップして、車の隠れ場所を選んでください。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      );
    }

    if (currentPhase == GamePhase.playing &&
        playerRole == PlayerRole.criminal &&
        !isPoliceTurnRunning) {
      if (_hasPendingAction) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '移動先 ($pendingRow, $pendingCol) を確定しますか？',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _confirmPendingAction,
                  icon: const Icon(Icons.check),
                  label: const Text('移動を確定'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _cancelPendingAction,
                  icon: const Icon(Icons.close),
                  label: const Text('キャンセル'),
                ),
              ],
            ),
          ],
        );
      }

      return const Center(
        child: Text(
          '緑色のビルをタップして移動してください。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      );
    }

    // 該当する表示がないフェーズでも領域の高さは確保し、盤面位置がズレないようにする
    return const SizedBox.shrink();
  }

  // ============ 盤面デザインの見た目スタイル切り替え（表示専用・ロジックなし） ============
  //
  // ビルの見た目は BoardWidget 側にすでに両対応が入っているため、
  // ここでは「今どちらを選んでいるか」を保持し、ボタンで切り替えるだけでよい。
  // ゲームロジック（判定・状態管理）には一切影響しない。
  // ※道路は「2車線」で確定したため、切り替えボタンは廃止し _roadStyle は
  //   常に RoadStyle.twoLane 固定（フィールド宣言側で初期値のまま変更していない）。

  // 「凡例」と「デザイン切替」を横並びにした行（凡例が左、切替が右）。
  // 画面が狭い場合はWrapで自動的に折り返す。
  Widget _buildDesignControlsRow(AppTheme theme) {
    return SizedBox(
      width: boardPixelSize,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [_buildTraceLegend(theme), _buildStyleToggleRow(theme)],
      ),
    );
  }

  Widget _buildStyleToggleRow(AppTheme theme) {
    // 「これは切り替えボタンです」と一目で伝わるよう、枠で囲み、
    // アイコン＋ラベルの見出しを付けた上で、選択中／未選択がはっきり
    // 分かる連結ピル型のセグメントコントロールにしている。
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        border: Border.all(color: theme.gridLine, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 14, color: theme.inkColor),
          const SizedBox(width: 4),
          Text(
            'ビルデザイン切替：',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.inkColor,
            ),
          ),
          const SizedBox(width: 6),
          _buildingStyleSegmentedControl(theme),
        ],
      ),
    );
  }

  Widget _buildingStyleSegmentedControl(AppTheme theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.gridLine, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segmentButton(
            label: '① 屋根パターン風',
            selected: _buildingStyle == BuildingStyle.roofPattern,
            theme: theme,
            onTap: () =>
                setState(() => _buildingStyle = BuildingStyle.roofPattern),
          ),
          Container(width: 1.2, color: theme.gridLine),
          _segmentButton(
            label: '② 新影風',
            selected: _buildingStyle == BuildingStyle.shadowRelief,
            theme: theme,
            onTap: () =>
                setState(() => _buildingStyle = BuildingStyle.shadowRelief),
          ),
        ],
      ),
    );
  }

  // セグメントコントロールの1ボタン分。選択中は塗りつぶし＋チェックマーク、
  // 未選択は背景透明のテキストのみ、という明確な差をつけている。
  Widget _segmentButton({
    required String label,
    required bool selected,
    required AppTheme theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: selected ? theme.gridLine : Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 12, color: theme.appBarForeground),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? theme.appBarForeground : theme.inkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 画面が広い時だけ使う、盤面の右側に置くパネル。
  // 横幅が狭いので、デザイン切替（セグメントコントロール）と凡例を
  // 縦に積む構成にしている。中身の判定ロジックは既存のものをそのまま再利用。
  Widget _buildSidePanelDesignControls(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        border: Border.all(color: theme.gridLine, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 14, color: theme.inkColor),
              const SizedBox(width: 4),
              Text(
                'デザイン切替',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.inkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildingStyleSegmentedControl(theme),
          const SizedBox(height: 16),
          Divider(color: theme.gridLine.withOpacity(0.5), height: 1),
          const SizedBox(height: 12),
          Text(
            '痕跡の色',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.inkColor,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in _traceLegendItems(theme))
                Padding(padding: const EdgeInsets.only(bottom: 6), child: item),
            ],
          ),
        ],
      ),
    );
  }

  // ============ 痕跡の色分け凡例（表示専用・ロジックなし） ============
  //
  // 痕跡マーカーは「1ターン目＝黄」「6ターン目＝赤」「それ以外＝グレー」で
  // 色分けしている（_getTraceColor参照）。盤面上では1・6以外の具体的な
  // ターン数はプレイ中わからないようにしているため、色の意味だけでも
  // 一目でわかるよう、盤面の外に小さな凡例を出す。
  // ※「トグルと並べたときに凡例だと分かりにくい」というフィードバックを受け、
  // 　枠で囲んで独立したパーツだと分かるようにしている。

  // 凡例1項目分（色の丸＋ラベル）。横並び・縦並びどちらの凡例からも使う。
  Widget _traceLegendSwatch(AppTheme theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: theme.inkColor)),
      ],
    );
  }

  List<Widget> _traceLegendItems(AppTheme theme) {
    return [
      _traceLegendSwatch(theme, Colors.amber, '1ターン目'),
      _traceLegendSwatch(theme, Colors.grey[400]!, 'その他'),
      _traceLegendSwatch(theme, Colors.redAccent, '6ターン目'),
    ];
  }

  // 盤面の下に表示する、横並び・枠付きの凡例（画面が狭い時のフォールバック用）。
  Widget _buildTraceLegend(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        border: Border.all(color: theme.gridLine, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 4,
        children: _traceLegendItems(theme),
      ),
    );
  }

  /// 盤面そのものだけを返す（決定/キャンセルボタンは盤面の外・下側に別要素として配置する）。
  Widget _buildBoardWithAction(AppTheme theme, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: BoardWidget(
        boardPixelSize: size,
        heliMarkerSize: heliMarkerSize,
        boardSize: boardSize,
        currentPhase: currentPhase,
        playerRole: playerRole,
        carRow: carRow,
        carCol: carCol,
        traceGrid: traceGrid,
        revealedTraces: revealedTraces,
        lastSearchedByHeli: lastSearchedByHeli,
        searchingRow: searchingRow,
        searchingCol: searchingCol,
        helicopters: helicopters,
        currentHeliIndex: currentHeliIndex,
        isPoliceTurnRunning: isPoliceTurnRunning,
        pendingRow: pendingRow,
        pendingCol: pendingCol,
        pendingIsSearch: pendingIsSearch,
        getTraceColor: _getTraceColor,
        onBuildingTap: _onBuildingTap,
        onIntersectionTap: _onIntersectionTap,
        theme: theme,
        buildingStyle: _buildingStyle,
        roadStyle: _roadStyle,
      ),
    );
  }

  // 盤面の「外側・右下寄り」に表示する決定/キャンセルボタンバー。
  // 盤面とは重ならない位置に置くため、盤面の下に固定高さの領域として確保する。
  // _hasPendingActionがfalseの間も高さだけは確保し、表示/非表示でレイアウトが
  // 動かないようにする（盤面固定配置の原則を踏襲）。
  static const double pendingActionBarHeight = 56;

  Widget _buildPendingActionBar(AppTheme theme, double width) {
    if (!_hasPendingAction) {
      return SizedBox(width: width, height: pendingActionBarHeight);
    }
    return SizedBox(
      width: width,
      height: pendingActionBarHeight,
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackground.withOpacity(0.96),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _confirmPendingAction,
                  icon: const Icon(Icons.check),
                  label: const Text('決定'),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _cancelPendingAction,
                  tooltip: 'キャンセル',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentPhase == GamePhase.roleSelect) {
      if (isTwoPlayerMode == null) {
        return ModeSelectView(onSelectMode: _choosePlayMode);
      }
      return RoleSelectView(
        onSelectRole: _chooseRole,
        isTwoPlayerMode: isTwoPlayerMode!,
      );
    }

    // 難易度選択（1人プレイのみ）：役割選択の後、ゲーム開始前に表示する。
    if (currentPhase == GamePhase.difficultySelect) {
      return DifficultySelectView(
        onSelectDifficulty: _chooseDifficulty,
        initialDifficulty: aiDifficulty,
      );
    }

    // ローカル2人対戦：ターン交代の受け渡し画面。
    // 画面全体をHandoffViewに完全に差し替え、盤面・ログを含む前の画面が
    // 一切表示されないようにする（非公開情報の漏洩防止）。
    // 🔄リセットボタンは、警察→犯人の受け渡し中は非表示、
    // 犯人→警察の受け渡し中は表示（確認ダイアログ付き）。
    if (currentPhase == GamePhase.handoffToCriminal ||
        currentPhase == GamePhase.handoffToPolice) {
      return HandoffView(
        phase: currentPhase,
        onContinue: _confirmHandoff,
        onReset: currentPhase == GamePhase.handoffToPolice
            ? _startNewGame
            : null,
      );
    }

    final theme = AppTheme.boardGame();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackground,
          appBar: AppBar(
            title: Text(
              playerRole == PlayerRole.police
                  ? 'City Chase（警察役）'
                  : playerRole == PlayerRole.criminal
                  ? 'City Chase（犯人役）'
                  : 'City Chase',
            ),
            backgroundColor: theme.appBarBackground,
            foregroundColor: theme.appBarForeground,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _startNewGame,
                tooltip: 'リセット（役割選択に戻る）',
              ),
            ],
          ),
          body: Column(
            children: [
              // 画面上部：ステータスヘッダー／結果バナー切り替え領域（高さ固定）
              Container(
                width: double.infinity,
                height: currentPhase == GamePhase.gameOver ? 120 : 56,
                color: currentPhase == GamePhase.gameOver
                    ? theme.pendingSearchColor.withOpacity(0.25)
                    : theme.buildingHighlight.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Center(
                  child: currentPhase == GamePhase.gameOver
                      ? _buildResultBanner()
                      : _buildStatusHeader(),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showLog = constraints.maxWidth >= 760;
                      final availableBoardWidth = showLog
                          ? constraints.maxWidth - logPanelWidth - 16
                          : constraints.maxWidth;
                      // ボタンバー分の高さをあらかじめ差し引いておき、
                      // 盤面+ボタンバーが画面の縦幅に収まるようにする。
                      final availableBoardHeight =
                          constraints.maxHeight - pendingActionBarHeight - 8;
                      final size = min(
                        boardPixelSize,
                        min(availableBoardHeight, availableBoardWidth),
                      );
                      final board = _buildBoardWithAction(theme, size);
                      final boardColumn = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          board,
                          const SizedBox(height: 8),
                          _buildPendingActionBar(theme, size),
                        ],
                      );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showLog) ...[
                            LogPanel(
                              logHistory: logHistory,
                              width: logPanelWidth,
                              height: size,
                            ),
                            const SizedBox(width: 16),
                          ],
                          boardColumn,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_pendingHandoffPhase != null) _buildHandoffConfirmOverlay(),
      ],
    );
  }
}
