/// ゲームフェーズ定義
/// roleSelect       : 役割選択画面
/// setupHelicopters : 警察役=人間の場合、ヘリ3機を配置するフェーズ
/// setupCarHuman    : 犯人役=人間の場合、車の初期隠れ場所を選ぶフェーズ
/// playing          : ゲーム進行中
/// gameOver         : ゲーム終了
///
/// ---- 以下、ローカル2人対戦モード用に追加（2026-08-12） ----
/// この2つの値は、ターン交代時に非公開情報（犯人の車位置・痕跡など）を
/// 画面上で一時的に隠すための「受け渡し画面」フェーズ。
/// views/game_page.dart の build() が HandoffView（views/handoff_view.dart）を
/// 表示し、盤面を含む画面全体を一時的に置き換える。1人プレイ（isTwoPlayerMode
/// != true）ではこの2つの値には一切遷移しないため、既存の1人プレイの挙動には
/// 影響しない。
/// handoffToCriminal : 次の手番が犯人プレイヤーであることを示し、
///                     犯人プレイヤーへ画面を受け渡す間のフェーズ
/// handoffToPolice   : 次の手番が警察プレイヤーであることを示し、
///                     警察プレイヤーへ画面を受け渡す間のフェーズ
/// difficultySelect     : 1人プレイのみ。役割選択の後、AI難易度を選ぶフェーズ。
///                        ローカル2人対戦ではAIを使わないため、この値には遷移しない。
enum GamePhase {
  roleSelect,
  difficultySelect,
  setupHelicopters,
  setupCarHuman,
  playing,
  gameOver,
  handoffToCriminal,
  handoffToPolice,
}
