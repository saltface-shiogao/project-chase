/// ゲームフェーズ定義
/// roleSelect       : 役割選択画面
/// setupHelicopters : 警察役=人間の場合、ヘリ3機を配置するフェーズ
/// setupCarHuman    : 犯人役=人間の場合、車の初期隠れ場所を選ぶフェーズ
/// playing          : ゲーム進行中
/// gameOver         : ゲーム終了
///
/// ---- 以下、ローカル2人対戦モード用に追加（2026-08-12）----
/// この2つの値は、ターン交代時に非公開情報（犯人の車位置・痕跡など）を
/// 画面上で一時的に隠すための「受け渡し画面」フェーズを表す想定。
/// 現時点ではこのファイル内に定義を追加しただけで、
/// views/game_page.dart 等、他のどのファイルからも参照・分岐処理は
/// まだ一切行っていない（既存の1人プレイの挙動に影響しない）。
/// handoffToCriminal : 次の手番が犯人プレイヤーであることを示し、
///                     犯人プレイヤーへ画面を受け渡す間のフェーズ
/// handoffToPolice   : 次の手番が警察プレイヤーであることを示し、
///                     警察プレイヤーへ画面を受け渡す間のフェーズ
enum GamePhase {
  roleSelect,
  setupHelicopters,
  setupCarHuman,
  playing,
  gameOver,
  handoffToCriminal,
  handoffToPolice,
}
