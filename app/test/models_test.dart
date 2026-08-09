import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/models/player_role.dart';
import 'package:my_first_app/models/game_phase.dart';
import 'package:my_first_app/models/helicopter.dart';
import 'package:my_first_app/models/police_ai_action.dart';
import 'package:my_first_app/ai/criminal_ai.dart';
import 'package:my_first_app/ai/police_ai.dart';

void main() {
  test('Dummy test', () {
    expect(true, isTrue);
  });

  test('PlayerRole and GamePhase enum test', () {
    expect(PlayerRole.police, isNotNull);
    expect(PlayerRole.criminal, isNotNull);
    expect(GamePhase.playing, isNotNull);
  });

  test('Helicopter model test', () {
    final heli = Helicopter(1, 0, 0);
    expect(heli.id, 1);
    expect(heli.row, 0);
    expect(heli.col, 0);
    expect(heli.hasActedThisTurn, isFalse);
  });

  test('PoliceAiAction model test', () {
    final heli = Helicopter(1, 1, 1);
    final action = PoliceAiAction.search(heli);
    expect(action.type, PoliceActionType.search);
    expect(action.targetHelicopter, heli);
  });

  test('CriminalAi test', () {
    final moves = CriminalAi.getValidMoves(2, 2);
    expect(moves.isNotEmpty, isTrue);

    final move = CriminalAi.decideMove(
      currentX: 2,
      currentY: 2,
      policePositions: [[0, 0]],
      searchedBuildings: [],
    );
    expect(move.length, 2);
  });

  test('PoliceAi test', () {
    final helis = [Helicopter(1, 0, 0)];
    final action = PoliceAi.decideAction(
      helicopters: helis,
      searchedBuildings: [],
    );
    expect(action, isNotNull);
  });
}

