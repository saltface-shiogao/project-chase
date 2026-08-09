/// 警察AI（ヘリ1機）が選んだ行動の種類
enum PoliceActionType { search, move, wait }

/// 警察AIが決定した行動内容。
/// 判断結果のみを保持し、setStateやログ更新などの状態変更は一切行わない。
class PoliceAiAction {
  final PoliceActionType type;
  final int targetRow;
  final int targetCol;

  const PoliceAiAction.search(this.targetRow, this.targetCol) : type = PoliceActionType.search;
  const PoliceAiAction.move(this.targetRow, this.targetCol) : type = PoliceActionType.move;
  const PoliceAiAction.wait()
      : type = PoliceActionType.wait,
        targetRow = -1,
        targetCol = -1;
}
