/// ヘリコプタークラス
class Helicopter {
  int id;
  int row; // 0〜3
  int col; // 0〜3
  bool hasActedThisTurn; // 今のターンで行動済みか（警察役=人間の時のみ使用）

  Helicopter(this.id, this.row, this.col, {this.hasActedThisTurn = false});

  /// 警察側の初期配置を最初からやり直す際に使用する。
  static void resetInitialSetup(List<Helicopter> helicopters) {
    helicopters.clear();
  }
}
