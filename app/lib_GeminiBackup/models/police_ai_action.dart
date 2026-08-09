import 'helicopter.dart';

enum PoliceActionType { search, move, stay }

class PoliceAiAction {
  final PoliceActionType type;
  final Helicopter? targetHelicopter;
  final int? targetX;
  final int? targetY;

  PoliceAiAction.search(this.targetHelicopter)
      : type = PoliceActionType.search,
        targetX = null,
        targetY = null;

  PoliceAiAction.move(this.targetHelicopter, this.targetX, this.targetY)
      : type = PoliceActionType.move;

  PoliceAiAction.stay()
      : type = PoliceActionType.stay,
        targetHelicopter = null,
        targetX = null,
        targetY = null;
}
