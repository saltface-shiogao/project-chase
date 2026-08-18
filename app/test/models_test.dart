import 'package0:flutter_test/flutter_test.dart';
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
    // search は位置引数 (heli.id, heli.row, heli.col) を受け取る形式に修正
    final action = PoliceAiAction.search(heli.id, heli.row, heli.col);
    expect(action.type, PoliceActionType.search);
    expect(action.helicopterId, heli.id);
  });

  test('CriminalAi test', () {
    // getValidMoves と decideMove は位置引数で呼び出す形式に修正
    final grid = List.generate(5, (_) => List.generate(5, (_) => 0));
    final moves = CriminalAi.getValidMoves(grid, 2, 2, []);
    expect(moves.isNotEmpty, isTrue);

    final move = CriminalAi.decideMove(grid, 2, 2, [
      [0, 0],
    ]);
    expect(move, isNotNull);
    expect(move?.length, 2);
  });

  test('PoliceAi test', () {
    final helis = [Helicopter(1, 0, 0)];
    final grid = List.generate(5, (_) => List.generate(5, (_) => 0));
    // decideAction も位置引数 (helis, grid, searchedBuildings) で呼び出し
    final action = PoliceAi.decideAction(helis, grid, []);
    expect(action, isNotNull);
  });
}
