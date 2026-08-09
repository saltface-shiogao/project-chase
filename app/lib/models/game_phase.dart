/// ゲームフェーズ定義
/// roleSelect       : 役割選択画面
/// setupHelicopters : 警察役=人間の場合、ヘリ3機を配置するフェーズ
/// setupCarHuman    : 犯人役=人間の場合、車の初期隠れ場所を選ぶフェーズ
/// playing          : ゲーム進行中
/// gameOver         : ゲーム終了
enum GamePhase {
  roleSelect,
  setupHelicopters,
  setupCarHuman,
  playing,
  gameOver,
}
